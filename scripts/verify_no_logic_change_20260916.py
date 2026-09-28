# -*- coding: utf-8 -*-
"""
verify_no_logic_change_20260916.py — 注释补充后的零逻辑改动校验（2026-09-16）

对 修改前(备份) / 修改后(当前) 两个文件：
  1) 剥离 // 行注释、/* */ 块注释与行尾空白
  2) 按空白切分 token，逐 token 对比
任何 token 差异即失败（退出码 1），完全一致输出 PASS。
用法：python verify_no_logic_change_20260916.py <before_file> <after_file>
"""
import sys
import io
import re

def strip_comments_and_tokenize(text):
    # 移除块注释（保留换行数以稳定行为，仅作 tokenize 不必）
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    tokens = []
    for line in text.splitlines():
        # 去掉行注释
        idx = line.find("//")
        if idx >= 0:
            line = line[:idx]
        tokens.extend(line.split())
    return tokens

def main():
    if len(sys.argv) != 3:
        print("usage: python verify_no_logic_change_20260916.py <before> <after>")
        sys.exit(2)
    with io.open(sys.argv[1], "r", encoding="utf-8", errors="replace") as f:
        a = strip_comments_and_tokenize(f.read())
    with io.open(sys.argv[2], "r", encoding="utf-8", errors="replace") as f:
        b = strip_comments_and_tokenize(f.read())
    if a == b:
        print("PASS %s == %s (%d tokens)" % (sys.argv[1], sys.argv[2], len(a)))
        return
    # 找出第一处差异便于定位
    n = min(len(a), len(b))
    for i in range(n):
        if a[i] != b[i]:
            print("DIFF at token #%d: before=%r after=%r" % (i, a[i], b[i]))
            print("context before: %r" % (" ".join(a[max(0, i - 6):i + 6])))
            print("context after : %r" % (" ".join(b[max(0, i - 6):i + 6])))
            sys.exit(1)
    print("DIFF token count: before=%d after=%d" % (len(a), len(b)))
    print("tail before: %r" % (" ".join(a[n - 6:] if len(a) >= 6 else a)))
    print("tail after : %r" % (" ".join(b[n - 6:] if len(b) >= 6 else b)))
    sys.exit(1)

if __name__ == "__main__":
    main()
