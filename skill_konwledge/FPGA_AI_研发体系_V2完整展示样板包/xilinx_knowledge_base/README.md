# Xilinx 工程知识库

这是一个完全本地、可追溯、可重建的 Xilinx/FPGA 技术知识库。当前范围只覆盖：

- 通用基础：Vivado、Tcl、综合、仿真、时序、AXI/AXI-Stream、FIFO、CDC、时钟与 DMA。
- 复杂 IP：Aurora、PCIe/XDMA（含 NVMe 数据通路）、DDR/MIG、以太网/lwIP。
- 工程实践：接口适配、跨时钟域、回压、突发/4 KB 边界、复位、仿真、回归、上板检查。

明确不收录 HDMI/显示接口、USB、图像/视频、SIFT/CNN 等资料；商业报价、采购文件和大体量 Vivado 生成物也不进入索引。

## 目录

- `knowledge/`：人工整理的主题入口与工程速查。
- `corpus/`：从原始 PDF、DOC/DOCX、XLSX、Markdown、RTL、Tcl、XDC、XCI 等提取的可审计文本副本。
- `index/xilinx_kb.sqlite3`：SQLite FTS5 全文索引。
- `index/manifest.json`、`index/manifest.csv`：来源、哈希、别名、分类和抽取状态。
- `config/sources.json`：白名单来源和排除规则。
- `tools/build_kb.py`：增量重建脚本。
- `tools/search_kb.py`：命令行检索工具。

## 主题入口

- [范围、来源与证据规则](knowledge/00_范围与来源.md)
- [Aurora 工程速查](knowledge/01_Aurora_工程速查.md)
- [PCIe/XDMA 工程速查](knowledge/02_PCIe_XDMA_工程速查.md)
- [DDR/MIG 工程速查](knowledge/03_DDR_MIG_工程速查.md)
- [以太网/RGMII/风暴过滤/DMA 工程速查](knowledge/04_以太网_工程速查.md)
- [跨 IP 集成检查表](knowledge/05_跨IP_集成检查表.md)

主题页中的“已通过”“未执行”“设计边界”严格分开。设计文档写了某个用例，不代表该用例已经运行；只有日志、报告或可重复脚本明确给出结果时才记为通过。

## 使用

重建：

```powershell
.\build.ps1
```

搜索：

```powershell
.\search.ps1 'Aurora lane_up channel_up'
.\search.ps1 '4KB 边界' --category pcie
.\search.ps1 'calib_complete' --category ddr --limit 15
.\search.ps1 '风暴窗口' --category ethernet
```

查看统计：

```powershell
.\search.ps1 --stats
```

检索结果始终返回原始文件绝对路径、知识库文本路径和命中片段。PDF、DOCX、XLSX 只做本地文字/单元格抽取，不渲染图片。
