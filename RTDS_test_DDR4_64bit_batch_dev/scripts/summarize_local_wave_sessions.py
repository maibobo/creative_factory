"""Offline VCD statistics and WCFG inventory. Python stdlib only; no images."""
from pathlib import Path
import csv
import hashlib
import json
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'evidence/local_wave_sessions'
CASES = ['1g', 'tx', 'rx_fifo', 'ring', 'axi', 'axi_tail', 'regs']

def norm(s):
    return '/'.join(x.strip().lstrip('\\') for x in s.split('/'))

def parse_vcd(path):
    scopes, signals, stats = [], [], {}
    now = 0
    timescale = ''
    timescale_next = False
    with path.open(encoding='utf-8', errors='replace') as stream:
        for raw in stream:
            s = raw.strip()
            if timescale_next:
                timescale = s.replace('$end', '').strip()
                timescale_next = False
            if s.startswith('$timescale'):
                timescale = s[len('$timescale'):].replace('$end', '').strip()
                timescale_next = not timescale
            elif s.startswith('$scope '):
                scopes.append(s.split()[2])
            elif s.startswith('$upscope'):
                scopes.pop()
            elif s.startswith('$var '):
                p = s.split()
                signals.append({'path': norm('/' + '/'.join(scopes + [p[4]])), 'width': int(p[2]), 'code': p[3]})
                stats.setdefault(p[3], {'initial': None, 'final': None, 'changes': 0, 'first_change': None, 'last_change': None, 'known_min': None, 'known_max': None, 'xz_events': 0})
            elif s.startswith('#'):
                now = int(s[1:])
            elif s and s[0] in '01xXzZbBrR':
                if s[0] in 'bBrR':
                    p = s[1:].split()
                    if len(p) != 2: continue
                    value, code = p
                else:
                    value, code = s[0], s[1:]
                if code not in stats: continue
                a = stats[code]
                value = value.lower()
                if a['initial'] is None:
                    a['initial'] = value
                elif value != a['final']:
                    a['changes'] += 1
                    if a['first_change'] is None: a['first_change'] = now
                    a['last_change'] = now
                a['final'] = value
                if 'x' in value or 'z' in value:
                    a['xz_events'] += 1
                elif set(value) <= {'0', '1'}:
                    v = int(value, 2)
                    a['known_min'] = v if a['known_min'] is None else min(v, a['known_min'])
                    a['known_max'] = v if a['known_max'] is None else max(v, a['known_max'])
    return signals, stats, now, timescale

PURPOSE = {
    '1g': ('1G 配置跨时钟和周期发送', '配置字节、译码/锁存、CDC 请求确认、链路复位、发送握手/帧标记/数据、周期和跳过计数；用于连接“首次合法配置→目的域参数→两拍发送”，并定位反压与掉线恢复。'),
    'tx': ('16Byte 下行与异步 FIFO', 'FDMA 地址/请求/数据握手、批量上限、FIFO 水位和满空保护、读/发状态机、10G 数据与 SOF/EOF/REM/ready；用于区分预取、反压保持、补读和排空。'),
    'rx_fifo': ('10G 接收跨时钟 FIFO', '接收数据/有效/帧标记、用户域与存储域时钟复位、FIFO 写读使能/满空/忙、frame 握手、源域丢失计数及目的域同步计数；用于检查按序透传和满时丢失。'),
    'ring': ('上行拼接与八块队列', '输入 frame、half/pair/tail、FDMA 全部写事务、状态机和响应、used_bytes、seal/push/pop、读写块指针、head/queued/irq/cpu_ack、丢失计数；用于确认“成功响应之后发布”、低32bit紧凑拼接和队列保护。'),
    'axi': ('FDMA 与 AXI 五通道', 'FDMA 读写请求/长度/数据/完成/错误、AXI AW/W/B/AR/R 全部接口、内部地址/拍数/状态、RAM 门控与错误注入；用于检查高地址、4KiB/256拍拆分及反压。'),
    'axi_tail': ('WSTRB 部分字节写', '保留 CONV_DMA 与 RAM 的完整读写接口和内部状态，重点比较 fdma_wstrb、M_AXI_WSTRB、写数据与读回数据；用于证明低四字节更新且高四字节保留。'),
    'regs': ('CPU AXI-Lite 寄存器交互', '完整 AXI-Lite 五通道、CPU_WR_DONE 及边沿检测、start/done、ACK/WSTRB、地址长度锁存和队头状态输入/读回；用于检查一次提交一次启动、忙时保持、硬件清零与 ACK 字节过滤。'),
}

def main():
    manifest = []
    for case in CASES:
        folder = OUT / case
        signals, stats, end, unit = parse_vcd(folder / f'{case}.vcd')
        by_path = {s['path']: s for s in signals}
        cfg_path = folder / f'{case}.wcfg'
        tree = ET.parse(cfg_path)
        for db in tree.findall('.//db_ref'):
            db.set('path', str(folder / f'{case}.wdb'))
        zoom = tree.find('zoom_setting')
        zoom.clear()
        scale = re.fullmatch(r'(\d+)\s*(s|ms|us|ns|ps|fs)', unit)
        if not scale: raise RuntimeError(f'Unexpected VCD timescale: {unit}')
        for tag, value in [('ZoomStartTime', 0), ('ZoomEndTime', end * int(scale[1])), ('Cursor1Time', 0)]:
            ET.SubElement(zoom, tag, time=f'{value}{scale[2]}')
        for obj in tree.findall('.//wvobject'):
            if obj.get('type') == 'array':
                prop = obj.find("obj_property[@name='Radix']")
                if prop is None: prop = ET.SubElement(obj, 'obj_property', name='Radix')
                prop.text = 'HEXRADIX'
        tree.write(cfg_path, encoding='UTF-8', xml_declaration=True)
        entries = {norm(o.get('fp_name')): o.get('type') for o in tree.findall('.//wvobject') if (o.get('fp_name') or '').startswith('/')}
        missing = sorted(set(by_path) - set(entries))
        # Clocking blocks can contain recorded aliases; never silently omit them.
        if missing:
            raise RuntimeError(f'{case}: VCD signals absent from WCFG: {missing[:10]}')
        rows = []
        for path, kind in entries.items():
            vcd = by_path.get(path)
            row = {'signal': path, 'wcfg_type': kind, 'vcd_width': vcd['width'] if vcd else '', 'coverage': 'VCD+WDB' if vcd else 'WDB object; no VCD scalar/vector', 'group': 'core' if path.count('/') <= 3 else 'hierarchy'}
            row.update(stats[vcd['code']] if vcd else {k: '' for k in next(iter(stats.values()))})
            rows.append(row)
        with (folder / 'signals.csv').open('w', encoding='utf-8-sig', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=list(rows[0]))
            writer.writeheader(); writer.writerows(rows)
        (folder / 'signals.txt').write_text('\n'.join(entries) + '\n', encoding='utf-8-sig')
        files = [Path(s.strip()) for s in (folder / 'files.txt').read_text(encoding='utf-8-sig').splitlines() if s.strip()]
        sim_dir = folder / f'project/wave_{case}.sim/sim_1/behav/xsim'
        glbl = sim_dir / 'glbl.v'
        if glbl.is_file() and glbl not in files: files.append(glbl)
        elaborate = (sim_dir / 'elaborate.log').read_text(encoding='utf-8', errors='replace')
        for library in ['cdc', 'fifo', 'memory']:
            if f'Compiling module xpm.xpm_{library}' in elaborate:
                f = Path(f'D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_{library}/hdl/xpm_{library}.sv')
                if f not in files: files.append(f)
        (folder / 'files.txt').write_text('\n'.join(f.as_posix() for f in files) + '\n', encoding='utf-8-sig')
        sources = []
        for f in files:
            if not f.is_file(): raise RuntimeError(f'Missing source: {f}')
            sources.append({'path': str(f), 'sha256': hashlib.sha256(f.read_bytes()).hexdigest()})
        (folder / 'source_hashes.json').write_text(json.dumps(sources, indent=2, ensure_ascii=False), encoding='utf-8-sig')
        dut_names = {'1g': 'rtds_1g_periodic_tx.v', 'tx': 'fdma_aurora_brg_tx.v', 'rx_fifo': 'rtds_rx_frame_fifo.v', 'ring': 'rtds_rx_block_writer.v', 'axi': 'CONV_DMA.v', 'axi_tail': 'CONV_DMA.v', 'regs': 'INFO_EXCH.v'}
        scope_files = {f'/tb_rtds_{case}': next(f for f in files if f.name == f'tb_rtds_{case}.sv'), f'/tb_rtds_{case}/bus': next(f for f in files if f.name == f'rtds_{case}_test_if.sv'), f'/tb_rtds_{case}/U_DUT': next(f for f in files if f.name == dut_names[case])}
        mapping = []
        for row in rows:
            scope, _, name = row['signal'].rpartition('/')
            if scope not in scope_files: continue
            f = scope_files[scope]
            found = ''
            for line_number, line in enumerate(f.read_text(encoding='utf-8-sig', errors='replace').splitlines(), 1):
                if re.search(r'(?<![\w$])' + re.escape(name) + r'(?![\w$])', line.split('//')[0]):
                    found = line_number; break
            mapping.append({'signal': row['signal'], 'source': str(f), 'first_code_occurrence_line': found, 'lookup_name': name})
        with (folder / 'signal_sources.csv').open('w', encoding='utf-8-sig', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=list(mapping[0])); writer.writeheader(); writer.writerows(mapping)
        log = (folder / 'simulation.log').read_text(encoding='utf-8', errors='replace')
        passes = [s for s in log.splitlines() if ('PASS' in s and not s.lstrip().startswith('#'))]
        if not any('TEST PASS' in s for s in passes): raise RuntimeError(f'No TEST PASS: {case}')
        item = {'case': case, 'wcfg_signals': len(entries), 'vcd_signals': len(signals), 'end_time': end, 'timescale': unit, 'sources': len(sources), 'pass_lines': passes, 'vcd_missing_from_wcfg': missing}
        manifest.append(item)
        title, why = PURPOSE[case]
        md = [f'# {case}：{title}', '', why, '', f'当前本机重跑日志：{len(entries)} 个 WCFG 对象，{len(signals)} 个 VCD 声明；结束时间 {end} × {unit}。', '', '```text', *passes, '```', '', '## 核心层信号与变化概要', '', '以下逐项列出测试顶层、接口与 DUT 第一层信号。深层 CDC/XPM、clocking block 别名和存储对象见 signals.csv / signals.txt；WCFG 同时包含完整层次。变化次数不包含初值，不等于成功握手次数；已知值范围按无符号二进制解释，X/Z 次数包含初始化阶段，不单独判错。时间单位见上文。', '', '| 信号全名 | 位宽 | 变化次数 | 首次变化 | 最后变化 | 已知最小值 | 已知最大值 |', '|---|---:|---:|---:|---:|---:|---:|']
        for row in rows:
            if row['group'] == 'core':
                md.append('| `' + row['signal'] + '` | ' + ' | '.join(str(row[k]) for k in ['vcd_width','changes','first_change','last_change','known_min','known_max']) + ' |')
        md += ['', '## 仿真源码文件列表（编译顺序）', '', *[f'- [{f.name}]({f.as_posix()})' for f in files], '']
        (folder / 'signals_summary.md').write_text('\n'.join(md), encoding='utf-8-sig')
        (folder / f'Open_{case}.cmd').write_bytes(('@echo off\r\n' + r'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\..\scripts\Open-LocalWave.ps1" -Case ' + case + '\r\nif errorlevel 1 pause\r\n').encode('ascii'))
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding='utf-8-sig')
    print(json.dumps(manifest, indent=2, ensure_ascii=False))

if __name__ == '__main__':
    main()
