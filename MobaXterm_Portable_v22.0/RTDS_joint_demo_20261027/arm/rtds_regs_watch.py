#!/usr/bin/env python3
"""Read-only multi-register viewer. No DMA, register writes, or read-clear access."""
import argparse
from collections import deque
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

# 访问属性按硬件定义标注；监视器本身始终只读。
# 0x10 读清通知，0x14 写1归还：两者都不加入轮询列表。
REGS = (
    (0x00, 'VERSION', 'R'), (0x04, 'BUILD_ID', 'R'),
    (0x08, 'BLOCK_CAPACITY', 'R'), (0x0c, 'TEMP_RAW', 'R'),
    (0x18, 'RX_HEAD_ADDR', 'R'), (0x1c, 'RX_VALID_BYTES', 'R'),
    (0x20, 'DOWN_TRIGGER_BUSY', 'R/W1P'),
    (0x24, 'DOWN_START_ADDR', 'RW'), (0x28, 'DOWN_BYTES', 'RW'),
    (0x2c, 'DDR_STATUS', 'R'), (0x30, 'RX_BLOCKS', 'R'),
    (0x34, 'RX_HEAD_SEQ', 'R'), (0x38, 'RX_DROPPED', 'R'),
)


def discover_bar(sysfs=Path('/sys/bus/pci/devices'), bdf=None):
    matches=[]
    for p in Path(sysfs).iterdir():
        if bdf and p.name != bdf:
            continue
        try:
            if int((p/'vendor').read_text(),16)==0x10ee and int((p/'device').read_text(),16)==0x8032:
                matches.append(p)
        except (OSError,ValueError):
            continue
    if len(matches)!=1:
        raise RuntimeError('Expected one 10ee:8032 endpoint; use --bdf when needed')
    p=matches[0]
    base,end,flags=(int(s,16) for s in (p/'resource').read_text().splitlines()[0].split())
    if base==0 or end-base+1<0x3c or not flags & 0x200:
        raise RuntimeError('Invalid BAR0; no register access performed')
    return p.name,base


def parse_value(text,address):
    values=[int(v,16) for a,v in re.findall(
        r'^\s*(?:0x)?([0-9a-fA-F]+):\s+(?:0x)?([0-9a-fA-F]{1,8})\s*$',text,re.M)
        if int(a,16)==address]
    if len(values)!=1:
        raise RuntimeError('Ambiguous io output for 0x%x' % address)
    return values[0]


def sample(base,io):
    values={}
    for offset,_,_ in REGS:
        address=base+offset
        # 每次只读取一个安全地址，不能连续扫过0x10。
        p=subprocess.run([io,'-4','-r',hex(address)],capture_output=True,
                         text=True,check=True,timeout=2)
        values[offset]=parse_value(p.stdout,address)
        if offset==0 and values[offset]!=0x2001:
            raise RuntimeError('Unexpected version/BAR value 0x%08x; viewer stopped' % values[offset])
    return values


def describe(offset,value):
    if offset==0x30:
        return 'queue %d/8' % value
    if offset in (0x08,0x1c,0x28):
        return '%d bytes' % value
    if offset==0x2c:
        return 'ready=%d errors=0x%x' % ((value & 3)==3,value & 0x1c)
    if offset==0x20:
        return 'busy=%d; W1 launches downlink' % (value & 1)
    if offset==0x0c:
        return 'raw code, not Celsius'
    if offset==0x38:
        return 'dropped words; do not clear'
    if offset==0x34:
        return 'head seq; 0 when empty'
    return ''


class Journal:
    """只读测试日志。W记录是软件意图/返回，不是硬件总线嗅探器。"""
    def __init__(self,path):
        self.path=Path(path)
        self.position=0
        self.pending=''
        self.lines=deque(maxlen=3)
        self.new_lines=[]

    def update(self):
        self.new_lines=[]
        try:
            size=self.path.stat().st_size
            if size<self.position:
                self.position=0;self.pending=''
            # 首次只取末尾64KiB，避免旧日志影响刷新。
            if self.position==0 and size>65536:
                self.position=size-65536
                discard=True
            else:
                discard=False
            with self.path.open('r',encoding='utf-8',errors='replace') as f:
                f.seek(self.position)
                if discard:
                    f.readline()
                text=self.pending+f.read()
                self.position=f.tell()
            parts=text.split('\n');self.pending=parts.pop()
            for line in parts:
                try:
                    event=json.loads(line)
                except (ValueError,TypeError):
                    continue
                message=self.describe(event)
                if message:
                    self.lines.append(message)
                    self.new_lines.append(message)
        except FileNotFoundError:
            pass
        return list(self.lines)

    @staticmethod
    def describe(e):
        name=e.get('event')
        if name=='WRITE_INTENT':
            return 'W INTENT   %s = %s (not completion proof)' % (e.get('offset'),e.get('value'))
        if name=='WRITE_RETURNED':
            return 'W RETURNED %s (io returned; verify state)' % e.get('offset')
        if name=='READ_CLEAR_ONCE':
            return 'R CLEAR    %s -> %s (performed by test, not viewer)' % (e.get('offset'),e.get('value'))
        if name=='BLOCK_ACK_CONFIRMED':
            return 'ACK CHECK  seq=%s queue=%s' % (e.get('sequence'),e.get('remaining'))
        if name=='REGISTERS':
            values=e.get('values',{})
            return 'R SNAPSHOT %-20s queue=%s DDR=%s' % (e.get('label'),values.get('0x30'),values.get('0x2c'))
        return None


def frame(bdf,base,values,previous,events,elapsed):
    lines=['RTDS register viewer | READ ONLY | Ctrl+C to stop',
           'BDF=%s BAR0=0x%08x elapsed=%.1fs (* changed since prior refresh)' % (bdf,base,elapsed),
           'Sequential reads, not atomic. No DMA, no writes, no read-clear.',
           'OFF ACC   NAME               HEX             DEC DETAIL']
    for offset,name,access in REGS:
        v=values[offset]
        marker='*' if previous and previous.get(offset)!=v else ' '
        lines.append('%s%02X %-5s %-18s %08X %10d %s' %
            (marker,offset,access,name,v,v,describe(offset,v)[:23]))
    lines.extend([' 10 RC    NOT POLLED         Reading clears notification.',
                  ' 14 R/W1P NOT POLLED         W1 returns a block; use validated test.',
                  'Recent TEST R/W journal (manual io writes are not captured):'])
    lines.extend([line[:78] for line in events] or ['No journal events yet.'])
    lines.extend(['']*(3-len(events)))
    return '\n'.join(lines)+'\n'


def changed_rows(values,previous,include_temperature=False):
    # 温度原始码会持续抖动，默认不让它触发刷日志；仍在首屏/周期快照显示。
    return [(o,n,a,previous[o],values[o]) for o,n,a in REGS
            if values[o]!=previous[o] and (o!=0x0c or include_temperature)]


def change_output(values,previous,events,elapsed,include_temperature=False):
    rows=changed_rows(values,previous,include_temperature)
    # 普通快照读取相同状态不重复打印；实际写入、读清、归还事件仍各记录一次。
    events=[e for e in events if not e.startswith('R SNAPSHOT')]
    if not rows and not events:
        return ''
    lines=['[+%.1fs] observed changes / new test actions' % elapsed]
    for offset,name,access,old,new in rows:
        lines.append('  0x%02X %-18s %-5s %08X -> %08X (%d)' %
                     (offset,name,access,old,new,new))
    lines.extend('  '+event for event in events)
    return '\n'.join(lines)+'\n'


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--interval',type=float,default=0.5)
    parser.add_argument('--bdf')
    parser.add_argument('--once',action='store_true')
    parser.add_argument('--plain',action='store_true',help='Compatibility flag; output never clears the screen')
    parser.add_argument('--mode',choices=['changes','periodic'],default='changes',
                        help='Default: one baseline then changed business values only; periodic: full snapshots')
    parser.add_argument('--include-temperature',action='store_true',
                        help='Also print temperature-only changes (may be noisy)')
    parser.add_argument('--log',default=str(Path(__file__).resolve().parent.parent/'live_status.log'))
    args=parser.parse_args(argv)
    if args.interval<0.1:
        parser.error('interval must be >=0.1 seconds')
    io=shutil.which('io')
    if not io:
        raise RuntimeError('io command is missing')
    bdf,base=discover_bar(bdf=args.bdf)
    journal=Journal(args.log)
    started=time.monotonic();previous=None
    try:
        while True:
            cycle=time.monotonic()
            values=sample(base,io)
            events=journal.update()
            elapsed=time.monotonic()-started
            if previous is None or args.mode=='periodic':
                output=frame(bdf,base,values,previous,events,elapsed)
                if previous is None and args.mode=='changes' and not args.once:
                    output+=('CHANGE-ONLY: unchanged business values produce no output; polling continues.\n'
                             'Temperature-only changes are %s. No screen clearing.\n' %
                             ('enabled' if args.include_temperature else 'muted'))
            else:
                output=change_output(values,previous,journal.new_lines,elapsed,args.include_temperature)
            if output:
                print(output,end='',flush=True)
            previous=values
            if args.once:
                break
            time.sleep(max(0,args.interval-(time.monotonic()-cycle)))
    except KeyboardInterrupt:
        return 0
    return 0


if __name__=='__main__':
    try:
        sys.exit(main())
    except (OSError,RuntimeError,subprocess.SubprocessError) as exc:
        print('VIEWER STOPPED: '+str(exc),file=sys.stderr)
        sys.exit(1)
