#!/usr/bin/env python3
"""Run the demo using a live GUI bridge and an authenticated ARM connection."""
import argparse
import datetime
import getpass
import json
import sys
import uuid
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent / 'hardware_joint_lab_20261016' / 'pc' / 'hostdeps_20261019'))
import lab_remote


# Windows 侧事件出口：把调度阶段与 ARM 回传结果写入同一 JSONL，供独立提示窗口读取。
class EventLog:
    """Append machine-readable events; a separate window displays the same stream."""
    # path 是本次事件文件，session 是运行关联号；初始化只准备目录，不触发硬件。
    def __init__(self, path, session):
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.session = session

    # 追加一条含 PC 时间的事件并立即打印；日志描述阶段/结果，不构造或发送业务载荷。
    def emit(self, event, **fields):
        item = {'session': self.session, 'pc_time': datetime.datetime.now().astimezone().isoformat(),
                'event': event, **fields}
        with self.path.open('a', encoding='utf-8') as output:
            output.write(json.dumps(item, ensure_ascii=False) + '\n')
        print(json.dumps(item, ensure_ascii=False), flush=True)

    # 接收 lab_remote 转发的 ARM JSON 事件，封装为 ARM_EVENT 后交给提示窗口。
    def arm_event(self, value):
        self.emit('ARM_EVENT', data=value)


# 返回到 192.168.50.10 root 的 SSHClient；沿用已保存主机密钥，未知密钥拒绝连接。
def connect_arm(password):
    """Use the already verified host key; never persist or log the password."""
    client = lab_remote.paramiko.SSHClient()
    client.load_host_keys(str(Path.home() / '.ssh' / 'known_hosts'))
    client.set_missing_host_key_policy(lab_remote.paramiko.RejectPolicy())
    client.connect('192.168.50.10', username='root', password=password,
                   look_for_keys=False, allow_agent=False, timeout=10,
                   auth_timeout=10, banner_timeout=10)
    client.get_transport().set_keepalive(15)
    return client


# 总调度：只读环境/寄存器 → 验证当前 GUI 桥接 → DDR 往返 → 慢速与连续两轮 8 槽。
# args.jobs 必须对应当前 Vivado；ARM 控制请求由 lab_remote 桥接到 Tcl，实际数据由 FPGA/C DMA 完成。
# 返回 0 表示上述调度全部通过，1 表示失败停止；不包括 1G→CPU 的 2µs 周期收发验证。
def run(cli, password):
    session = datetime.datetime.now().strftime('%Y%m%d_%H%M%S') + '_' + uuid.uuid4().hex[:8]
    log = EventLog(cli.events, session)
    jobs = Path(cli.jobs)
    client = None
    log.emit('START', jobs=str(jobs), note='VIO test source; not real Aurora traffic')
    try:
        if not (jobs / 'service.ready').is_file():
            raise RuntimeError('所选 GUI 桥接目录没有 service.ready；请在当前 Vivado 重新启动桥接')
        client = connect_arm(password)
        args = argparse.Namespace(arm_dir=cli.arm_dir, jobs=jobs, exclusive=True, capture=False,
                                  capture_reads=False, dwell=0, no_jtag=False, boot_mode='unknown',
                                  live_log=True, event_callback=log.arm_event)
        for case in ('env', 'regs'):
            args.case = case
            log.emit('PHASE', phase=case, description='只读身份和寄存器基线')
            log.emit('CASE_DONE', case=case, run_id=lab_remote.run_case(client, args))
        # This read-only round trip proves that this particular bridge is responsive;
        # a stale service.ready by itself is not sufficient.
        log.emit('PHASE', phase='vio_inspect', description='检查当前 Vivado 调试核及链路状态')
        log.emit('VIO_STATE', values=lab_remote.hw_call(jobs, 'inspect'))
        log.emit('VIO_SNAPSHOT', values=lab_remote.hw_call(jobs, 'snapshot'))
        for case, dwell, capture, capture_reads in (
                ('ddr', 0, True, False),
                ('eight', 2, True, True),
                ('eight', 0, False, False)):
            args.case, args.dwell, args.capture, args.capture_reads = case, dwell, capture, capture_reads
            phase = 'ddr' if case == 'ddr' else ('eight_slow' if dwell else 'eight_continuous')
            log.emit('PHASE', phase=phase, dwell=dwell, capture=capture,
                     description={'ddr': '16 Byte DDR 写入与读取', 'eight_slow': '8 块逐步入队与读取',
                                  'eight_continuous': '8 块连续入队与读取'}[phase])
            log.emit('CASE_DONE', case=phase, run_id=lab_remote.run_case(client, args))
        log.emit('DONE', status='PASS', note='板内 VIO 测试；不代表真实 Aurora 或性能验收')
    except Exception as exc:
        log.emit('FAIL', error=str(exc), note='停止，不自动重试、清错或归还未验证块')
        return 1
    finally:
        if client:
            client.close()
    return 0


# 解析 jobs/events/独占声明及密码输入，再调用 run；--exclusive 是操作者声明，不能自行停止外部业务。
def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jobs', required=True, help='本次 Vivado GUI 桥接目录')
    parser.add_argument('--events', required=True, help='本轮 Windows JSONL 提示日志')
    parser.add_argument('--arm-dir', default='/root/rtds_joint_demo_20261027')
    parser.add_argument('--prompt-password', action='store_true', help='在交互终端隐藏输入密码')
    parser.add_argument('--exclusive', action='store_true', help='确认其他业务和消费者已停止')
    args = parser.parse_args()
    if not args.exclusive:
        parser.error('必须先停止其他业务并明确传入 --exclusive')
    password = getpass.getpass('ARM root SSH 密码：') if args.prompt_password else sys.stdin.readline().rstrip('\r\n')
    if not password:
        parser.error('从标准输入读取 ARM 密码，不在命令行或文件中保存')
    return run(args, password)


if __name__ == '__main__':
    sys.exit(main())
