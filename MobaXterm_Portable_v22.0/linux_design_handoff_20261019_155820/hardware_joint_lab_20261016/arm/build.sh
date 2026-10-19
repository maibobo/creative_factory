#!/bin/sh
# 在 ARM/Linux 用户态编译一次性 XDMA 辅助程序；本脚本不安装或重载任何内核驱动。
set -eu
# -e 让编译/替换失败立即退出，-u 阻止使用未定义变量。
cd "$(dirname "$0")"
# 先生成临时文件，且把全部警告当错误；编译成功后才替换现有 rtds_dma，避免留下半成品。
cc -std=c11 -O2 -Wall -Wextra -Werror rtds_dma.c -o rtds_dma.new
mv rtds_dma.new rtds_dma
# 打印目标机架构，便于确认二进制是在预期 ARM 主机上构建的。
printf 'Built rtds_dma for %s\n' "$(uname -m)"
