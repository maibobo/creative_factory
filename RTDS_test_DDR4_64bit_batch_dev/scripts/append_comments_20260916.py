# -*- coding: utf-8 -*-
"""
append_comments_20260916.py — RTL/TB 注释补充工具（2026-09-16）

用途：按 JSON 计划为源文件做两类零逻辑改动：
  1) append：在指定行（1-based）行尾追加 4 空格 + // 注释
     —— 用于 assign 语句统一行尾注释（本行结束后空 4 格处开始）
  2) insert_before：在指定行前插入注释行（缩进取目标行缩进）
     —— 用于 always/task/initial 等块的上方注释

约束：不修改/删除任何原有字符与注释；不做任何代码变换。
用法：python append_comments_20260916.py <plan.json>
计划格式：
{
  "file_path": "<绝对路径>",
  "append": {"170": "注释文本"},
  "insert_before": {"83": ["// 第一行", "// 第二行"]}
}
"""
import json
import sys
import io

def main():
    if len(sys.argv) != 2:
        print("usage: python append_comments_20260916.py <plan.json>")
        sys.exit(2)
    with io.open(sys.argv[1], "r", encoding="utf-8") as f:
        plan = json.load(f)

    path = plan["file_path"]
    with io.open(path, "r", encoding="utf-8", newline="") as f:
        lines = f.readlines()

    # 判断换行风格，保持原样
    crlf = any(l.endswith("\r\n") for l in lines)

    append_map = {int(k): v for k, v in plan.get("append", {}).items()}
    insert_map = {int(k): v for k, v in plan.get("insert_before", {}).items()}

    # 冲突检查：同一行既要 append 又要 insert_before 时报错
    clash = set(append_map) & set(insert_map)
    if clash:
        print("ERROR: line clash: %s" % sorted(clash))
        sys.exit(1)

    for ln in append_map:
        if not (1 <= ln <= len(lines)):
            print("ERROR: append line %d out of range (file %s, %d lines)" % (ln, path, len(lines)))
            sys.exit(1)
        raw = lines[ln - 1].rstrip("\r\n")
        if "//" in raw:
            print("ERROR: line %d already has a comment: %s" % (ln, raw.strip()))
            sys.exit(1)
        lines[ln - 1] = raw.rstrip() + "    // " + append_map[ln] + ("\r\n" if crlf else "\n")

    out = []
    for idx, l in enumerate(lines, start=1):
        if idx in insert_map:
            target_indent = l[:len(l) - len(l.lstrip())]
            eol = "\r\n" if crlf else "\n"
            for c in insert_map[idx]:
                out.append(target_indent + c + eol)
        out.append(l)

    with io.open(path, "w", encoding="utf-8", newline="") as f:
        f.writelines(out)

    print("OK %s: %d appended, %d inserted-before, total %d -> %d lines"
          % (path, len(append_map), len(insert_map), len(lines), len(out)))

if __name__ == "__main__":
    main()
