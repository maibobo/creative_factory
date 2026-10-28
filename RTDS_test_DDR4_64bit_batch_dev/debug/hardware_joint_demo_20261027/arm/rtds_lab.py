#!/usr/bin/env python3
"""RTDS board-side lab runner, Python >=3.8, standard library only.

Only config, ddr, single, multi require --exclusive. No automatic resets,
programming, driver reloads, user-interrupt registration, or acknowledgement retry.
"""
import argparse
import csv
import datetime
import fcntl
import hashlib
import json
import os
import platform
import re
import shutil
import stat
import subprocess
import sys
import time
import uuid
from pathlib import Path

# 寄存器访问采用白名单：这些偏移是身份、状态、队列头和配置等可安全读取的 BAR0 寄存器。
# 0x10 是“读后清除”的通知寄存器，故意不放入普通快照，只有明确验证通知时才单独读取一次。
SAFE_REGS = (0x00, 0x04, 0x08, 0x0c, 0x18, 0x1c, 0x20, 0x24, 0x28,
             0x2c, 0x30, 0x34, 0x38)
# 上行测试块的有效载荷只有 8 Byte；本实验 DMA 辅助程序限定 16 Byte 对齐，所以实际 C2H 请求为 16 Byte，
# 校验时只比较前 8 Byte。上行环形区共有 8 个槽，每槽间隔 0x40000。
UP_DATA = bytes.fromhex('11 00 00 00 22 00 00 00')
UP_BASE, UP_STRIDE, UP_COUNT = 0x100000, 0x40000, 8


# 实验判定失败的统一异常类型；调用方据此留证并退出，不进行隐式恢复。
class LabError(RuntimeError):
    pass


# 把可序列化状态写入同目录临时文件后替换目标，避免提示窗口/控制器读到半份 JSON。
def atomic_json(path, value):
    # 先写同目录临时文件再原子替换，避免进程中断时留下半份 JSON 证据。
    path = Path(path)
    tmp = path.with_suffix('.tmp')
    tmp.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')
    tmp.replace(path)


# 输入 io 命令文本及期望物理地址；仅返回唯一匹配地址的 32bit 读值，歧义即失败。
def parse_io(text, address):
    # io prints addresses without 0x; reject unrelated/ambiguous output.
    # io 的地址可能没有 0x 前缀；只接受目标地址恰好出现一次，防止把告警或其他地址误当读值。
    found = re.findall(r'^\s*(?:0x)?([0-9a-fA-F]+):\s+(?:0x)?([0-9a-fA-F]{1,8})\s*$', text, re.M)
    matches = [int(v, 16) for a, v in found if int(a, 16) == address]
    if len(matches) != 1:
        raise LabError('Cannot parse io read at 0x%x: %r' % (address, text))
    return matches[0]


# 输入软件期望与实际字节序列；长度或任一字节不同即抛错，本函数只比较、不向 FPGA 发数据。
def compare_bytes(expected, actual):
    if len(expected) != len(actual):
        raise LabError('Data length mismatch: expected=%d actual=%d' % (len(expected), len(actual)))
    for i, (want, got) in enumerate(zip(expected, actual)):
        if want != got:
            raise LabError('Data mismatch offset=0x%x expected=%02x actual=%02x' % (i, want, got))


# 每个实验独立保存日志、数据和结果，关联运行编号与实际程序哈希；历史结果不随注释更新重写。
class Report:
    # args 决定输出目录及运行编号；创建新结果目录并记录环境、程序哈希，禁止覆盖旧运行。
    def __init__(self, args):
        # 每次运行创建不可复用的结果目录；exist_ok=False 可避免覆盖既有证据。
        self.args = args
        self.run_id = args.run_id or ('arm_' + uuid.uuid4().hex[:12])
        if not re.fullmatch(r'[A-Za-z0-9_.-]{1,100}', self.run_id):
            raise LabError('run-id must contain only letters, digits, _, -, .')
        self.path = Path(args.output) / self.run_id
        self.path.mkdir(parents=True, exist_ok=False)
        self.started = time.monotonic()
        self.doc = {'run_id': self.run_id, 'case': args.case, 'status': 'RUNNING',
                    'pc_time': args.pc_time, 'boot_mode': args.boot_mode,
                    'arm_wall_time_untrusted': datetime.datetime.now().isoformat(),
                    'arm_monotonic_start': self.started, 'kernel': platform.release(),
                    'machine': platform.machine(), 'steps': [], 'blocks': [],
                    'evidence': [], 'exclusive_declared': args.exclusive,
                    'note': 'VIO mode validates DDR/C2H, not real Aurora RX.'}
        self.log('START', **{k: v for k, v in self.doc.items() if k not in ('steps', 'blocks')})
        for name in ('rtds_lab.py', 'rtds_dma.c', 'rtds_dma'):
            # 报告中记录本次实际使用程序的哈希，便于把结果追溯到具体源码/二进制。
            p = Path(__file__).parent / name
            if p.exists():
                self.doc.setdefault('program_sha256', {})[name] = hashlib.sha256(p.read_bytes()).hexdigest()
        if args.artifacts_manifest:
            self.doc['fpga_artifacts'] = json.loads(Path(args.artifacts_manifest).read_text(encoding='utf-8'))

    # 记录相对单调时间、事件及字段，同时更新终端、run.log 和 result.json。
    def log(self, event, **fields):
        # run.log 是追加式事件流，result.json 是当前完整状态；两者同时保留便于故障后复核。
        item = {'elapsed': round(time.monotonic() - self.started, 6), 'event': event, **fields}
        self.doc['steps'].append(item)
        line = json.dumps(item, ensure_ascii=False)
        with (self.path / 'run.log').open('a', encoding='utf-8') as f:
            f.write(line + '\n')
        print(line, flush=True)
        atomic_json(self.path / 'result.json', self.doc)

    # 记录最终 PASS/FAIL、耗时及错误，并输出一行 summary.csv；不执行硬件动作。
    def finish(self, status, error=None):
        self.doc.update(status=status, error=error, elapsed_seconds=time.monotonic()-self.started)
        self.log('FINISH', status=status, error=error)
        with (self.path / 'summary.csv').open('w', newline='', encoding='utf-8-sig') as f:
            writer = csv.DictWriter(f, fieldnames=['run_id', 'case', 'status', 'boot_mode', 'pc_time',
                                                  'elapsed_seconds', 'error'])
            writer.writeheader()
            writer.writerow({k: self.doc.get(k) for k in writer.fieldnames})


# ARM 实际访问层：从 sysfs 找 PCIe/BAR，通过 io 访问寄存器并调用 rtds_dma 执行真实 DMA。
class Hardware:
    # 按 vendor/device、可选 BDF、BAR0 和 XDMA 节点确认目标；错卡、缺驱动或节点不匹配即停止。
    def __init__(self, args, report):
        self.args, self.report = args, report
        self.io = shutil.which('io')
        if not self.io:
            raise LabError('io tool not found')
        root = Path(args.sysfs)
        candidates = []
        # 从 sysfs 按 Xilinx vendor/device ID 找 PCIe 端点；--bdf 可在多卡时消除歧义。
        for p in root.iterdir():
            if (p / 'vendor').read_text().strip() == '0x10ee' and (p / 'device').read_text().strip() == '0x8032':
                candidates.append(p)
        if args.bdf:
            candidates = [p for p in candidates if p.name == args.bdf]
        if len(candidates) != 1:
            raise LabError('Expected one 10ee:8032 endpoint, found %d; select --bdf' % len(candidates))
        self.pci = candidates[0]
        first = (self.pci / 'resource').read_text().splitlines()[0].split()
        self.base, end, flags = [int(v, 16) for v in first]
        # BAR0 至少覆盖 0x00..0x38，并且必须是内存型资源；后续 io 命令使用其物理基址。
        if self.base == 0 or end-self.base+1 < 0x3c or not flags & 0x200:
            raise LabError('Invalid BAR0 memory resource')
        driver = self.pci / 'driver'
        # 本程序依赖已有 XDMA 驱动和字符设备，本身不加载、卸载或实现内核驱动。
        if not driver.is_symlink() or driver.resolve().name != 'xdma':
            raise LabError('Endpoint is not bound to xdma')
        self.devices = {name: Path(args.dev_root) / ('xdma%d_%s' % (args.device_index, name))
                        for name in ('user', 'h2c_0', 'c2h_0')}
        for node in self.devices.values():
            if not node.exists() or not stat.S_ISCHR(node.stat().st_mode):
                raise LabError('XDMA character device missing: ' + str(node))
        # A device index must belong to the selected PCI function, not merely exist.
        # 设备节点“存在”还不够：通过主/次设备号反查 sysfs，确认它确实属于选中的 BDF。
        for node in self.devices.values():
            st = node.stat()
            char_path = Path('/sys/dev/char') / ('%d:%d' % (os.major(st.st_rdev), os.minor(st.st_rdev)))
            if self.pci.name not in str(char_path.resolve()):
                raise LabError('Device node does not resolve to selected BDF: ' + str(node))
        report.doc['endpoint'] = {'bdf': self.pci.name, 'bar0': hex(self.base),
                                  'driver': driver.resolve().name,
                                  'nodes': {k: str(v) for k, v in self.devices.items()}}
        self.reject_external_users()

    # 检查其他进程占用的 XDMA 字符设备，发现消费者则拒绝继续；不替操作者终止这些进程。
    def reject_external_users(self):
        # 扫描其他进程已打开的 XDMA 节点。若业务程序仍占用设备，就在任何写操作/DMA 前退出。
        identities = {(os.major(p.stat().st_rdev), os.minor(p.stat().st_rdev)) for p in self.devices.values()}
        owners = []
        for proc in Path('/proc').iterdir():
            if not proc.name.isdigit() or int(proc.name) == os.getpid():
                continue
            try:
                for fd in (proc / 'fd').iterdir():
                    s = fd.stat()
                    if stat.S_ISCHR(s.st_mode) and (os.major(s.st_rdev), os.minor(s.st_rdev)) in identities:
                        owners.append(int(proc.name)); break
            except (OSError, PermissionError):
                continue
        if owners:
            raise LabError('Other process owns XDMA nodes: %r. Stop the business program first.' % owners)

    # offset 是 BAR 相对偏移，内部加 self.base；返回寄存器值。0x10 读清必须显式 read_clear=True。
    def rd(self, offset, read_clear=False):
        # 默认只能读 SAFE_REGS；0x10 必须显式声明 read_clear，避免快照误清通知状态。
        if offset not in SAFE_REGS and not (offset == 0x10 and read_clear):
            raise LabError('Register read is not in safe allowlist')
        addr = self.base + offset
        try:
            p = subprocess.run([self.io, '-4', '-r', hex(addr)], capture_output=True,
                               text=True, timeout=self.args.state_timeout, check=True)
        except (subprocess.SubprocessError, OSError) as e:
            raise LabError('io read failed: %s' % e)
        return parse_io(p.stdout, addr)

    # 仅允许独占实验写 0x14/0x24/0x28；此白名单不含 0x20，因此现有脚本不会启动 1G 配置所需的下行任务。
    def wr(self, offset, value):
        # 写寄存器同时受 --exclusive 与偏移白名单约束：0x14 队列确认，0x24/0x28 下行配置。
        if not self.args.exclusive or offset not in (0x14, 0x24, 0x28):
            raise LabError('Write requires --exclusive and an allowed register')
        self.report.log('WRITE_INTENT', offset=hex(offset), value=hex(value), retry=False)
        try:
            subprocess.run([self.io, '-4', '-w', hex(self.base+offset), hex(value)],
                           capture_output=True, text=True, timeout=self.args.state_timeout, check=True)
        except (subprocess.SubprocessError, OSError) as e:
            # 写命令报错时无法证明硬件是否已接收，必须停止且不重试，避免重复确认/重复配置。
            raise LabError('io write failed/uncertain; no retry: %s' % e)
        self.report.log('WRITE_RETURNED', offset=hex(offset))

    # 逐项采样安全寄存器并记录；不读 0x10，不是同一个时钟沿的原子快照，可能漏掉瞬态。
    def snapshot(self, label):
        # 快照排除了读后清除寄存器 0x10，因此采证本身不会改变通知状态。
        regs = {hex(o): self.rd(o) for o in SAFE_REGS}
        self.report.log('REGISTERS', label=label, values=regs)
        return regs

    # 等待某一寄存器值等于 wanted；超时抛错而非重试动作。0x30 对应本轮期望队列块数。
    def wait(self, offset, wanted):
        # 使用单调时钟轮询状态，避免系统墙上时间跳变影响超时判断。
        deadline = time.monotonic() + self.args.state_timeout
        last = None
        while time.monotonic() < deadline:
            last = self.rd(offset)
            if last == wanted:
                self.report.log('STATE_READY', offset=hex(offset), value=last)
                return last
            time.sleep(0.01)
        raise LabError('State timeout offset=0x%x wanted=%d last=%r' % (offset, wanted, last))

    # direction 为 h2c/c2h，address 是卡端 DDR 字节地址，path 是 ARM 本地数据文件。
    # h2c 只准 0x8000 起 16Byte；上行 c2h 只准合法槽基址。检查完成长度后返回 C helper 的结果字典。
    def dma(self, direction, address, size, path):
        # DMA 仅在独占模式下开放，并进一步限制方向、地址和长度，避免访问实验区外的卡内存。
        if not self.args.exclusive:
            raise LabError('DMA requires --exclusive')
        if direction == 'h2c' and (address != 0x8000 or size != 16):
            raise LabError('Lab H2C is restricted to 16 bytes at 0x8000')
        if direction == 'c2h' and not (address == 0x8000 or
                UP_BASE <= address < UP_BASE + UP_COUNT*UP_STRIDE and (address-UP_BASE) % UP_STRIDE == 0):
            raise LabError('Lab C2H address outside test regions')
        cmd = [str(Path(__file__).parent / 'rtds_dma'), direction,
               str(self.devices['h2c_0' if direction == 'h2c' else 'c2h_0']), hex(address), str(size), str(path)]
        self.report.log('DMA_SUBMIT', direction=direction, card_address=hex(address), requested=size,
                        data_file=path.name)
        try:
            # C helper 每次进程只提交一次 read/write；Python 超时后保留当前队列，不再次提交。
            p = subprocess.run(cmd, capture_output=True, text=True, timeout=self.args.dma_timeout)
        except subprocess.TimeoutExpired:
            raise LabError('DMA timeout; queue is retained; no resubmit/acknowledgement')
        try:
            result = json.loads(p.stdout.strip())
        except ValueError:
            raise LabError('DMA helper invalid output: %r %r' % (p.stdout, p.stderr))
        self.report.log('DMA_RETURN', **result, returncode=p.returncode, stderr=p.stderr)
        if p.returncode or result.get('completed') != size:
            # 错误或短传输均视为数据所有权未可靠完成，不执行后续队列 ACK。
            raise LabError('DMA failed/short; no acknowledgement')
        return result


# ARM 到操作者或 PC 控制器的控制面；只请求 ILA/VIO 操作，不承载上行业务数据。
class Control:
    """Manual gates or an SFTP file handshake, never a timed blind trigger."""
    # 有 control_dir 时使用本次独有目录与 PC 文件握手；否则每次控制动作需人工输入 PASS。
    def __init__(self, args, report):
        self.args, self.report, self.seq = args, report, 0
        self.root = Path(args.control_dir) if args.control_dir else None
        if self.root:
            self.root.mkdir(parents=True, exist_ok=False)

    # action 为 inspect/arm/inject/save/snapshot；等待匹配请求 ID 的明确响应后才返回。
    # 人工 PASS 仅覆盖这些控制动作，不等于 DMA 比较后、归还前已有逐步确认功能。
    def call(self, action, **params):
        # 控制面采用“请求—明确完成”的握手：人工模式要求输入 PASS，文件模式要求响应 ID 匹配。
        # 这避免 ARM 仅凭固定延时猜测 PC/Vivado 已经布置好 ILA、VIO 或已经保存证据。
        self.seq += 1
        self.report.log('CONTROL_REQUEST', action=action, sequence=self.seq, params=params)
        if not self.root:
            prompts = {
                'inspect': 'Run ::rtds_lab::inspect. Confirm link/DDR=1, fault=0, busy=0. Enter PASS: ',
                'arm': 'Run ::rtds_joint::arm %s. Confirm ILA is waiting, then enter PASS: ' % params.get('test'),
                'inject': 'Run ::rtds_lab::inject. Wait for accepted=2, busy=0, fault=0, then enter PASS: ',
                'save': 'Run ::rtds_lab::save %s, retain the evidence, then enter PASS: ' % params.get('kind'),
                'snapshot': 'Run ::rtds_joint::snapshot and keep its output, then enter PASS: ',
            }
            try:
                confirmed = input(prompts[action]).strip() == 'PASS'
            except EOFError:
                confirmed = False
            if not confirmed:
                raise LabError('Manual control confirmation missing: ' + action)
            response = {'manual_ack': True, 'action': action}
        else:
            # 唯一 request_id 防止把上一次动作遗留的 response.json 当成本次响应。
            request_id = '%03d_%s' % (self.seq, uuid.uuid4().hex[:8])
            request = {'id': request_id, 'action': action, **params}
            atomic_json(self.root / 'request.json', request)
            deadline = time.monotonic() + self.args.control_timeout
            response = None
            while time.monotonic() < deadline:
                rp = self.root / 'response.json'
                if rp.exists():
                    candidate = json.loads(rp.read_text(encoding='utf-8'))
                    if candidate.get('id') == request_id:
                        response = candidate; break
                time.sleep(0.1)
            if response is None:
                raise LabError('Control handshake timeout: ' + action)
            if response.get('status') != 'ok':
                raise LabError('Hardware control failed: %r' % response)
        self.report.doc['evidence'].append(response)
        self.report.log('CONTROL_COMPLETE', action=action, response=response)
        return response


# 组织环境、下行 DDR 与上行队列协议实验；所操作是真实 Hardware，而非离线测试里的 FakeHardware。
class Experiments:
    # 注入访问层、控制面、日志及参数，维护本轮基线和最近消费序号。
    def __init__(self, hw, control, report, args):
        self.hw, self.control, self.report, self.args = hw, control, report, args
        self.baseline, self.last_seq = None, None

    # regs 是读回值字典：0x2C & 0x03 检查 DDR ready/校准，0x2C & 0x1C 检查 bit4..2 错误。
    # 这里 0x1C 是数值掩码，不是在读取偏移 0x1C 的上行长度；PCIe 链路另由设备/调试状态检查。
    def health(self, regs):
        # 0x00/0x04/0x08 是设计身份与能力标识；0x2c 的低两位分别表示 DDR ready 与校准完成，
        # 其余受检位表示错误；0x20 是下行忙状态；0x38 是丢字计数器。
        if regs['0x0'] != 0x2001 or regs['0x4'] != 0x20260914 or regs['0x8'] != 0x40000:
            raise LabError('Identity registers mismatch')
        if regs['0x2c'] & 3 != 3 or regs['0x2c'] & 0x1c:
            raise LabError('DDR is not ready or error flags are set; evidence retained, no clear')
        if regs['0x20'] != 0:
            raise LabError('Downlink is busy')
        if self.baseline and regs['0x38'] != self.baseline['0x38']:
            raise LabError('Dropped-word counter changed')

    # 先留健康基线并要求队列为空；旧块、既有异常或丢字计数饱和时退出，不盲目归还/清除。
    def preflight(self):
        # 基线必须健康、队列为空且丢字计数器未饱和，否则无法证明本次运行没有新增丢字。
        self.baseline = self.hw.snapshot('baseline')
        self.health(self.baseline)
        if self.baseline['0x30'] != 0:
            raise LabError('Old blocks present. Do not blindly acknowledge; save and inspect first.')
        if self.baseline['0x38'] != 0xffffffff:
            self.report.log('DROP_BASELINE', value=self.baseline['0x38'])
        else:
            raise LabError('Drop counter saturated; cannot prove no new drops')

    # 只测试下行地址/长度回读，不写 0x20 启动命令；恢复配置也须先留证并确认硬件健康空闲。
    def config(self):
        # 配置测试只验证 0x24 地址和 0x28 长度可写回读；无论主体是否成功都尝试恢复原值。
        old = (self.hw.rd(0x24), self.hw.rd(0x28))
        try:
            for addr, length in ((0x8000, 0x10), (0x8010, 0x20)):
                self.hw.wait(0x20, 0)
                self.hw.wr(0x24, addr); self.hw.wr(0x28, length)
                if (self.hw.rd(0x24), self.hw.rd(0x28), self.hw.rd(0x20)) != (addr, length, 0):
                    raise LabError('Configuration readback mismatch')
                self.report.log('CONFIG_VERIFIED', address=hex(addr), length=length)
        finally:
            # Restore only with healthy idle hardware; preserve evidence before doing so.
            # 恢复前先留快照并再次确认硬件空闲健康，避免在异常状态下继续写配置。
            regs = self.hw.snapshot('before_config_restore')
            self.health(regs)
            self.hw.wr(0x24, old[0]); self.hw.wr(0x28, old[1])
            if (self.hw.rd(0x24), self.hw.rd(0x28)) != old:
                raise LabError('Original configuration restore failed')
            self.report.log('CONFIG_RESTORED', address=hex(old[0]), length=old[1])

    # 此处 Python 确实构造 00..0F，并经 H2C 写 0x8000 再 C2H 读回；这是 DDR 往返实验。
    # 它不经过上行 VIO 生成路径，也不会因 H2C 写入本身就产生 1G 配置事件。
    def ddr(self):
        # DDR 回环：H2C 把 16 Byte 模式写到卡地址 0x8000，再用 C2H 读回并逐字节比较。
        if self.args.no_jtag:
            self.report.log('JTAG_NOT_USED', reason='Direct ARM H2C/C2H; VIO/ILA validation is not claimed')
        else:
            self.control.call('inspect')
        pattern = bytes(range(16))
        tx, rx = self.report.path / 'ddr_tx.bin', self.report.path / 'ddr_rx.bin'
        tx.write_bytes(pattern)
        if self.args.capture:
            self.control.call('arm', test='dma_write')
        self.hw.dma('h2c', 0x8000, 16, tx)
        if self.args.capture:
            self.control.call('save', kind='native')
            self.control.call('arm', test='dma_read')
        self.hw.dma('c2h', 0x8000, 16, rx)
        compare_bytes(pattern, rx.read_bytes())
        self.report.log('DATA_MATCH', effective=16, requested=16, data_hex=rx.read_bytes().hex())
        if self.args.capture:
            self.control.call('save', kind='native')

    # count 是注入完成后期望的队列总数，不是本次生成字节数或块数。
    # 每调用一次请求 Tcl 把 rx_test_start 置 0→1；FPGA 固定源产生两字、合计 8Byte，提交一个块。
    def inject(self, count):
        # inject 由 PC/Vivado 控制面执行；ARM 等待队列计数达到期望值，并检查旧队头不会被新块覆盖。
        old_head = self.head() if count > 1 else None
        if self.args.capture:
            self.control.call('arm', test='fdma_up')
        self.control.call('inject')
        self.hw.wait(0x30, count)
        self.health(self.hw.snapshot('after_inject_%d' % count))
        if old_head is not None and self.head() != old_head:
            raise LabError('Head changed while another block was enqueued')
        if self.args.capture:
            self.control.call('save', kind='fdma')
        self.demo_hold('入队完成', count)

    # 已确认硬件状态后停留 dwell 秒便于看屏；不会冻结 FPGA，也不会等待操作者按“下一步”。
    def demo_hold(self, stage, count):
        """状态已确认后延长显示时间；延时不替代硬件握手。"""
        seconds = getattr(self.args, 'dwell', 0)
        if seconds:
            self.report.log('DEMO_HOLD', stage=stage, queue=count, seconds=seconds)
            time.sleep(seconds)

    # 返回当前队头的地址、有效字节数及序号三元组；多个 MMIO 读取需靠前后检查保证逻辑一致。
    def head(self):
        # 队头由地址(0x18)、有效长度(0x1c)和序号(0x34)组成，必须作为一个逻辑快照交叉检查。
        return (self.hw.rd(0x18), self.hw.rd(0x1c), self.hw.rd(0x34))

    # 逐块按硬件队头 C2H 读取并比较，再写一次 0x14=1；当前测试有效 8Byte、DMA 请求 16Byte。
    # UP_DATA 是软件期望值，不会被 H2C 写入上行槽；失败或结果不确定时不得重复归还。
    def consume(self, count, check_notify=False):
        # 队列所有权协议：先稳定读取队头，再 DMA、校验数据，最后只写一次 0x14 归还当前块。
        # 任何校验、DMA 或状态检查失败都在 ACK 前退出，因此失败块继续归硬件/队列持有。
        for remaining in range(count, 0, -1):
            if self.hw.rd(0x30) != remaining:
                raise LabError('Unexpected queue count before read')
            address, effective, sequence = before = self.head()
            if effective != 8 or not (UP_BASE <= address < UP_BASE+UP_COUNT*UP_STRIDE) or (address-UP_BASE) % UP_STRIDE:
                raise LabError('Unexpected test-block address/length: %r' % (before,))
            if self.last_seq is not None and sequence != ((self.last_seq+1) & 0xffffffff):
                raise LabError('Block sequence discontinuity')
            if check_notify and remaining == count:
                # Check stability for one second; never include INT_STATE in snapshots.
                # 首块先观察一秒未确认稳定性，再只读一次 0x10 清通知；清通知不等于归还队列块。
                deadline = time.monotonic() + 1.0
                while time.monotonic() < deadline:
                    if self.head() != before or self.hw.rd(0x30) != remaining:
                        raise LabError('Unacknowledged head/count changed')
                    time.sleep(0.05)
                self.health(self.hw.snapshot('before_notification_clear'))
                notification = self.hw.rd(0x10, read_clear=True)
                self.report.log('READ_CLEAR_ONCE', offset='0x10', value=notification)
                if notification & 1 != 1:
                    raise LabError('Expected user notification bit absent; check other consumers')
                if self.head() != before or self.hw.rd(0x30) != remaining:
                    raise LabError('Notification clear released or changed queue head')
            rx = self.report.path / ('up_%03d_seq_%08x.bin' % (len(self.report.doc['blocks']), sequence))
            # effective=8 是业务有效字节数，但 XDMA 读请求按硬件对齐扩大到 16 Byte；尾部 8 Byte 不参与比较。
            self.report.log('BLOCK_READ_BEGIN', address=hex(address), sequence=sequence,
                            effective=effective, remaining=remaining)
            if getattr(self.args, 'capture_reads', False):
                self.control.call('arm', test='dma_read')
            result = self.hw.dma('c2h', address, 16, rx)
            compare_bytes(UP_DATA, rx.read_bytes()[:effective])
            if getattr(self.args, 'capture_reads', False):
                self.control.call('save', kind='native')
            self.health(self.hw.snapshot('before_ack'))
            if self.head() != before or self.hw.rd(0x30) != remaining:
                raise LabError('Queue changed during DMA; no acknowledgement')
            block = {'address': hex(address), 'sequence': sequence, 'effective': effective,
                     'requested': 16, 'completed': result['completed'], 'data_hex': rx.read_bytes()[:8].hex(),
                     'file': rx.name, 'ack_intent': False, 'ack_confirmed': False}
            self.report.doc['blocks'].append(block)
            block['ack_intent'] = True
            self.report.log('BLOCK_DATA_VERIFIED', block=block.copy())
            self.hw.wr(0x14, 1)  # Exactly once. If uncertain, stop; do not retry.
            # 0x14=1 是一次性消费确认。写返回后还要看到 0x30 减一，才记录 ack_confirmed。
            self.hw.wait(0x30, remaining-1)
            block['ack_confirmed'] = True
            self.last_seq = sequence
            self.report.log('BLOCK_ACK_CONFIRMED', sequence=sequence, remaining=remaining-1)
            self.demo_hold('读取并归还完成', remaining-1)
        if self.hw.rd(0x18) != 0 or self.hw.rd(0x1c) != 0:
            raise LabError('Empty queue did not clear head address/length')

    # single=1 块；multi=2/8/2 块；eight=8 块。先逐次 VIO 注入，再逐块读取归还。
    # eight 的 8 次注入形成 8 个相同 8Byte 载荷块，覆盖 8 个 256KiB 槽，不是每槽写满 256KiB。
    def up(self, multi=False, eight=False):
        # single 验证单块协议；multi 依次验证 2、8、2 块批次，并确认 8 个环形槽均被覆盖和发生回绕。
        self.control.call('inspect')
        saved_config = (self.hw.rd(0x24), self.hw.rd(0x28))
        for n in ((2, 8, 2) if multi else ((8,) if eight else (1,))):
            for count in range(1, n+1):
                self.inject(count)
            self.consume(n, check_notify=True)
            self.report.log('QUEUE_BATCH_VERIFIED', blocks=n)
        if (self.hw.rd(0x24), self.hw.rd(0x28)) != saved_config:
            raise LabError('Uplink changed downlink configuration')
        if multi or eight:
            addresses = [int(b['address'], 16) for b in self.report.doc['blocks']]
            if len(set(addresses)) != 8:
                raise LabError('Did not exercise all 8 ring slots')
            self.report.log('RING_WRAP_VERIFIED', total_blocks=len(addresses), distinct_slots=8)

    # 完成预检后分发当前 case，最后检查健康和空队列；VIO/ILA 截图不替代数据比较结论。
    def run(self):
        self.preflight()
        case = self.args.case
        if case == 'config':
            self.config()
        elif case == 'ddr':
            self.ddr()
        elif case in ('single', 'multi', 'eight'):
            self.up(case == 'multi', case == 'eight')
        elif case == 'env':
            self.report.log('ENVIRONMENT_VERIFIED', python=sys.version.split()[0], io=self.hw.io)
        elif case == 'regs':
            self.report.log('REGISTERS_VERIFIED')
        self.health(self.hw.snapshot('final'))
        if self.hw.rd(0x30) != 0:
            raise LabError('Queue is not empty at experiment end')
        if case in ('ddr', 'single', 'multi', 'eight') and not self.args.no_jtag:
            self.control.call('snapshot')


# 解析并约束实验、独占、捕获及超时参数；禁止把 no-jtag 与 VIO 上行实验组合使用。
def arguments(argv=None):
    # env/regs 为只读检查；config/ddr/single/multi/eight 会写寄存器或 DMA，必须由调用者声明 --exclusive。
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('case', choices=['env', 'regs', 'config', 'ddr', 'single', 'multi', 'eight'])
    p.add_argument('--exclusive', action='store_true', help='Declare other software stopped; required for writes/DMA')
    p.add_argument('--capture', action='store_true', help='Arm and save the appropriate ILA for each transfer/injection')
    p.add_argument('--capture-reads', action='store_true', help='Capture native ILA for each uplink C2H read')
    p.add_argument('--dwell', type=float, default=0, help='Seconds to display each confirmed queue state, 0..10')
    p.add_argument('--no-jtag', action='store_true', help='DDR-only CPU data loop; no VIO/ILA verification claimed')
    p.add_argument('--output', default=str(Path(__file__).parent.parent / 'results'))
    p.add_argument('--run-id')
    p.add_argument('--pc-time', default='not supplied')
    p.add_argument('--boot-mode', choices=['flash', 'jtag', 'unknown'], default='unknown')
    p.add_argument('--control-dir', help='Unique directory for the PC controller SFTP handshake')
    p.add_argument('--state-timeout', type=float, default=2.0)
    p.add_argument('--dma-timeout', type=float, default=10.0)
    p.add_argument('--control-timeout', type=float, default=600.0)
    p.add_argument('--bdf')
    p.add_argument('--device-index', type=int, default=0)
    p.add_argument('--sysfs', default='/sys/bus/pci/devices')
    p.add_argument('--dev-root', default='/dev')
    p.add_argument('--artifacts-manifest')
    args = p.parse_args(argv)
    if min(args.state_timeout, args.dma_timeout, args.control_timeout) <= 0:
        p.error('timeouts must be positive')
    if args.case not in ('env', 'regs') and not args.exclusive:
        p.error('This experiment requires --exclusive; stop other hardware users first')
    if not 0 <= args.dwell <= 10:
        p.error('--dwell must be between 0 and 10 seconds')
    if args.capture_reads and args.case != 'eight':
        p.error('--capture-reads is only supported for eight')
    if args.no_jtag and (args.capture or args.capture_reads or args.case in ('single', 'multi', 'eight')):
        p.error('--no-jtag cannot be combined with capture or VIO uplink experiments')
    return args


# 持有 ARM 进程锁覆盖本轮，创建真实访问层并执行实验；异常先留失败快照，最终释放锁。
def main(argv=None):
    args = arguments(argv)
    report, hw = None, None
    # Held across the entire experiment; a second instance cannot consume/ack blocks.
    # 进程级 flock 覆盖整个实验，阻止两个本程序实例同时消费并确认同一队列块。
    lock = open('/run/lock/rtds_joint_lab.lock', 'a')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print('Another RTDS experiment is running', file=sys.stderr); return 2
    try:
        report = Report(args)
        hw = Hardware(args, report)
        Experiments(hw, Control(args, report), report, args).run()
        report.finish('PASS')
        return 0
    except (LabError, OSError, subprocess.SubprocessError, KeyboardInterrupt, ValueError) as e:
        # 失败路径先记录原因和不含读清寄存器的快照；不做复位、不清错、不补发 DMA，也不归还未验证块。
        if report:
            report.log('FAILURE', error=str(e))
            if hw:
                try:
                    hw.snapshot('failure_no_read_clear')
                except Exception as snapshot_error:
                    report.log('SNAPSHOT_FAILED', error=str(snapshot_error))
            report.finish('FAIL', str(e) or type(e).__name__)
        else:
            print(str(e), file=sys.stderr)
        return 1
    finally:
        lock.close()


if __name__ == '__main__':
    sys.exit(main())
