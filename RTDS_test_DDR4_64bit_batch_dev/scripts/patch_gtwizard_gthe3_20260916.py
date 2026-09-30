# -*- coding: utf-8 -*-
"""
patch_gtwizard_gthe3_20260916.py — XDMA GT 向导仿真源码 part-select 兼容补丁

问题：Vivado 2020.2 生成的 design_1_xdma_0_0_pcie3_ip_gt_gtwizard_gthe3.v 中
  [f_ub_cm(W,(4*cm)+3) : f_lb_cm(W,4*cm)] / [f_ub_ch(W,(4*ch)+3) : f_lb_ch(W,4*ch)]
在"该 quad/common 未启用"的 generate 迭代中 ub<lb，xsim elaborate 报
  [VRFC 10-1219] part-select direction is opposite from prefix index direction

修复：改为方向无关的 indexed part-select：[f_lb_cm(W,4*cm) +: W]（语义等价：
启用时 ub=lb+W-1；未启用分支本就不应被业务使用）。
注意：export_ip_user_files -force 会覆盖本文件；重导出后需重放本补丁。
"""
import io
import re
import sys
import shutil

PATH = (r"c:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev\RTDS_test_DDR4_64bit.ip_user_files"
        r"\bd\design_1\ip\design_1_xdma_0_0\ip_0\ip_0\sim\design_1_xdma_0_0_pcie3_ip_gt_gtwizard_gthe3.v")

PAT_CM = re.compile(r"\[f_ub_cm\(\s*(\d+)\s*,\s*\(4\*cm\)\+3\)\s*:\s*f_lb_cm\(\s*(\d+)\s*,\s*4\*cm\)\s*\]")
PAT_CH = re.compile(r"\[f_ub_ch\(\s*(\d+)\s*,\s*\(4\*ch\)\+3\)\s*:\s*f_lb_ch\(\s*(\d+)\s*,\s*4\*ch\)\s*\]")


def main():
    with io.open(PATH, "r", encoding="utf-8", errors="replace") as f:
        text = f.read()
    orig = text
    n_cm = n_ch = 0

    def sub_cm(m):
        nonlocal n_cm
        n_cm += 1
        w = m.group(1)
        return "[f_lb_cm( %s,4*cm) +: %s]" % (w, w)

    def sub_ch(m):
        nonlocal n_ch
        n_ch += 1
        w = m.group(1)
        return "[f_lb_ch( %s,4*ch) +: %s]" % (w, w)

    text = PAT_CM.sub(sub_cm, text)
    text = PAT_CH.sub(sub_ch, text)
    if text == orig:
        print("NO CHANGE (already patched or pattern not found)")
        sys.exit(0)
    shutil.copy2(PATH, PATH + ".bak_20260916")
    with io.open(PATH, "w", encoding="utf-8", newline="") as f:
        f.write(text)
    print("PATCHED cm=%d ch=%d lines; backup at %s.bak_20260916" % (n_cm, n_ch, PATH))


if __name__ == "__main__":
    main()
