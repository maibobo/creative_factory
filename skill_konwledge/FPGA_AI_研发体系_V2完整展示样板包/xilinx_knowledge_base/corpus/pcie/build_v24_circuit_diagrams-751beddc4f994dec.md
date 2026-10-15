# build_v24_circuit_diagrams

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\build_v24_circuit_diagrams.py`
- SHA-256: `751beddc4f994dec572a33b661b5b9bac928d0967b78595791b4fdc1830a04a9`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\build_v24_circuit_diagrams.py

```python
"""生成V2.4 DOCX使用的电路框图/Visio风格高分辨率图。

图片只写入本地/远程工程docs/figures_v24，不在前台显示。DOCX继续保留原有
Word表格式架构图，并把这些重绘图作为行内图片紧邻插入。
"""

from __future__ import annotations

import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from v24_visual_catalog import (
    FORMAL_MODULES,
    MODULE_VISUALS,
    OVERALL_ARCHITECTURE_ROWS,
    OVERALL_DATA_FLOW,
    WAVEFORMS,
)


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "figures_v24"

W = 2400
H = 1280
BG = "#FFFFFF"
INK = "#17324D"
BLUE = "#1F4E78"
MID_BLUE = "#5B9BD5"
LIGHT_BLUE = "#D9EAF7"
PALE_BLUE = "#EFF6FA"
GRAY = "#667788"
LIGHT_GRAY = "#F2F4F7"
GREEN = "#2E7D6B"
GOLD = "#B07A15"


def font(size: int, bold: bool = False):
    candidates = [
        Path("C:/Windows/Fonts/msyhbd.ttc" if bold else "C:/Windows/Fonts/msyh.ttc"),
        Path("C:/Windows/Fonts/simhei.ttf"),
        Path("C:/Windows/Fonts/arial.ttf"),
    ]
    for candidate in candidates:
        if candidate.is_file():
            return ImageFont.truetype(str(candidate), size=size)
    return ImageFont.load_default()


TITLE_FONT = font(58, True)
LANE_FONT = font(42, True)
NODE_FONT = font(39, True)
BODY_FONT = font(35)
PIN_FONT = font(38, True)


def text_width(draw, value: str, face) -> int:
    box = draw.textbbox((0, 0), value, font=face)
    return box[2] - box[0]


def wrap_text(draw, value: str, face, max_width: int) -> list[str]:
    result: list[str] = []
    for source_line in value.splitlines() or [""]:
        if not source_line:
            result.append("")
            continue
        current = ""
        for char in source_line:
            candidate = current + char
            if current and text_width(draw, candidate, face) > max_width:
                result.append(current)
                current = char
            else:
                current = candidate
        if current:
            result.append(current)
    return result


def centered_text(draw, box, value: str, face, fill=INK, spacing=7) -> None:
    x0, y0, x1, y1 = box
    lines = wrap_text(draw, value, face, max(40, x1 - x0 - 30))
    line_height = face.size + spacing
    top = y0 + max(0, ((y1 - y0) - len(lines) * line_height) // 2)
    for index, line in enumerate(lines):
        width = text_width(draw, line, face)
        draw.text(((x0 + x1 - width) / 2, top + index * line_height), line, font=face, fill=fill)


def rounded_box(draw, box, fill, outline=BLUE, width=4, radius=22) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def arrow(draw, start, end, color=BLUE, width=6) -> None:
    x0, y0 = start
    x1, y1 = end
    draw.line((x0, y0, x1, y1), fill=color, width=width)
    if abs(x1 - x0) >= abs(y1 - y0):
        direction = 1 if x1 >= x0 else -1
        head = [(x1, y1), (x1 - 22 * direction, y1 - 13), (x1 - 22 * direction, y1 + 13)]
    else:
        direction = 1 if y1 >= y0 else -1
        head = [(x1, y1), (x1 - 13, y1 - 22 * direction), (x1 + 13, y1 - 22 * direction)]
    draw.polygon(head, fill=color)


def pin(draw, center, label: str, color=BLUE) -> None:
    x, y = center
    draw.ellipse((x - 24, y - 24, x + 24, y + 24), fill=BG, outline=color, width=4)
    bbox = draw.textbbox((0, 0), label, font=PIN_FONT)
    draw.text((x - (bbox[2] - bbox[0]) / 2, y - (bbox[3] - bbox[1]) / 2 - 3), label, font=PIN_FONT, fill=color)


def title_band(draw, title: str, subtitle: str) -> None:
    draw.rectangle((0, 0, W, 142), fill=BLUE)
    draw.text((65, 30), title, font=TITLE_FONT, fill="white")
    sub_width = text_width(draw, subtitle, BODY_FONT)
    draw.text((W - 65 - sub_width, 58), subtitle, font=BODY_FONT, fill="#D9EAF7")


def split_core(value: str) -> list[str]:
    parts = []
    for line in value.splitlines():
        parts.extend(re.split(r"\s*[→↓↔]\s*", line))
    return [part.strip() for part in parts if part.strip()]


def module_diagram(module_name: str) -> Path:
    spec = MODULE_VISUALS[module_name]
    inputs, core, outputs = spec["architecture"][0]
    input_nodes = [item.strip() for item in inputs.splitlines() if item.strip()]
    core_nodes = split_core(core)
    output_nodes = [item.strip() for item in outputs.splitlines() if item.strip()]

    image = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(image)
    title_band(draw, f"{module_name}  顶层架构", "I=输入｜O=输出｜正交连接")

    boundary = (640, 185, 1760, 1160)
    rounded_box(draw, boundary, PALE_BLUE, outline=BLUE, width=6, radius=30)
    centered_text(draw, (690, 184, 1710, 250), module_name, LANE_FONT, BLUE)

    def side_nodes(nodes, x0, x1, side):
        count = max(1, len(nodes))
        available = 850
        height = min(165, max(110, available // count - 20))
        gap = (available - count * height) // max(1, count - 1) if count > 1 else 0
        y = 245
        centers = []
        for item in nodes:
            box = (x0, y, x1, y + height)
            rounded_box(draw, box, LIGHT_GRAY, outline=GRAY, width=3, radius=18)
            centered_text(draw, box, item, BODY_FONT)
            centers.append((x1 if side == "I" else x0, y + height // 2))
            y += height + gap
        return centers

    input_centers = side_nodes(input_nodes, 55, 500, "I")
    output_centers = side_nodes(output_nodes, 1900, 2345, "O")

    core_count = max(1, len(core_nodes))
    core_height = min(145, max(92, 790 // core_count - 15))
    core_gap = (790 - core_count * core_height) // max(1, core_count - 1) if core_count > 1 else 0
    core_boxes = []
    y = 300
    for index, item in enumerate(core_nodes):
        box = (825, y, 1575, y + core_height)
        rounded_box(draw, box, LIGHT_BLUE if index % 2 == 0 else "#E8EEF5", outline=MID_BLUE, width=4, radius=20)
        centered_text(draw, box, item, NODE_FONT if len(item) < 22 else BODY_FONT, BLUE)
        core_boxes.append(box)
        y += core_height + core_gap

    if core_boxes:
        for first, second in zip(core_boxes, core_boxes[1:]):
            arrow(draw, ((first[0] + first[2]) // 2, first[3]), ((second[0] + second[2]) // 2, second[1] - 2), MID_BLUE, 5)

    input_bus_y = 610
    arrow(draw, (500, input_bus_y), (810, input_bus_y), GREEN, 6)
    pin(draw, (575, input_bus_y), "I", GREEN)
    for _, node_y in input_centers:
        draw.line((500, node_y, 535, node_y, 535, input_bus_y), fill=GREEN, width=4)
        draw.ellipse((529, input_bus_y - 6, 541, input_bus_y + 6), fill=GREEN)

    output_bus_y = 720
    arrow(draw, (1590, output_bus_y), (1900, output_bus_y), GOLD, 6)
    pin(draw, (1825, output_bus_y), "O", GOLD)
    for _, node_y in output_centers:
        draw.line((1865, output_bus_y, 1865, node_y, 1900, node_y), fill=GOLD, width=4)
        draw.ellipse((1859, output_bus_y - 6, 1871, output_bus_y + 6), fill=GOLD)

    draw.text((60, 1205), "I端口只向模块内部传递；O端口只由模块内部驱动。双向协议由独立I/O信号组合表达。", font=BODY_FONT, fill=GRAY)
    path = OUT / f"{module_name}_visio_circuit.png"
    image.save(path, format="PNG", optimize=True)
    return path


def overall_architecture_diagram() -> Path:
    image = Image.new("RGB", (W, 1660), BG)
    draw = ImageDraw.Draw(image)
    title_band(draw, "正式Vitis兼容通路总体顶层架构", "控制、采集、存储三通道")
    headers = ["软件控制 / 所有权", "ADC采集 / DDR缓存", "NoPHAE / SSD持久化"]
    lane_x = [(55, 785), (835, 1565), (1615, 2345)]
    for index, (x0, x1) in enumerate(lane_x):
        draw.rounded_rectangle((x0, 175, x1, 1555), radius=24, fill=PALE_BLUE if index == 1 else LIGHT_GRAY, outline=BLUE, width=4)
        centered_text(draw, (x0 + 10, 190, x1 - 10, 260), headers[index], LANE_FONT, BLUE)

    node_centers = [[], [], []]
    for col, (x0, x1) in enumerate(lane_x):
        values = [row[col] for row in OVERALL_ARCHITECTURE_ROWS if row[col].strip()]
        y = 295
        for value in values:
            cleaned = re.sub(r"^[↓↑↔]+\s*", "", value).replace("↑↓", "")
            box = (x0 + 42, y, x1 - 42, y + 145)
            rounded_box(draw, box, LIGHT_BLUE if col == 1 else "#FFFFFF", outline=MID_BLUE if col == 1 else GRAY, width=3, radius=18)
            centered_text(draw, box, cleaned, BODY_FONT)
            node_centers[col].append(((x0 + x1) // 2, y, y + 145))
            y += 176
        for first, second in zip(node_centers[col], node_centers[col][1:]):
            arrow(draw, (first[0], first[2]), (second[0], second[1] - 3), BLUE, 4)

    # 三条关键跨泳道连接：控制上下文、Manager描述符、DDR到NoPHAE DMA源。
    arrow(draw, (785, 560), (835, 560), GREEN, 6)
    pin(draw, (810, 560), "I", GREEN)
    arrow(draw, (835, 1070), (785, 1070), GOLD, 6)
    pin(draw, (810, 1070), "O", GOLD)
    arrow(draw, (1565, 1240), (1615, 1240), GREEN, 6)
    pin(draw, (1590, 1240), "I", GREEN)
    draw.text((65, 1585), "跨通道连线分别表示Capture控制、Segment描述符/状态和DDR作为NoPHAE DMA源；Manager不搬运Payload。", font=BODY_FONT, fill=GRAY)
    path = OUT / "overall_architecture_visio_circuit.png"
    image.save(path, format="PNG", optimize=True)
    return path


def overall_data_flow_diagram() -> Path:
    image = Image.new("RGB", (W, 1510), BG)
    draw = ImageDraw.Draw(image)
    title_band(draw, "一次Capture的端到端数据流", "八阶段数据路径")
    positions = [
        (65, 200), (630, 200), (1195, 200), (1760, 200),
        (1760, 805), (1195, 805), (630, 805), (65, 805),
    ]
    boxes = []
    for index, row in enumerate(OVERALL_DATA_FLOW):
        x, y = positions[index]
        box = (x, y, x + 505, y + 395)
        fill = LIGHT_BLUE if index in {1, 2, 3} else ("#E8F3EF" if index in {4, 5} else LIGHT_GRAY)
        rounded_box(draw, box, fill, outline=BLUE, width=4, radius=24)
        draw.ellipse((x + 20, y + 18, x + 76, y + 74), fill=BLUE)
        centered_text(draw, (x + 20, y + 18, x + 76, y + 74), row[0], PIN_FONT, "white")
        centered_text(draw, (x + 90, y + 20, x + 485, y + 105), row[1], NODE_FONT, BLUE)
        centered_text(draw, (x + 30, y + 112, x + 475, y + 365), row[2], BODY_FONT, INK)
        boxes.append(box)

    for index in range(3):
        arrow(draw, (boxes[index][2], (boxes[index][1] + boxes[index][3]) // 2), (boxes[index + 1][0] - 8, (boxes[index + 1][1] + boxes[index + 1][3]) // 2), BLUE, 6)
    arrow(draw, ((boxes[3][0] + boxes[3][2]) // 2, boxes[3][3]), ((boxes[4][0] + boxes[4][2]) // 2, boxes[4][1] - 8), BLUE, 6)
    for index in range(4, 7):
        arrow(draw, (boxes[index][0], (boxes[index][1] + boxes[index][3]) // 2), (boxes[index + 1][2] + 8, (boxes[index + 1][1] + boxes[index + 1][3]) // 2), BLUE, 6)
    draw.text((65, 1430), "箭头表示Capture数据及其元数据的因果方向；ready/valid stall时发送端保持，ADC源本身不可反压。", font=BODY_FONT, fill=GRAY)
    path = OUT / "overall_data_flow_visio_circuit.png"
    image.save(path, format="PNG", optimize=True)
    return path


def dashed_vertical(draw, x: int, y0: int, y1: int, color="#B8C2CC") -> None:
    dash = 14
    gap = 10
    y = y0
    while y < y1:
        draw.line((x, y, x, min(y + dash, y1)), fill=color, width=3)
        y += dash + gap


def timing_waveform_diagram(module_name: str) -> Path:
    wave = WAVEFORMS[module_name]
    cycles = wave["cycles"]
    signals = wave["signals"]
    row_height = 105
    image_height = 285 + row_height * len(signals)
    image = Image.new("RGB", (W, image_height), BG)
    draw = ImageDraw.Draw(image)
    title_band(draw, f"{module_name}  关键时序", "周期边界使用垂直虚线")

    timeline_x0 = 610
    timeline_x1 = 2335
    timeline_y0 = 225
    timeline_y1 = image_height - 55
    cycle_width = (timeline_x1 - timeline_x0) / len(cycles)

    draw.text((65, 175), "信号", font=LANE_FONT, fill=BLUE)
    for index, cycle in enumerate(cycles):
        x0 = timeline_x0 + index * cycle_width
        x1 = timeline_x0 + (index + 1) * cycle_width
        label_width = text_width(draw, cycle, NODE_FONT)
        draw.text(((x0 + x1 - label_width) / 2, 172), cycle, font=NODE_FONT, fill=BLUE)
    for boundary in range(len(cycles) + 1):
        x = round(timeline_x0 + boundary * cycle_width)
        dashed_vertical(draw, x, timeline_y0, timeline_y1)

    for row_index, (signal, values) in enumerate(signals):
        center_y = 280 + row_index * row_height
        draw.line((55, center_y + 48, 2340, center_y + 48), fill="#E5E9ED", width=2)
        draw.text((65, center_y - 25), signal, font=BODY_FONT, fill=INK)

        if all(value in {"L", "H"} for value in values):
            high_y = center_y - 23
            low_y = center_y + 23
            for index, value in enumerate(values):
                x0 = round(timeline_x0 + index * cycle_width)
                x1 = round(timeline_x0 + (index + 1) * cycle_width)
                level_y = high_y if value == "H" else low_y
                draw.line((x0, level_y, x1, level_y), fill=BLUE, width=7)
                if index + 1 < len(values) and values[index + 1] != value:
                    next_y = high_y if values[index + 1] == "H" else low_y
                    # 每个周期边界只画一次垂直转换边沿。
                    draw.line((x1, level_y, x1, next_y), fill=BLUE, width=7)
        else:
            group_start = 0
            while group_start < len(values):
                group_end = group_start + 1
                while group_end < len(values) and values[group_end] == values[group_start]:
                    group_end += 1
                x0 = round(timeline_x0 + group_start * cycle_width) + 5
                x1 = round(timeline_x0 + group_end * cycle_width) - 5
                box = (x0, center_y - 32, x1, center_y + 32)
                draw.rounded_rectangle(box, radius=10, fill="#EFF6FA", outline=MID_BLUE, width=3)
                centered_text(draw, box, values[group_start], BODY_FONT, BLUE, spacing=4)
                group_start = group_end

    draw.text(
        (65, image_height - 42),
        "连续水平线表示电平保持；蓝色垂直线表示唯一一次上升沿或下降沿；灰色垂直虚线只分隔周期。",
        font=BODY_FONT,
        fill=GRAY,
    )
    path = OUT / f"{module_name}_timing_waveform.png"
    image.save(path, format="PNG", optimize=True)
    return path


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    generated = [overall_architecture_diagram(), overall_data_flow_diagram()]
    generated.extend(module_diagram(module_name) for module_name in FORMAL_MODULES)
    generated.extend(timing_waveform_diagram(module_name) for module_name in FORMAL_MODULES)
    print(f"V24_CIRCUIT_DIAGRAMS_GENERATED: {len(generated)} files in {OUT}")
    for path in generated:
        print(f"{path.name}: {path.stat().st_size} bytes")


if __name__ == "__main__":
    main()
```
