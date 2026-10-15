# build_pcie_fdma_aurora_brg_adapter_design_doc

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\build_pcie_fdma_aurora_brg_adapter_design_doc.py`
- SHA-256: `2737bb725271dcd14bb8af118ca96695a3b3c213d868f4d42908b11580d45f26`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

```python
from __future__ import annotations

import math
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

import pypdfium2 as pdfium
from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
DOCS_DIR = ROOT / "docs"
ASSET_DIR = DOCS_DIR / "generated" / "pcie_fdma_aurora_brg_adapter_doc_assets"
RENDER_DIR = DOCS_DIR / "generated" / "pcie_fdma_aurora_brg_adapter_doc_render"
TEMPLATE = Path(
    r"D:\WeChatData\xwechat_files\wxid_y0pzuy6xx5rl21_97d1\msg\file\2026-07"
    r"\fdma_aurora_brg_IP总体设计与验证概述-origin.docx"
)
OUTPUT_DOCX = DOCS_DIR / "pcie_fdma_aurora_brg_adapter总体设计与验证方案.docx"
TEMP_DOCX = DOCS_DIR / "generated" / "pcie_fdma_aurora_brg_adapter_design_draft.docx"
SOFFICE = Path(r"C:\Program Files\LibreOffice\program\soffice.com")


FONT_CN = "SimSun"
FONT_EN = "Times New Roman"
FONT_CODE = "Consolas"
BLUE = "1F4E79"
LIGHT_BLUE = "D9EAF7"
LIGHT_GRAY = "F3F5F7"
BORDER = "7F7F7F"


TOC_ENTRIES = [
    (1, "Revision Record 修订记录", "Revision Record 修订记录"),
    (1, "目录", "目录"),
    (1, "1 工程背景与当前边界", "工程背景与当前边界"),
    (2, "1.1 设计依据与资料来源", "设计依据与资料来源"),
    (2, "1.2 当前 RTL 边界", "当前 RTL 边界"),
    (1, "2 原结构与最终结构对比", "原结构与最终结构对比"),
    (2, "2.1 adapter 插入前结构", "adapter 插入前结构"),
    (2, "2.2 adapter 插入后结构", "adapter 插入后结构"),
    (2, "2.3 adapter 与完整异步桥的边界", "adapter 与完整异步桥的边界"),
    (1, "3 pcie_fdma_aurora_brg_adapter 设计", "pcie_fdma_aurora_brg_adapter 设计"),
    (2, "3.1 内部职责", "内部职责"),
    (2, "3.2 关键接口与状态", "关键接口与状态"),
    (2, "3.3 CPU 到 Aurora 数据流", "CPU 到 Aurora 数据流"),
    (2, "3.4 Aurora 到 CPU 数据流", "Aurora 到 CPU 数据流"),
    (1, "4 PCIe.v 设计方案", "PCIe.v 设计方案"),
    (2, "4.1 保留边界", "保留边界"),
    (2, "4.2 与 design_1_wrapper 的连接", "与 design_1_wrapper 的连接"),
    (2, "4.3 link_enable 当前方案与最终建议", "link_enable 当前方案与最终建议"),
    (1, "5 主模块关键接口时序", "主模块关键接口时序"),
    (2, "5.1 INFO_EXCH 到 adapter 的 TX 启动", "INFO_EXCH 到 adapter 的 TX 启动"),
    (2, "5.2 FDMA read 与 rvalid stall", "FDMA read 与 rvalid stall"),
    (2, "5.3 完整桥 TX 帧边界", "完整桥 TX 帧边界"),
    (2, "5.4 完整桥 RX 到 FDMA write 与中断", "完整桥 RX 到 FDMA write 与中断"),
    (2, "5.5 RX 中断清除", "RX 中断清除"),
    (2, "5.6 完整异步桥内部 FIFO CDC", "完整异步桥内部 FIFO CDC"),
    (2, "5.7 link_enable 与 channel_up", "link_enable 与 channel_up"),
    (1, "6 剩余不变模块设计说明", "剩余不变模块设计说明"),
    (1, "7 BD 与扩展状态寄存器策略", "BD 与扩展状态寄存器策略"),
    (1, "8 验证方案与风险清单", "验证方案与风险清单"),
]


def font(size: int = 24, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        r"C:\Windows\Fonts\simhei.ttf" if bold else r"C:\Windows\Fonts\simsun.ttc",
        r"C:\Windows\Fonts\msyhbd.ttc" if bold else r"C:\Windows\Fonts\msyh.ttc",
        r"C:\Windows\Fonts\arial.ttf",
    ]
    for item in candidates:
        if Path(item).exists():
            return ImageFont.truetype(item, size)
    return ImageFont.load_default()


def ensure_dirs() -> None:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    RENDER_DIR.mkdir(parents=True, exist_ok=True)


def text_size(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.ImageFont) -> tuple[int, int]:
    bbox = draw.textbbox((0, 0), text, font=fnt)
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def wrap_text(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.ImageFont, max_width: int) -> list[str]:
    lines: list[str] = []
    for part in text.split("\n"):
        line = ""
        if part == "":
            lines.append("")
            continue
        for ch in part:
            trial = line + ch
            if text_size(draw, trial, fnt)[0] <= max_width:
                line = trial
            else:
                if line:
                    lines.append(line)
                line = ch
        if line:
            lines.append(line)
    return lines


def draw_wrapped(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    text: str,
    fnt: ImageFont.ImageFont,
    fill: str,
    max_width: int,
    line_gap: int = 8,
) -> int:
    x, y = xy
    lines = wrap_text(draw, text, fnt, max_width)
    for line in lines:
        draw.text((x, y), line, font=fnt, fill=fill)
        y += text_size(draw, line, fnt)[1] + line_gap
    return y


def draw_centered_wrapped(
    draw: ImageDraw.ImageDraw,
    box_xy: tuple[int, int, int, int],
    title: str,
    lines: list[str],
    title_font: ImageFont.ImageFont,
    body_font: ImageFont.ImageFont,
    title_fill: str = "#0F172A",
    body_fill: str = "#334155",
) -> None:
    x1, y1, x2, y2 = box_xy
    max_width = x2 - x1 - 30
    text_rows: list[tuple[str, ImageFont.ImageFont, str]] = []
    for row in wrap_text(draw, title, title_font, max_width):
        text_rows.append((row, title_font, title_fill))
    if lines:
        text_rows.append(("", body_font, body_fill))
    for line in lines:
        for row in wrap_text(draw, line, body_font, max_width):
            text_rows.append((row, body_font, body_fill))

    row_heights = [text_size(draw, row or " ", fnt)[1] for row, fnt, _ in text_rows]
    total_h = sum(row_heights) + max(0, len(text_rows) - 1) * 8
    y = y1 + max(12, (y2 - y1 - total_h) // 2)
    for (row, fnt, fill), h in zip(text_rows, row_heights):
        if row:
            w, _ = text_size(draw, row, fnt)
            draw.text((x1 + (x2 - x1 - w) / 2, y), row, font=fnt, fill=fill)
        y += h + 8


def arrow(
    draw: ImageDraw.ImageDraw,
    start: tuple[int, int],
    end: tuple[int, int],
    color: str = "#334155",
    width: int = 4,
) -> None:
    draw.line([start, end], fill=color, width=width)
    x1, y1 = start
    x2, y2 = end
    ang = math.atan2(y2 - y1, x2 - x1)
    length = 18
    spread = 0.45
    pts = [
        (x2, y2),
        (x2 - length * math.cos(ang - spread), y2 - length * math.sin(ang - spread)),
        (x2 - length * math.cos(ang + spread), y2 - length * math.sin(ang + spread)),
    ]
    draw.polygon(pts, fill=color)


def box(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int, int, int],
    title: str,
    lines: list[str] | None = None,
    fill: str = "#FFFFFF",
    outline: str = "#64748B",
) -> None:
    x1, y1, x2, y2 = xy
    draw.rounded_rectangle(xy, radius=16, fill=fill, outline=outline, width=3)
    draw_centered_wrapped(draw, xy, title, lines or [], font(50, True), font(38), "#0F172A", "#334155")


def new_canvas(title: str = "", subtitle: str | None = None, size: tuple[int, int] = (2200, 1120)) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", size, "white")
    draw = ImageDraw.Draw(img)
    return img, draw


def draw_original_structure() -> Path:
    path = ASSET_DIR / "fig_01_original_structure.png"
    img, d = new_canvas(size=(2200, 980))
    box(d, (80, 190, 410, 390), "debug 源", ["frame_gen", "66-bit 测试帧"], "#FFF7ED", "#EA580C")
    box(d, (555, 165, 900, 420), "DATA_CDC", ["遗留占位", "最终删除", "FIFO CDC"], "#FEF2F2", "#DC2626")
    box(d, (1045, 150, 1395, 435), "PCIe.v", ["旧 FDMA/IRQ", "BD 连接", "debug 边界"], "#EFF6FF", "#2563EB")
    box(d, (1535, 145, 1925, 440), "BD / XDMA", ["CONV_DMA", "INFO_EXCH", "BRAM"], "#F0FDF4", "#16A34A")
    box(d, (1535, 610, 1925, 790), "Host / CPU", ["BAR", "寄存器", "payload"], "#F8FAFC", "#64748B")
    box(d, (555, 630, 900, 800), "TX 未闭环", ["输出悬空", "仅 ILA 观察"], "#FEF2F2", "#DC2626")

    arrow(d, (410, 290), (555, 290), "#EA580C", width=6)
    arrow(d, (900, 290), (1045, 290), "#2563EB", width=6)
    arrow(d, (1395, 290), (1535, 290), "#16A34A", width=6)
    arrow(d, (1730, 440), (1730, 610), "#16A34A", width=6)
    arrow(d, (1045, 715), (900, 715), "#DC2626", width=6)
    arrow(d, (1395, 715), (1045, 715), "#DC2626", width=6)
    img.save(path)
    return path


def draw_final_structure() -> Path:
    path = ASSET_DIR / "fig_02_final_structure.png"
    img, d = new_canvas(size=(2200, 980))
    box(d, (70, 310, 360, 545), "Host / CPU", ["BAR", "寄存器", "payload"], "#F8FAFC", "#64748B")
    box(d, (485, 250, 835, 610), "BD / XDMA", ["CONV_DMA", "INFO_EXCH", "BRAM"], "#F0FDF4", "#16A34A")
    box(d, (960, 265, 1265, 595), "PCIe.v", ["PCIe 边界", "adapter", "ILA"], "#EFF6FF", "#2563EB")
    box(d, (1390, 240, 1710, 620), "adapter", ["软件协议", "地址/长度", "IRQ/status", "FDMA 控制"], "#FEFCE8", "#CA8A04")
    box(d, (1835, 180, 2150, 690), "FDMA2AURORA\n完整异步桥", ["数据桥", "FIFO CDC", "Aurora IP/GT", "link 状态"], "#ECFDF5", "#059669")
    box(d, (1835, 770, 2150, 910), "Aurora 链路", ["对端设备", "真实闭环"], "#F8FAFC", "#0F766E")
    arrow(d, (360, 400), (485, 400), "#16A34A", width=7)
    arrow(d, (485, 500), (360, 500), "#16A34A", width=7)
    arrow(d, (835, 430), (960, 430), "#2563EB", width=7)
    arrow(d, (1265, 430), (1390, 430), "#CA8A04", width=7)
    arrow(d, (1710, 430), (1835, 430), "#059669", width=7)
    arrow(d, (1992, 690), (1992, 770), "#0F766E", width=7)
    img.save(path)
    return path


def draw_adapter_internal() -> Path:
    path = ASSET_DIR / "fig_03_adapter_internal.png"
    img, d = new_canvas(size=(2200, 980))
    box(d, (70, 160, 470, 380), "INFO_EXCH", ["RD_START", "addr / len", "clear"], "#F8FAFC", "#64748B")
    box(d, (70, 565, 470, 785), "IRQ/status", ["INT_STATE", "irq_req", "sticky/error"], "#F8FAFC", "#64748B")
    box(d, (620, 150, 1080, 795), "adapter", ["原软件协议", "地址/长度检查", "512B 计数", "start/done", "IRQ 汇总", "不含 Aurora/CDC"], "#FEFCE8", "#CA8A04")
    box(d, (1235, 160, 1625, 380), "BD FDMA", ["fdma_r*", "fdma_w*", "64 beat"], "#F0FDF4", "#16A34A")
    box(d, (1235, 565, 1625, 785), "桥状态", ["link_enable", "channel/lane", "fifo/error"], "#EFF6FF", "#2563EB")
    box(d, (1780, 245, 2140, 705), "FDMA2AURORA\n完整异步桥", ["FDMA 数据桥", "异步 FIFO", "Aurora IP/GT"], "#ECFDF5", "#059669")

    arrow(d, (470, 270), (620, 270), "#64748B", width=7)
    arrow(d, (620, 675), (470, 675), "#64748B", width=7)
    arrow(d, (1080, 270), (1235, 270), "#16A34A", width=7)
    arrow(d, (1235, 330), (1080, 330), "#16A34A", width=7)
    arrow(d, (1080, 675), (1235, 675), "#2563EB", width=7)
    arrow(d, (1625, 270), (1780, 390), "#059669", width=7)
    arrow(d, (1780, 560), (1625, 675), "#059669", width=7)
    img.save(path)
    return path


def draw_bidirectional_flow() -> Path:
    path = ASSET_DIR / "fig_04_bidirectional_flow.png"
    img, d = new_canvas(size=(2200, 980))
    y = 165
    blocks = [
        ("CPU 写", ["payload", "XDMA BAR"]),
        ("INFO_EXCH", ["start", "addr / len"]),
        ("adapter", ["检查", "FDMA read"]),
        ("完整桥 TX", ["FIFO CDC", "Aurora TX"]),
        ("Aurora 链路", ["发送"]),
    ]
    x_positions = [70, 500, 930, 1360, 1790]
    for x, (title, lines) in zip(x_positions, blocks):
        box(d, (x, y, x + 330, y + 190), title, lines, "#F8FAFC", "#2563EB")
    for i in range(len(x_positions) - 1):
        arrow(d, (x_positions[i] + 330, y + 95), (x_positions[i + 1], y + 95), "#2563EB", width=7)

    y = 570
    blocks = [
        ("Aurora 链路", ["接收"]),
        ("完整桥 RX", ["Aurora RX", "FIFO CDC"]),
        ("adapter", ["FDMA write", "IRQ/status"]),
        ("INFO_EXCH", ["INT_STATE", "addr / len"]),
        ("CPU 读", ["payload", "XDMA BAR"]),
    ]
    for x, (title, lines) in zip(x_positions, blocks):
        box(d, (x, y, x + 330, y + 190), title, lines, "#F8FAFC", "#059669")
    for i in range(len(x_positions) - 1):
        arrow(d, (x_positions[i] + 330, y + 95), (x_positions[i + 1], y + 95), "#059669", width=7)
    img.save(path)
    return path


def draw_timing(path_name: str, title: str, signals: list[tuple[str, list[str]]], notes: list[str]) -> Path:
    path = ASSET_DIR / path_name
    steps = max(len(v) for _, v in signals)
    width = 2400
    left = 570
    right = 70
    top = 78
    step_w = int((width - left - right) / steps)
    row_h = 132
    height = top + row_h * len(signals) + 62
    img = Image.new("RGB", (width, height), "white")
    d = ImageDraw.Draw(img)
    for i in range(steps + 1):
        x = left + i * step_w
        d.line([(x, top - 20), (x, top + row_h * len(signals) - 16)], fill="#E5E7EB", width=2)

    for row, (name, values) in enumerate(signals):
        y = top + row * row_h
        d.line([(left, y + row_h - 10), (width - right, y + row_h - 10)], fill="#F1F5F9", width=2)
        d.text((34, y + 34), name, font=font(50, True), fill="#0F172A")
        base = y + 88
        high = y + 26
        prev_level = None
        prev_x = left
        for i in range(steps):
            value = values[i] if i < len(values) else values[-1]
            x0 = left + i * step_w
            x1 = x0 + step_w
            if value in ("0", "1"):
                level = high if value == "1" else base
                if prev_level is not None and prev_level != level:
                    d.line([(x0, prev_level), (x0, level)], fill="#2563EB", width=8)
                d.line([(x0, level), (x1, level)], fill="#2563EB", width=8)
                prev_level = level
                prev_x = x1
            elif value == "P":
                d.line([(x0, base), (x0 + step_w * 0.18, base), (x0 + step_w * 0.18, high), (x0 + step_w * 0.82, high), (x0 + step_w * 0.82, base), (x1, base)], fill="#2563EB", width=8)
                prev_level = base
                prev_x = x1
            elif value == "CLK":
                d.line([(x0, base), (x0 + step_w * 0.48, base), (x0 + step_w * 0.48, high), (x1, high)], fill="#334155", width=8)
                prev_level = None
                prev_x = x1
            elif value == "-":
                d.line([(x0, base), (x1, base)], fill="#CBD5E1", width=6)
                prev_level = base
                prev_x = x1
            elif value == "...":
                d.line([(x0, base), (x1, base)], fill="#94A3B8", width=6)
                ellipsis_font = font(58, True)
                tw, th = text_size(d, value, ellipsis_font)
                d.text((x0 + step_w / 2 - tw / 2, y + 57 - th / 2), value, font=ellipsis_font, fill="#475569")
                prev_level = None
                prev_x = x1
            else:
                d.rounded_rectangle((x0 + 12, y + 20, x1 - 12, y + 92), radius=10, fill="#EFF6FF", outline="#2563EB", width=4)
                value_font = font(54, True)
                tw, th = text_size(d, value, value_font)
                d.text((x0 + step_w / 2 - tw / 2, y + 57 - th / 2), value, font=value_font, fill="#0F172A")
                prev_level = None
                prev_x = x1
        if prev_level is not None:
            d.line([(prev_x, prev_level), (prev_x + 1, prev_level)], fill="#2563EB", width=8)
    img.save(path)
    return path


def create_assets() -> dict[str, Path]:
    return {
        "original": draw_original_structure(),
        "final": draw_final_structure(),
        "adapter": draw_adapter_internal(),
        "flow": draw_bidirectional_flow(),
        "timing_tx_start": draw_timing(
            "timing_01_tx_start.png",
            "时序图 1：INFO_EXCH -> adapter 的 TX 启动",
            [
                ("clk", ["CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK"]),
                ("CPU_WR_DONE[0]", ["0", "1", "1", "1", "0", "0", "0", "0"]),
                ("RD_START", ["0", "P", "0", "0", "0", "0", "0", "0"]),
                ("addr/len", ["idle", "A/L", "A/L", "A/L", "A/L", "A/L", "A/L", "idle"]),
                ("tx_active", ["0", "1", "1", "1", "1", "1", "0", "0"]),
                ("CPU_WR_DONE_resp", ["0", "1", "1", "1", "1", "1", "0", "0"]),
            ],
            [
                "INFO_EXCH 在 CPU_WR_DONE[0] 上升沿产生 r_RD_START 单周期脉冲。",
                "adapter 在 RD_START 有效时锁存 CPU_FPGA_START_ADDR 和 CPU_FPGA_LEN，并检查长度是否 512B 对齐。",
                "当前代码在启动后置 CPU_WR_DONE_resp，TX 完成后清零。",
            ],
        ),
        "timing_fdma_read": draw_timing(
            "timing_02_fdma_read.png",
            "时序图 2：adapter FDMA read 与 rvalid stall",
            [
                ("clk", ["CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK"]),
                ("fdma_rareq", ["0", "P", "0", "0", "0", "0", "0", "0", "0"]),
                ("fdma_rbusy", ["0", "1", "1", "1", "1", "1", "1", "0", "0"]),
                ("fdma_raddr", ["idle", "base", "base", "base", "base", "base+", "base+", "idle", "idle"]),
                ("fdma_rsize", ["idle", "64", "64", "64", "64", "64", "64", "idle", "idle"]),
                ("fdma_rvalid", ["0", "0", "1", "1", "0", "1", "1", "0", "0"]),
                ("fdma_rready", ["0", "1", "1", "1", "1", "1", "1", "0", "0"]),
            ],
            [
                "fdma_rsize=64 表示 64 个 64-bit beat，即 512B。",
                "当 fdma_rvalid 暂停时，TX 侧计数和输出必须只在 rvalid && rready 成立时推进。",
                "fdma_raddr 由 adapter 将 32-bit 软件地址显式扩展为 64-bit 后输出。",
            ],
        ),
        "timing_tx_stream": draw_timing(
            "timing_03_tx_stream.png",
            "时序图 3：FDMA2AURORA 桥 TX 帧边界",
            [
                ("clk", ["CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK"]),
                ("tx_valid", ["0", "1", "1", "1", "1", "...", "1", "0"]),
                ("SOF", ["0", "1", "0", "0", "0", "...", "0", "0"]),
                ("data", ["idle", "D0", "D1", "D2", "D3", "...", "D63", "idle"]),
                ("EOF", ["0", "0", "0", "0", "0", "...", "1", "0"]),
            ],
            [
                "单帧为 64 个有效 beat；首拍 SOF=1，末拍 EOF=1。",
                "该帧边界属于完整 FDMA2AURORA 异步桥内部或桥侧边界，不再经过 DATA_CDC。",
            ],
        ),
        "timing_rx_write": draw_timing(
            "timing_04_rx_write_irq.png",
            "时序图 4：RX stream -> FDMA write -> 中断",
            [
                ("clk", ["CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK"]),
                ("rx_valid", ["0", "1", "1", "1", "...", "1", "0", "0", "0"]),
                ("SOF/EOF", ["0", "SOF", "0", "0", "...", "EOF", "0", "0", "0"]),
                ("fdma_wareq", ["0", "0", "P", "0", "0", "0", "0", "0", "0"]),
                ("fdma_wvalid", ["0", "0", "1", "1", "0", "1", "1", "0", "0"]),
                ("fdma_wready", ["0", "0", "1", "1", "1", "1", "1", "0", "0"]),
                ("INT_STATE_W", ["0", "0", "0", "0", "0", "0", "P", "1", "1"]),
                ("FPGA_CPU_irq_req", ["0", "0", "0", "0", "0", "0", "1", "1", "1"]),
            ],
            [
                "RX 数据先进入 bridge RX FIFO，再由 FDMA write 写入 payload window。",
                "写完一个 512B 可交付单位后，adapter 更新 FPGA_CPU_START_ADDR/FPGA_CPU_LEN，并置位中断状态。",
            ],
        ),
        "timing_irq_clear": draw_timing(
            "timing_05_irq_clear.png",
            "时序图 5：RX 中断清除",
            [
                ("clk", ["CLK", "CLK", "CLK", "CLK", "CLK", "CLK"]),
                ("CPU read 0x0010", ["0", "0", "P", "0", "0", "0"]),
                ("INT_STATE_R", ["0", "0", "P", "0", "0", "0"]),
                ("CLEAR_INTER_R", ["0", "0", "P", "0", "0", "0"]),
                ("INT_STATE_W", ["1", "1", "0", "0", "0", "0"]),
                ("FPGA_CPU_irq_req", ["1", "1", "0", "0", "0", "0"]),
            ],
            [
                "INFO_EXCH 读 0x0010 时产生 INT_STATE_R 和 CLEAR_INTER_R。",
                "adapter 看到 int_state_clear 或 clear_inter 后清 fpga_cpu_irq_req 和 int_state_w。",
            ],
        ),
        "timing_cdc": draw_timing(
            "timing_06_bridge_internal_fifo_cdc.png",
            "时序图 6：完整 FDMA2AURORA 异步桥内部 FIFO CDC",
            [
                ("aurora_clk", ["CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK"]),
                ("fifo_wr/data", ["D0", "D1", "D2", "-", "-", "D3", "D4", "-", "-"]),
                ("FIFO empty", ["1", "0", "0", "0", "0", "0", "0", "0", "1"]),
                ("fdma_clk", ["CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK"]),
                ("fifo_rd", ["0", "1", "1", "1", "0", "1", "1", "0", "0"]),
                ("fdma_valid/data", ["-", "D0", "D1", "D2", "-", "D3", "D4", "-", "-"]),
            ],
            [
                "跨时钟 FIFO 位于完整 FDMA2AURORA 异步桥内部，不再使用 RTDS_test 的 DATA_CDC。",
                "跨域后 valid/data 有 FIFO 延迟，adapter 和 PCIe.v 不应假设同周期穿透。",
            ],
        ),
        "timing_link": draw_timing(
            "timing_07_link_enable.png",
            "时序图 7：link_enable 与 channel_up 建议",
            [
                ("clk", ["CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK", "CLK"]),
                ("user_lnk_up_int", ["0", "1", "1", "1", "1", "1", "1", "1"]),
                ("bridge_channel_up", ["0", "0", "0", "1", "1", "0", "0", "1"]),
                ("bridge_lane_up", ["0", "0", "1", "1", "1", "1", "1", "1"]),
                ("current link_enable", ["0", "1", "1", "1", "1", "1", "1", "1"]),
                ("recommended enable", ["0", "0", "0", "1", "1", "0", "0", "1"]),
            ],
            [
                "当前 adapter 的 link_enable 暂接 user_lnk_up_int，只代表 PCIe 链路可用。",
                "最终建议使用 pcie_link_up && bridge_channel_up && bridge_lane_up。",
            ],
        ),
    }


def set_run_font(run, name: str = FONT_CN, size: float | None = None, bold: bool | None = None, color: str | None = None) -> None:
    run.font.name = name
    if run._element.rPr is None:
        run._element.get_or_add_rPr()
    run._element.rPr.rFonts.set(qn("w:ascii"), FONT_EN if name == FONT_CN else name)
    run._element.rPr.rFonts.set(qn("w:hAnsi"), FONT_EN if name == FONT_CN else name)
    run._element.rPr.rFonts.set(qn("w:eastAsia"), name)
    if size is not None:
        run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold
    if color:
        run.font.color.rgb = RGBColor.from_string(color)


def clear_cell(cell) -> None:
    for p in cell.paragraphs:
        p.clear()


def set_cell_text(cell, text: str, size: float = 10.5, bold: bool = False, align=WD_ALIGN_PARAGRAPH.CENTER) -> None:
    clear_cell(cell)
    p = cell.paragraphs[0]
    p.alignment = align
    p.paragraph_format.line_spacing = 1.12
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(0)
    for i, part in enumerate(text.split("\n")):
        if i:
            p.add_run().add_break()
        r = p.add_run(part)
        set_run_font(r, size=size, bold=bold)


def set_cell_shading(cell, fill: str) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), fill)
    tc_pr.append(shd)


def set_cell_border(cell, color: str = BORDER, size: str = "6") -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = tc_pr.first_child_found_in("w:tcBorders")
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right"):
        tag = "w:" + edge
        el = borders.find(qn(tag))
        if el is None:
            el = OxmlElement(tag)
            borders.append(el)
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), size)
        el.set(qn("w:space"), "0")
        el.set(qn("w:color"), color)


def fix_table_geometry(table, widths: list[float]) -> None:
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    table.autofit = False
    for row in table.rows:
        for idx, width in enumerate(widths):
            row.cells[idx].width = Inches(width)
            row.cells[idx].vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            set_cell_border(row.cells[idx])


def normalize_paragraph(p, size: float = 10.5, first_line_indent: bool = True) -> None:
    p.paragraph_format.line_spacing = 1.45
    p.paragraph_format.space_after = Pt(6)
    if first_line_indent:
        p.paragraph_format.first_line_indent = Pt(21)
    for run in p.runs:
        set_run_font(run, size=size)


def add_para(doc: Document, text: str, size: float = 10.5, bold_prefix: str | None = None) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    if bold_prefix and text.startswith(bold_prefix):
        r = p.add_run(bold_prefix)
        set_run_font(r, size=size, bold=True)
        r = p.add_run(text[len(bold_prefix):])
        set_run_font(r, size=size)
    else:
        r = p.add_run(text)
        set_run_font(r, size=size)
    normalize_paragraph(p, size=size)


def add_bullets(doc: Document, items: list[str]) -> None:
    for item in items:
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Pt(18)
        p.paragraph_format.first_line_indent = Pt(-9)
        p.paragraph_format.line_spacing = 1.35
        p.paragraph_format.space_after = Pt(4)
        r = p.add_run("• ")
        set_run_font(r, size=10.5)
        r = p.add_run(item)
        set_run_font(r, size=10.5)


def set_outline_level(paragraph, level: int) -> None:
    p_pr = paragraph._p.get_or_add_pPr()
    outline = p_pr.find(qn("w:outlineLvl"))
    if outline is None:
        outline = OxmlElement("w:outlineLvl")
        p_pr.append(outline)
    outline.set(qn("w:val"), str(level))


def add_h1(doc: Document, text: str) -> None:
    text = re.sub(r"^\d+\s+", "", text)
    p = doc.add_paragraph(style="Heading 1")
    set_outline_level(p, 0)
    p.paragraph_format.space_before = Pt(22)
    p.paragraph_format.space_after = Pt(14)
    r = p.add_run(text)
    set_run_font(r, size=15, bold=True)


def add_h2(doc: Document, text: str) -> None:
    text = re.sub(r"^\d+\.\d+\s+", "", text)
    p = doc.add_paragraph(style="Heading 2")
    set_outline_level(p, 1)
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(8)
    r = p.add_run(text)
    set_run_font(r, size=12, bold=True)


def add_caption(doc: Document, text: str) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(8)
    r = p.add_run(text)
    set_run_font(r, size=10.5, bold=True)


def add_image(doc: Document, path: Path, caption: str, width: float = 6.45) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(2)
    run = p.add_run()
    run.add_picture(str(path), width=Inches(width))
    add_caption(doc, caption)


def add_figure_notes(doc: Document, notes: list[str]) -> None:
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(3)
    r = p.add_run("说明：")
    set_run_font(r, size=10.5, bold=True)
    for note in notes:
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Pt(18)
        p.paragraph_format.first_line_indent = Pt(-9)
        p.paragraph_format.line_spacing = 1.25
        p.paragraph_format.space_after = Pt(2)
        r = p.add_run("• ")
        set_run_font(r, size=9.8)
        r = p.add_run(note)
        set_run_font(r, size=9.8)


def add_table(doc: Document, headers: list[str], rows: list[list[str]], widths: list[float]) -> None:
    table = doc.add_table(rows=1, cols=len(headers))
    fix_table_geometry(table, widths)
    for i, header in enumerate(headers):
        set_cell_shading(table.rows[0].cells[i], LIGHT_BLUE)
        set_cell_text(table.rows[0].cells[i], header, size=10.5, bold=True)
    for row in rows:
        cells = table.add_row().cells
        for i, value in enumerate(row):
            set_cell_text(cells[i], value, size=9.8, align=WD_ALIGN_PARAGRAPH.LEFT)
    doc.add_paragraph().paragraph_format.space_after = Pt(2)


def trim_template(doc: Document) -> None:
    body = doc._body._element
    children = list(body)
    for idx, el in enumerate(children):
        if idx >= 38 and el.tag != qn("w:sectPr"):
            body.remove(el)


def update_front_matter(doc: Document, total_pages: int | None) -> None:
    for p in doc.paragraphs:
        if "fdma_aurora_brg IP总体设计与验证概述" in p.text:
            p.clear()
            r = p.add_run("pcie_fdma_aurora_brg_adapter 总体设计与验证方案")
            set_run_font(r, size=18, bold=True)
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            break
    for p in doc.paragraphs:
        if p.text.strip() == "Revision Record 修订记录":
            set_outline_level(p, 0)
            break

    page_text = "Total XX pages  共 XX 页" if total_pages is None else f"Total {total_pages} pages  共 {total_pages} 页"
    cover = doc.tables[0]
    set_cell_text(cover.rows[1].cells[0], "RTDS_test / PCIe-FDMA-Aurora", size=11)
    set_cell_text(cover.rows[3].cells[0], "V1.0", size=11)
    set_cell_text(cover.rows[2].cells[1], page_text, size=11)
    set_cell_text(cover.rows[3].cells[1], page_text, size=11)

    sign = doc.tables[1]
    set_cell_text(sign.rows[0].cells[3], "\n2026-07-09", size=10.5)

    rev = doc.tables[2]
    rows = [
        ["1.0", "完成 RTDS_test PCIe-FDMA-Aurora Bridge 设计方案文档，明确 adapter 插入位置、PCIe.v 连接方式、BD 维持策略和验证路径。", "", "2026-07-09"],
        ["1.1", "按完整 FDMA2AURORA 异步桥已包含 Aurora 与 FIFO CDC 的口径重设计，删除最终主路径中的 DATA_CDC，并重绘全部结构图和时序图。", "", "2026-07-09"],
    ]
    for r_idx, row in enumerate(rows, start=1):
        for c_idx, value in enumerate(row):
            set_cell_text(rev.rows[r_idx].cells[c_idx], value, size=9.5, align=WD_ALIGN_PARAGRAPH.LEFT if c_idx == 1 else WD_ALIGN_PARAGRAPH.CENTER)


def add_toc_field_begin(doc: Document) -> None:
    p = doc.add_paragraph()
    r = p.add_run()
    fld_begin = OxmlElement("w:fldChar")
    fld_begin.set(qn("w:fldCharType"), "begin")
    fld_begin.set(qn("w:dirty"), "true")
    r._r.append(fld_begin)

    r = p.add_run()
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = 'TOC \\o "1-2" \\h \\z \\u'
    r._r.append(instr)

    r = p.add_run()
    fld_separate = OxmlElement("w:fldChar")
    fld_separate.set(qn("w:fldCharType"), "separate")
    r._r.append(fld_separate)


def add_toc_field_end(doc: Document) -> None:
    p = doc.add_paragraph()
    r = p.add_run()
    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")
    r._r.append(fld_end)


def add_toc(doc: Document, page_map: dict[str, int] | None) -> None:
    p = doc.add_paragraph("目录", style="缺省文本" if "缺省文本" in [s.name for s in doc.styles] else None)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_outline_level(p, 0)
    for run in p.runs:
        set_run_font(run, size=12, bold=True)
    add_toc_field_begin(doc)
    for level, label, key in TOC_ENTRIES:
        p = doc.add_paragraph(style="toc 1" if level == 1 else "toc 2")
        p.paragraph_format.line_spacing = 1.0
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        page = "?" if page_map is None else str(page_map.get(key, "?"))
        left = label if level == 1 else "    " + label
        visual_len = sum(2 if ord(ch) > 127 else 1 for ch in left)
        dots = "." * max(6, 78 - visual_len)
        p.add_run(left + dots + page)
        for run in p.runs:
            set_run_font(run, size=9.2)
    add_toc_field_end(doc)
    p = doc.add_paragraph()
    p.add_run().add_break(WD_BREAK.PAGE)


def add_content(doc: Document, assets: dict[str, Path]) -> None:
    add_h1(doc, "1 工程背景与当前边界")
    add_h2(doc, "1.1 设计依据与资料来源")
    add_para(doc, "本文面向 RTDS_test 工程中 PCIe、FDMA、Aurora Bridge 的真实集成方案说明，重点阅读目录为 E:\\PCIE-CPU\\RTDS_test\\RTDS_test.srcs\\sources_1\\new。设计判断以 2026-07-08_08-56_工程评估.md 为主线，并交叉参考 rtds_top_fdma_aurora_brg_real_integration.md 与 fdma_aurora_brg_added_files_theory_design_registers.md。")
    add_para(doc, "当前工程已经存在 pcie_fdma_aurora_brg_adapter.v 和修改后的 PCIe.v；本文按“完整 FDMA2AURORA 异步桥已经包含 Aurora 与 FIFO 跨时钟域转换”的口径描述最终结构，同时说明当前遗留 debug 模块与最终产品主链路的取舍。")
    add_h2(doc, "1.2 当前 RTL 边界")
    add_para(doc, "TOP.v 当前仍是 Vivado synthesis top，负责板级时钟、PCIe 管脚、PCIe 子系统、LED 和温度读取；PCIe.v 当前已例化 pcie_fdma_aurora_brg_adapter，并继续连接 design_1_wrapper 内的 XDMA、CONV_DMA、INFO_EXCH 和 BRAM 数据窗口。")
    add_para(doc, "DATA_CDC 当前只解释为遗留 debug/占位路径：Aurora_frame_gen 产生测试数据，PCIe->Aurora 方向输出也未形成真实 Aurora 闭环。由于完整 FDMA2AURORA 异步桥已经包含 Aurora 与 FIFO CDC，最终主路径应删除 DATA_CDC，避免重复跨域、重复协议边界和职责误导。")

    add_h1(doc, "2 原结构与最终结构对比")
    add_h2(doc, "2.1 adapter 插入前结构")
    add_image(doc, assets["original"], "图1  adapter 插入前的当前 RTDS_test 数据路径")
    add_para(doc, "原结构的核心问题不是 PCIe 或 BD 完全不可用，而是 Aurora 侧仍处在 debug/占位状态。Aurora->PCIe 方向由 Aurora_frame_gen 产生测试帧；PCIe->Aurora 方向的 CDC 输出没有继续接到真实 Aurora 发送路径。该结构只能用于局部烟测和 ILA 观察，最终集成时应整体退出主路径。")
    add_h2(doc, "2.2 adapter 插入后结构")
    add_image(doc, assets["final"], "图2  pcie_fdma_aurora_brg_adapter 的最终插入位置")
    add_para(doc, "最终结构中，adapter 插在 PCIe.v 内部，位于 design_1_wrapper/CONV_DMA 的 FDMA 边界与完整 FDMA2AURORA 异步桥的控制/FDMA 边界之间。完整桥负责 FDMA-to-Aurora 数据桥、内部 FIFO CDC、Aurora IP/GT 和 channel_up/lane_up 状态，因此最终主路径不再经过 DATA_CDC。")
    add_h2(doc, "2.3 adapter 与完整异步桥的边界")
    add_para(doc, "需要特别区分：pcie_fdma_aurora_brg_adapter 在最终方案中不是重复实现 Aurora bridge TX/RX 的模块，而是保留 RTDS_test 原 PCIe 软件协议的适配层。它负责 INFO_EXCH 控制语义、地址/长度检查、start/done、IRQ/status 和 BD FDMA 端口适配。")
    add_para(doc, "完整 FDMA2AURORA 异步桥负责数据面重活：FDMA-to-Aurora 转换、跨时钟 FIFO、Aurora IP/GT、真实收发链路和 channel_up/lane_up。这样边界清楚，PCIe 工程不用再维护另一套 DATA_CDC 或 debug 66-bit stream 主链路。")

    add_h1(doc, "3 pcie_fdma_aurora_brg_adapter 设计")
    add_h2(doc, "3.1 内部职责")
    add_image(doc, assets["adapter"], "图3  pcie_fdma_aurora_brg_adapter 内部职责分解")
    add_para(doc, "adapter 的设计目标是保留原 RTDS_test PCIe 软件协议，并把 INFO_EXCH/CONV_DMA 暴露出的控制与 FDMA 语义送入完整 FDMA2AURORA 异步桥。软件仍通过 XDMA/INFO_EXCH 写起始地址、长度和 CPU_WR_DONE；adapter 负责锁存、检查、启动、完成反馈、中断和状态汇总。")
    doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)
    add_h2(doc, "3.2 关键接口与状态")
    add_para(doc, "adapter 对外接口可以分成两组：第一组是 INFO_EXCH 控制、IRQ 和状态边界，第二组是与 design_1_wrapper/CONV_DMA 以及完整 FDMA2AURORA 异步桥之间的 FDMA/控制边界。当前代码里存在的 66-bit debug stream 边界只作为遗留实现现状，不作为最终主路径。")
    add_table(
        doc,
        ["数据/控制接口", "方向", "功能说明"],
        [
            ["bridge_rx_done/status", "输入", "完整 FDMA2AURORA 异步桥返回的 RX 完成、FIFO 和错误状态。"],
            ["bridge_tx_start/control", "输出", "adapter 根据 INFO_EXCH start、地址和长度触发完整异步桥 TX 方向传输。"],
            ["rd_start / CPU_FPGA_*", "输入", "INFO_EXCH 发出的 TX 启动脉冲、起始地址和长度。长度必须 512B 对齐。"],
            ["CPU_WR_DONE_resp", "输出", "adapter 启动 TX 后反馈给 INFO_EXCH，TX 完成后清除。"],
        ],
        [1.75, 0.60, 3.95],
    )
    add_table(
        doc,
        ["状态/FDMA接口", "方向", "功能说明"],
        [
            ["FPGA_CPU_START_ADDR / FPGA_CPU_LEN", "输出", "RX 写入完成后提供给 CPU 的可读 payload 地址和长度。"],
            ["INT_STATE_W / FPGA_CPU_irq_req", "输出", "RX 完成后置位中断状态，CPU 读 INT_STATE 后清除。"],
            ["fdma_r* / fdma_w*", "双向", "连接 design_1_wrapper/CONV_DMA 的 FDMA 读写接口，size 固定为 64 beat。"],
            ["rx_overflow_sticky / length_error_sticky 等", "输出", "用于 ILA 或后续寄存器的错误锁存状态。"],
        ],
        [1.75, 0.60, 3.95],
    )
    add_h2(doc, "3.3 CPU 到 Aurora 数据流")
    add_image(doc, assets["flow"], "图4  CPU->Aurora 与 Aurora->CPU 双向数据流")
    add_para(doc, "CPU->Aurora 方向中，CPU 先通过 XDMA 写 payload buffer，再写 CPU_FPGA_START_ADDR、CPU_FPGA_LEN 和 CPU_WR_DONE。INFO_EXCH 将 CPU_WR_DONE 上升沿转换成 RD_START 单周期脉冲。adapter 锁存地址和长度，完成 512B 对齐检查后触发完整 FDMA2AURORA 异步桥，由完整桥完成 FDMA read、内部 FIFO 跨域和 Aurora TX。")
    add_h2(doc, "3.4 Aurora 到 CPU 数据流")
    add_para(doc, "Aurora->CPU 方向中，完整 FDMA2AURORA 异步桥接收 Aurora 链路数据，并在桥内部完成 Aurora RX、FIFO CDC 和 FDMA write，把一帧 512B 写入 payload window。写完后 adapter 根据桥侧 done/status 更新 FPGA_CPU_START_ADDR、FPGA_CPU_LEN，并置 INT_STATE_W 和 FPGA_CPU_irq_req。")
    add_para(doc, "RX 方向的关键风险是 Aurora 侧通常不适合被下游 full 直接反压。因此风险控制应放在完整桥内部 FIFO 深度、almost_full/full、overflow sticky、远端限速和软件及时读取策略上，而不是额外串接 DATA_CDC。")

    add_h1(doc, "4 PCIe.v 设计方案")
    add_h2(doc, "4.1 保留边界")
    add_para(doc, "PCIe.v 应继续保持 PCIe MGT、PCIe refclk/reset、user_lnk_up、FPGA_TEMP_W、i_sys_clk/i_sys_rst 等板级边界。最终版本应删除或旁路当前 Aurora/debug 66-bit 输入输出，把 PCIe.v 内部 adapter 直接接到完整 FDMA2AURORA 异步桥的控制/FDMA 边界。")
    add_h2(doc, "4.2 与 design_1_wrapper 的连接")
    add_table(
        doc,
        ["PCIe.v 连接项", "当前连接对象", "设计含义"],
        [
            ["fdma_raddr/fdma_rareq/fdma_rsize/fdma_rdata/fdma_rvalid/fdma_rready", "design_1_wrapper fdma_r*_0", "CPU->Aurora 时从 payload window 读取 512B frame。"],
            ["fdma_waddr/fdma_wareq/fdma_wsize/fdma_wdata/fdma_wvalid/fdma_wready", "design_1_wrapper fdma_w*_0", "Aurora->CPU 时写入 payload window。"],
            ["RD_START / CPU_FPGA_START_ADDR / CPU_FPGA_LEN", "INFO_EXCH 输出", "软件 TX start、地址和长度配置。"],
            ["INT_STATE_W / FPGA_CPU_irq_req", "INFO_EXCH / XDMA IRQ", "RX 完成后通知 CPU。"],
            ["CLEAR_INTER_R / INT_STATE_R", "INFO_EXCH 清除脉冲", "CPU 读 INT_STATE 后清中断。"],
            ["ila_FDMA probes", "ILA IP", "观察 FDMA 地址、请求、数据、size 和 adapter 状态。"],
        ],
        [1.75, 1.75, 2.80],
    )
    add_h2(doc, "4.3 link_enable 当前方案与最终建议")
    add_para(doc, "当前 PCIe.v 将 adapter.link_enable 暂接 user_lnk_up_int。这在工程未接完整 FDMA2AURORA 桥状态时可以用于语法和 PCIe 侧 smoke，但它只说明主机 PCIe 链路可用，不代表 Aurora 链路可发送。最终建议将 link_enable 改成 pcie_link_up && bridge_channel_up && bridge_lane_up，并按桥侧状态所属时钟域完成同步。")

    add_h1(doc, "5 主模块关键接口时序")
    add_h2(doc, "5.1 INFO_EXCH 到 adapter 的 TX 启动")
    add_image(doc, assets["timing_tx_start"], "图5  INFO_EXCH 到 adapter 的 TX 启动时序")
    add_figure_notes(doc, [
        "INFO_EXCH 在 CPU_WR_DONE[0] 上升沿产生 r_RD_START 单周期脉冲。",
        "adapter 在 RD_START 有效时锁存 CPU_FPGA_START_ADDR 和 CPU_FPGA_LEN，并检查长度是否 512B 对齐。",
        "当前代码在启动后置 CPU_WR_DONE_resp，TX 完成后清零。",
    ])
    add_h2(doc, "5.2 FDMA read 与 rvalid stall")
    add_image(doc, assets["timing_fdma_read"], "图6  adapter FDMA read 与 rvalid stall 时序")
    add_figure_notes(doc, [
        "fdma_rsize=64 表示 64 个 64-bit beat，即 512B。",
        "当 fdma_rvalid 暂停时，TX 侧计数和输出只在 rvalid && rready 成立时推进。",
        "fdma_raddr 由 adapter 将 32-bit 软件地址显式扩展为 64-bit 后输出。",
    ])
    add_h2(doc, "5.3 完整桥 TX 帧边界")
    add_image(doc, assets["timing_tx_stream"], "图7  完整 FDMA2AURORA 桥 TX 帧边界时序")
    add_figure_notes(doc, [
        "单帧为 64 个有效 beat；首拍 SOF=1，末拍 EOF=1。",
        "该帧边界属于完整 FDMA2AURORA 异步桥内部或桥侧边界，不再经过 DATA_CDC。",
    ])
    add_h2(doc, "5.4 完整桥 RX 到 FDMA write 与中断")
    add_image(doc, assets["timing_rx_write"], "图8  完整 FDMA2AURORA 桥 RX 到 FDMA write 与中断置位时序")
    add_figure_notes(doc, [
        "RX 数据先进入 bridge RX FIFO，再由 FDMA write 写入 payload window。",
        "写完一个 512B 可交付单位后，adapter 更新 FPGA_CPU_START_ADDR/FPGA_CPU_LEN，并置位中断状态。",
    ])
    add_h2(doc, "5.5 RX 中断清除")
    add_image(doc, assets["timing_irq_clear"], "图9  RX 中断清除时序")
    add_figure_notes(doc, [
        "INFO_EXCH 读 0x0010 时产生 INT_STATE_R 和 CLEAR_INTER_R。",
        "adapter 看到 int_state_clear 或 clear_inter 后清 fpga_cpu_irq_req 和 int_state_w。",
    ])
    add_h2(doc, "5.6 完整异步桥内部 FIFO CDC")
    add_image(doc, assets["timing_cdc"], "图10  完整 FDMA2AURORA 异步桥内部 FIFO CDC 时序")
    add_figure_notes(doc, [
        "该跨时钟关系位于完整 FDMA2AURORA 异步桥内部，不再由 RTDS_test 的 DATA_CDC 承担。",
        "跨域后 valid/data 有 FIFO 延迟，adapter 和 PCIe.v 不应假设同周期穿透。",
    ])
    add_h2(doc, "5.7 link_enable 与 channel_up")
    add_image(doc, assets["timing_link"], "图11  link_enable 与完整桥 channel_up/lane_up 建议时序")
    add_figure_notes(doc, [
        "当前 adapter 的 link_enable 暂接 user_lnk_up_int，只代表 PCIe 链路可用。",
        "最终建议使用 pcie_link_up && bridge_channel_up && bridge_lane_up。",
    ])

    add_h1(doc, "6 剩余不变模块设计说明")
    add_table(
        doc,
        ["模块", "保持/改动策略", "说明"],
        [
            ["TOP.v", "保持顶层并删主路径占位", "继续实例化 CLK_GEN、PCIe、LED、TEMP_RD；最终主路径不再实例化 DATA_CDC。"],
            ["DATA_CDC.v", "最终删除/仅留旧调试说明", "当前使用 Aurora_frame_gen 和两个方向 CDC；完整 FDMA2AURORA 桥已含 Aurora+FIFO CDC，因此产品主路径删除。"],
            ["Aurora_PCIe_cdc.v", "最终删除", "其跨域功能由完整 FDMA2AURORA 异步桥内部 FIFO CDC 承担。"],
            ["PCIe_Aurora_cdc.v", "最终删除", "其跨域功能由完整 FDMA2AURORA 异步桥内部 FIFO CDC 承担。"],
            ["CONV_DMA.v", "保持", "继续承担 FDMA 到 AXI4 burst 转换，adapter/完整桥需保证 size=64 beat。"],
            ["INFO_EXCH.v", "第一版保持", "保留 0x0000-0x0028 原寄存器语义；扩展状态后续再做。"],
            ["CLK_GEN.v", "保持", "继续输出 250 MHz、100 MHz 和 sys_rst。"],
            ["LED.v / TEMP_RD.v", "保持", "板级心跳和温度读数，不进入本次数据路径改造。"],
            ["Aurora_frame_gen.v", "最终不进主路径", "可作为单独 testbench 或 bring-up pattern 源，不作为 TOP 默认数据源。"],
        ],
        [1.25, 1.15, 3.90],
    )

    add_h1(doc, "7 BD 与扩展状态寄存器策略")
    add_para(doc, "第一版建议维持现有 BD，不同步新增扩展状态寄存器。原因是 INFO_EXCH 位于 block design 内，新增 AXI-Lite slave 或扩展端口会牵动 BD 地址分配、wrapper 端口、软件地址表和回归验证。当前 adapter 已把 sticky/status 暴露给 ILA，足以支撑上板前的 bring-up 和定位。")
    add_table(
        doc,
        ["方案", "工作量", "收益", "风险/代价"],
        [
            ["维持 BD，仅 ILA 观察 sticky/status", "0-1 人日", "最快进入综合、仿真和上板前检查。", "软件无法直接读取 overflow/timeout/link 状态，长期联调可观测性弱。"],
            ["在 INFO_EXCH 内扩展简单状态寄存器", "3-6 人日", "软件可读基本状态，地址空间集中。", "INFO_EXCH 会变大，需谨慎保持 0x0000-0x0028 兼容。"],
            ["新增独立 AXI-Lite 状态寄存器 slave", "5-9 人日", "边界清晰，支持 IRQ_ENABLE、W1C、计数器和自测。", "需要修改 BD、地址分配、wrapper、驱动/脚本和更多验证。"],
            ["先维持 BD，后续补寄存器", "后续约 2-4 人日；若未预留状态端口约 4-7 人日", "当前进度最快，后续可按问题再补。", "需在 adapter 中保留清晰状态信号，避免后续拆线返工。"],
        ],
        [1.35, 1.05, 1.80, 2.10],
    )
    add_para(doc, "因此建议当前文档方案明确：先维持 BD，保留原寄存器表；后续若需要软件长期运行可观测性，再从 0x0030 之后增加 AURORA_STATUS、FDMA_STATUS、FIFO_STATUS、IRQ_ENABLE、IRQ_STATUS 和 ERROR_CLEAR 等寄存器，不覆盖原 0x0000-0x0028。")

    add_h1(doc, "8 验证方案与风险清单")
    add_table(
        doc,
        ["验证层级", "目标", "关键检查"],
        [
            ["bridge 单元回归", "确认完整 FDMA2AURORA 异步桥原行为未破坏。", "TX/RX、stall、地址回绕、FIFO sticky、Aurora link。"],
            ["adapter 功能 TB", "证明 INFO_EXCH 语义、FDMA size、frame 边界正确。", "TX/RX 单帧、多帧、非 512B 对齐、IRQ/clear、rvalid/wready stall。"],
            ["PCIe.v 级 mock TB", "证明 PCIe.v 嵌入点与 design_1_wrapper 端口语义匹配。", "RD_START、CPU_WR_DONE_resp、FPGA_CPU_irq_req、64-bit 地址、ILA probe。"],
            ["Vivado 综合实现", "证明工程收录、IP 状态和时序可通过。", "TOP 为 synthesis top、XPM_CDC/XPM_FIFO、Vivado 2020.2 IP locked 状态处理。"],
            ["上板 bring-up", "证明 PCIe、Aurora、FDMA 和软件闭环可运行。", "PCIe 枚举、BAR 读写、TX 单帧、RX 单帧、连续帧、异常 sticky。"],
        ],
        [1.25, 1.85, 3.20],
    )
    add_table(
        doc,
        ["风险", "影响", "建议措施"],
        [
            ["完整桥状态未接入 adapter", "Aurora 未 up 时 TX 仍可能启动。", "最终改为 PCIe link 与 bridge channel/lane up 相与。"],
            ["旧 66-bit debug 端口未删除", "容易让 DATA_CDC 被误接回主路径。", "最终 PCIe.v/TOP.v 清理旧 debug stream 边界，只保留必要 ILA/test hook。"],
            ["RX 方向不能可靠反压", "CPU 慢读或 FDMA stall 时可能 overflow。", "增加 FIFO 水位观测、overflow sticky、远端限速和软件读取策略。"],
            ["暂不加状态寄存器", "软件长期调试状态不足。", "当前用 ILA，上板稳定后补 0x0030 以后的扩展寄存器。"],
            ["Vivado IP 版本 locked", "综合/实现可能被 IP 状态阻塞。", "上板前固定 Vivado 版本策略或 regenerate IP 后重跑实现。"],
        ],
        [1.45, 1.95, 2.90],
    )


def build_docx(path: Path, assets: dict[str, Path], page_map: dict[str, int] | None = None, total_pages: int | None = None) -> None:
    doc = Document(str(TEMPLATE))
    trim_template(doc)
    update_front_matter(doc, total_pages)
    add_toc(doc, page_map)
    add_content(doc, assets)
    doc.save(path)


def render_docx_to_pdf(docx_path: Path, render_dir: Path) -> Path:
    if render_dir.exists():
        shutil.rmtree(render_dir)
    render_dir.mkdir(parents=True)
    work = Path(tempfile.mkdtemp(prefix="pcie_doc_render_", dir=str(render_dir.parent)))
    try:
        profile = work / "lo_profile"
        out = work / "out"
        profile.mkdir()
        out.mkdir()
        local_doc = work / "input.docx"
        shutil.copy2(docx_path, local_doc)
        cmd = [
            str(SOFFICE),
            "--headless",
            "--invisible",
            "--norestore",
            "--nolockcheck",
            f"-env:UserInstallation={profile.as_uri()}",
            "--convert-to",
            "pdf",
            "--outdir",
            str(out),
            str(local_doc),
        ]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=180)
        pdf = out / "input.pdf"
        if not pdf.exists() or pdf.stat().st_size == 0:
            raise RuntimeError(f"LibreOffice PDF conversion failed\nSTDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}")
        final_pdf = render_dir / (docx_path.stem + ".pdf")
        shutil.copy2(pdf, final_pdf)
        return final_pdf
    finally:
        shutil.rmtree(work, ignore_errors=True)


def extract_page_map(pdf_path: Path) -> tuple[int, dict[str, int]]:
    pdf = pdfium.PdfDocument(str(pdf_path))
    page_map: dict[str, int] = {"Revision Record 修订记录": 2, "目录": 3}
    for idx in range(len(pdf)):
        page = pdf[idx]
        text = page.get_textpage().get_text_range()
        for _, _, key in TOC_ENTRIES:
            if key in ("Revision Record 修订记录", "目录"):
                continue
            if key in text:
                page_map[key] = idx + 1
    return len(pdf), page_map


def render_pdf_to_pngs(pdf_path: Path, out_dir: Path) -> list[Path]:
    png_dir = out_dir / "pages"
    png_dir.mkdir(parents=True, exist_ok=True)
    for old in png_dir.glob("page-*.png"):
        old.unlink()
    pdf = pdfium.PdfDocument(str(pdf_path))
    paths: list[Path] = []
    for idx, page in enumerate(pdf):
        bitmap = page.render(scale=1.65)
        image = bitmap.to_pil()
        path = png_dir / f"page-{idx + 1:02d}.png"
        image.save(path)
        paths.append(path)
    return paths


def make_contact_sheets(pages: list[Path], out_dir: Path) -> list[Path]:
    sheets: list[Path] = []
    thumb_w, thumb_h = 310, 438
    cols, rows = 3, 3
    for batch_idx in range(0, len(pages), cols * rows):
        batch = pages[batch_idx : batch_idx + cols * rows]
        sheet = Image.new("RGB", (cols * thumb_w, rows * (thumb_h + 34)), "white")
        d = ImageDraw.Draw(sheet)
        for i, path in enumerate(batch):
            img = Image.open(path).convert("RGB")
            img.thumbnail((thumb_w - 16, thumb_h), Image.LANCZOS)
            x = (i % cols) * thumb_w + (thumb_w - img.width) // 2
            y = (i // cols) * (thumb_h + 34) + 28
            d.text((i % cols * thumb_w + 8, y - 24), path.stem, font=font(18, True), fill="#0F172A")
            sheet.paste(img, (x, y))
        out = out_dir / f"contact-sheet-{len(sheets) + 1:02d}.png"
        sheet.save(out)
        sheets.append(out)
    return sheets


def main() -> None:
    ensure_dirs()
    assets = create_assets()
    build_docx(TEMP_DOCX, assets)
    draft_pdf = render_docx_to_pdf(TEMP_DOCX, RENDER_DIR / "draft")
    total_pages, page_map = extract_page_map(draft_pdf)
    build_docx(OUTPUT_DOCX, assets, page_map=page_map, total_pages=total_pages)
    final_pdf = render_docx_to_pdf(OUTPUT_DOCX, RENDER_DIR / "final")
    final_pages = render_pdf_to_pngs(final_pdf, RENDER_DIR / "final")
    sheets = make_contact_sheets(final_pages, RENDER_DIR / "final")
    print(f"DOCX={OUTPUT_DOCX}")
    print(f"PDF={final_pdf}")
    print(f"PAGES={len(final_pages)}")
    for sheet in sheets:
        print(f"SHEET={sheet}")


if __name__ == "__main__":
    main()
```
