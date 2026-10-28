#!/usr/bin/env python3
"""Show the current demo event stream in a separate read-only Tk window."""
import argparse
import json
import tkinter as tk
from pathlib import Path
from tkinter import scrolledtext


def describe(item):
    event = item.get('event', '')
    data = item.get('data') or {}
    if event == 'PHASE':
        return '步骤：' + item.get('description', item.get('phase', ''))
    if event == 'FAIL':
        return '停止：' + item.get('error', '') + '；未自动重试或清错。'
    if event == 'DONE':
        return '本轮完成：' + item.get('status', '') + '。仅覆盖板内 VIO 测试。'
    if event == 'CASE_DONE':
        return '阶段完成：%s；记录 %s' % (item.get('case'), item.get('run_id'))
    if event == 'VIO_STATE':
        return 'VIO 状态：' + json.dumps(item.get('values', {}), ensure_ascii=False)
    if event != 'ARM_EVENT':
        return None
    name = data.get('event')
    if name == 'DEMO_HOLD':
        return '%s：队列 %s/8；观察约 %s 秒。' % (data.get('stage'), data.get('queue'), data.get('seconds'))
    if name == 'STATE_READY' and data.get('offset') == '0x30':
        return '硬件已确认：待取块数 %s/8。' % data.get('value')
    if name == 'REGISTERS':
        v = data.get('values', {})
        return '寄存器快照 %s：DDR=%s，队列=%s，丢字=%s。' % (
            data.get('label'), v.get('0x2c'), v.get('0x30'), v.get('0x38'))
    if name == 'BLOCK_READ_BEGIN':
        return '准备读取：地址 %s，序号 %s，有效 %s Byte，队列 %s/8。' % (
            data.get('address'), data.get('sequence'), data.get('effective'), data.get('remaining'))
    if name == 'BLOCK_DATA_VERIFIED':
        b = data.get('block', {})
        return '数据一致：序号 %s，地址 %s，DMA %s/%s Byte，有效数据 %s。' % (
            b.get('sequence'), b.get('address'), b.get('completed'), b.get('requested'), b.get('data_hex'))
    if name == 'BLOCK_ACK_CONFIRMED':
        return '归还已确认：序号 %s，剩余 %s/8。' % (data.get('sequence'), data.get('remaining'))
    if name == 'READ_CLEAR_ONCE':
        return '正式实验读取通知 0x10 一次；读清通知不归还块。'
    if name == 'DATA_MATCH':
        return 'DDR 数据比较一致：' + str(data.get('data_hex'))
    if name == 'CONTROL_REQUEST':
        return 'Vivado 操作：%s %s' % (data.get('action'), data.get('params', {}))
    if name == 'CONTROL_COMPLETE' and data.get('action') == 'save':
        return 'ILA 已采集：' + str((data.get('response') or {}).get('path', ''))
    if name == 'FAILURE':
        return 'ARM 实验失败：' + str(data.get('error'))
    return None


class NoticeWindow:
    def __init__(self, root, path):
        self.root, self.path, self.offset = root, Path(path), 0
        root.title('RTDS 上板联调实时提示')
        root.geometry('880x620')
        tk.Label(root, text='RTDS 板内联调：步骤、实测结果与提示', font=('Microsoft YaHei', 14, 'bold')).pack(anchor='w', padx=12, pady=8)
        self.status = tk.StringVar(value='等待本轮事件。窗口只显示日志，不操作硬件。')
        tk.Label(root, textvariable=self.status, anchor='w', wraplength=840, font=('Microsoft YaHei', 11)).pack(fill='x', padx=12)
        self.text = scrolledtext.ScrolledText(root, font=('Microsoft YaHei', 10), wrap='word')
        self.text.pack(fill='both', expand=True, padx=12, pady=10)
        self.text.insert('end', '观察对应的 Vivado ILA/VIO 和 Linux 寄存器窗口。\n采样可能漏掉瞬态；ILA 显示的是触发后的采样。\n\n')
        self.poll()

    def poll(self):
        try:
            if self.path.exists():
                if self.path.stat().st_size < self.offset:
                    self.offset = 0
                with self.path.open('r', encoding='utf-8') as stream:
                    stream.seek(self.offset)
                    while True:
                        start = stream.tell()
                        line = stream.readline()
                        if not line or not line.endswith('\n'):
                            stream.seek(start)
                            break
                        try:
                            item = json.loads(line)
                        except ValueError:
                            continue
                        message = describe(item)
                        if message:
                            self.status.set(message)
                            self.text.insert('end', '%s  %s\n' % (item.get('pc_time', ''), message))
                            self.text.see('end')
                    self.offset = stream.tell()
        except OSError as error:
            self.status.set('读取事件日志失败：' + str(error))
        self.root.after(250, self.poll)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--events', required=True)
    args = parser.parse_args()
    root = tk.Tk()
    NoticeWindow(root, args.events)
    root.mainloop()


if __name__ == '__main__':
    main()
