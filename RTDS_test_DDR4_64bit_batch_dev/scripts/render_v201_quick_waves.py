from __future__ import annotations

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "evidence" / "v201_quick_wave_draft"
RAW = EVIDENCE / "raw"
OUT_CLEAN = EVIDENCE / "figures_no_title_png"
OUT_TITLE = EVIDENCE / "figures_with_title_png"
OUT_CLEAN.mkdir(parents=True, exist_ok=True)
OUT_TITLE.mkdir(parents=True, exist_ok=True)
FONT_CN = r"C:\Windows\Fonts\msyh.ttc"
FONT_MONO = r"C:\Windows\Fonts\consola.ttf"


def load_vcd(path: Path):
    scopes, codes, widths, events = [], {}, {}, {}
    now, in_defs = 0, True
    with path.open("r", encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            line = raw.strip()
            if in_defs:
                if line.startswith("$scope "):
                    scopes.append(line.split()[2])
                elif line.startswith("$upscope"):
                    if scopes:
                        scopes.pop()
                elif line.startswith("$var "):
                    p = line.split()
                    name = "/" + "/".join(scopes + [p[4]])
                    codes[p[3]] = name
                    widths[name] = int(p[2])
                    events[name] = []
                elif line.startswith("$enddefinitions"):
                    in_defs = False
                continue
            if not line:
                continue
            if line[0] == "#":
                now = int(line[1:])
            elif line[0] in "01xXzZ":
                code, value = line[1:], line[0].lower()
                if code in codes:
                    events[codes[code]].append((now, value))
            elif line[0] in "bB":
                value, code = line[1:].split(None, 1)
                if code in codes:
                    events[codes[code]].append((now, value.lower()))
    return events, widths, now


def find_name(events, case, leaf):
    preferred = f"/tb_rtds_{case}/bus/{leaf}"
    if preferred in events:
        return preferred
    direct = f"/tb_rtds_{case}/{leaf}"
    if direct in events:
        return direct
    matches = [n for n in events if n.endswith("/" + leaf)]
    if not matches:
        raise KeyError(f"{case}: signal {leaf} not found")
    return sorted(matches, key=lambda n: (n.count("/"), len(n)))[0]


def intval(bits):
    return None if any(c in bits for c in "xz") else int(bits, 2)


def transition_time(events, name, predicate, occurrence=0):
    hits = [(t, v) for t, v in events[name] if predicate(v)]
    if len(hits) <= occurrence:
        raise RuntimeError(f"event not found: {name}, occurrence {occurrence}")
    return hits[occurrence][0]


def value_event(events, name, value, occurrence=0):
    return transition_time(events, name, lambda b: intval(b) == value, occurrence)


def max_value_event(events, name):
    known = [(t, intval(v)) for t, v in events[name] if intval(v) is not None]
    maximum = max(v for _, v in known)
    return next(t for t, v in known if v == maximum), maximum


def clamp_window(center, before, after, total):
    start = max(0, center - before)
    end = min(total, center + after)
    if end <= start:
        end = min(total, start + 1)
    return start, end


def specs_for(case, events, total):
    n = lambda leaf: find_name(events, case, leaf)
    if case == "1g":
        cfg = value_event(events, n("configured"), 1)
        sof = transition_time(events, n("tx_sof"), lambda b: b == "1")
        skip = transition_time(events, n("skipped_periods"), lambda b: (intval(b) or 0) > 0)
        down = transition_time(events, n("channel_up"), lambda b: b == "0", 1)
        return [
            ("01_1g_config_cdc.png", "1G首次合法配置译码与跨时钟锁存", *clamp_window(cfg, 1_000_000, 2_000_000, total),
             [("src_clk","bin"),("user_clk","bin"),("cfg_byte","hex"),("cfg_byte_valid","bin"),("decode_valid","bin"),("cfg_req","bin"),("cfg_ack","bin"),("configured","bin"),("configured_id","dec"),("cfg_user","hex")]),
            ("02_1g_payload_period.png", "1G两拍6Byte载荷与63拍发送周期", *clamp_window(sof, 300_000, 2_500_000, total),
             [("user_clk","bin"),("period_tick","bin"),("tx_valid","bin"),("tx_ready","bin"),("tx_sof","bin"),("tx_eof","bin"),("tx_rem","hex"),("tx_data","hex"),("completed_frames","dec")]),
            ("03_1g_backpressure_link.png", "1G反压保持、周期跳过与链路恢复", max(0,skip-1_000_000), min(total,down+4_000_000),
             [("user_clk","bin"),("channel_up","bin"),("tx_ready","bin"),("tx_valid","bin"),("tx_sof","bin"),("tx_eof","bin"),("tx_rem","hex"),("tx_data","hex"),("skipped_periods","dec")]),
        ]
    if case == "tx":
        lim300 = value_event(events, n("limit"), 300)
        peak_t, _ = max_value_event(events, n("peak_words"))
        return [
            ("04_tx_single_frame.png", "16Byte下行单帧FDMA读取与10G两拍发送", 0, min(total, lim300),
             [("fdma_clk","bin"),("user_clk","bin"),("limit","dec"),("raddr","hex"),("rareq","bin"),("rvalid","bin"),("rready","bin"),("tx_data","hex"),("sof","bin"),("eof","bin"),("valid","bin"),("ready","bin")]),
            ("05_tx_batch_near_full.png", "300帧批量下行、FIFO阈值504与反压排空", *clamp_window(peak_t, 500_000, 1_500_000, total),
             [("fdma_clk","bin"),("user_clk","bin"),("limit","dec"),("fifo_wr_cnt","dec"),("fifo_almost_full","bin"),("fifo_overflow","bin"),("fifo_underflow","bin"),("valid","bin"),("ready","bin"),("tx_data","hex"),("peak_words","dec")]),
        ]
    if case == "rx_fifo":
        full = transition_time(events, n("fifo_full"), lambda b: b == "1")
        drop = transition_time(events, n("dropped_frames"), lambda b: (intval(b) or 0) > 0)
        return [
            ("06_rx_fifo_cdc.png", "10G接收异步FIFO双时钟顺序传递", 0, min(total, full),
             [("user_clk","bin"),("mem_clk","bin"),("rx_valid","bin"),("rx_sof","bin"),("rx_eof","bin"),("rx_data","hex"),("frame_valid","bin"),("frame_ready","bin"),("frame_data","hex"),("received","dec")]),
            ("07_rx_fifo_full_drop.png", "接收FIFO满、按字丢弃及释放恢复", *clamp_window(drop, 200_000, 250_000, total),
             [("user_clk","bin"),("mem_clk","bin"),("rx_valid","bin"),("rx_ready","bin"),("fifo_full","bin"),("frame_valid","bin"),("frame_ready","bin"),("dropped_frames","dec"),("length_error","bin")]),
        ]
    if case == "ring":
        tail = value_event(events, n("fdma_wstrb"), 0x0F)
        first_pub = value_event(events, n("ready_blocks"), 1)
        seq16 = value_event(events, n("head_seq"), 16)
        full = value_event(events, n("ready_blocks"), 8)
        err = transition_time(events, n("inject_error"), lambda b: b == "1")
        return [
            ("08_ring_pack_tail.png", "上行低32bit紧凑拼接与奇数尾拍", *clamp_window(tail, 80_000, 120_000, total),
             [("clk","bin"),("frame_data","hex"),("frame_valid","bin"),("frame_ready","bin"),("half_valid","bin"),("fdma_wdata","hex"),("fdma_wstrb","hex"),("fdma_wvalid","bin"),("fdma_wdone","bin")]),
            ("09_ring_publish_ack.png", "100ms窗口封存、块发布与CPU确认", *clamp_window(first_pub, 120_000, 150_000, total),
             [("clk","bin"),("seal_pending","bin"),("fdma_wdone","bin"),("ready_blocks","dec"),("irq","bin"),("head_addr","hex"),("head_len","dec"),("head_seq","dec"),("cpu_ack","bin")]),
            ("10_ring_three_wraps.png", "八块循环回绕与三轮地址复用", *clamp_window(seq16, 5_000_000, 6_000_000, total),
             [("clk","bin"),("ready_blocks","dec"),("head_addr","hex"),("head_len","dec"),("head_seq","dec"),("publish_seq","dec"),("cpu_ack","bin")]),
            ("11_ring_full_no_overwrite.png", "八块全满、不覆盖队头与丢字统计", *clamp_window(full, 400_000, 700_000, total),
             [("clk","bin"),("frame_valid","bin"),("frame_ready","bin"),("ready_blocks","dec"),("head_addr","hex"),("head_len","dec"),("head_seq","dec"),("reject_word","bin"),("dropped_frames","dec"),("cpu_ack","bin")]),
            ("12_ring_error_recovery.png", "延迟写响应、错误写响应与恢复", *clamp_window(err, 1_200_000, 2_000_000, total),
             [("clk","bin"),("inject_error","bin"),("fdma_wareq","bin"),("fdma_wvalid","bin"),("fdma_wdone","bin"),("fdma_werror","bin"),("write_failure","bin"),("ready_blocks","dec"),("dropped_frames","dec"),("head_seq","dec")]),
        ]
    if case == "axi":
        high = value_event(events, n("M_AXI_AWADDR"), 0x100000)
        cross = value_event(events, n("M_AXI_AWADDR"), 0x180FF8)
        return [
            ("13_axi_independent_high_addr.png", "CONV_DMA的AW/W独立握手与高地址访问", *clamp_window(high, 100_000, 2_000_000, total),
             [("M_AXI_ACLK","bin"),("M_AXI_AWADDR","hex"),("M_AXI_AWVALID","bin"),("M_AXI_AWREADY","bin"),("M_AXI_WDATA","hex"),("M_AXI_WVALID","bin"),("M_AXI_WREADY","bin"),("M_AXI_BRESP","hex"),("M_AXI_BVALID","bin"),("fdma_wdone","bin")]),
            ("14_axi_4k_split.png", "跨4KiB突发拆分、读回与响应完成", *clamp_window(cross, 200_000, 5_000_000, total),
             [("M_AXI_ACLK","bin"),("fdma_waddr","hex"),("fdma_wsize","dec"),("M_AXI_AWADDR","hex"),("M_AXI_AWLEN","dec"),("M_AXI_AWVALID","bin"),("M_AXI_WLAST","bin"),("M_AXI_BVALID","bin"),("M_AXI_ARADDR","hex"),("M_AXI_RDATA","hex"),("fdma_wdone","bin")]),
        ]
    if case == "axi_tail":
        return [("15_axi_wstrb_tail.png", "WSTRB=0F贯穿FDMA、CONV_DMA与AXI RAM", 0, total,
                 [("M_AXI_ACLK","bin"),("fdma_wdata","hex"),("fdma_wstrb","hex"),("M_AXI_WDATA","hex"),("M_AXI_WSTRB","hex"),("M_AXI_WVALID","bin"),("M_AXI_WREADY","bin"),("M_AXI_BVALID","bin"),("M_AXI_RDATA","hex"),("fdma_wdone","bin")])]
    if case == "regs":
        start = transition_time(events, n("start"), lambda b: b == "1")
        ack = transition_time(events, n("ack"), lambda b: b == "1")
        return [
            ("16_regs_doorbell.png", "V2.01下行门铃、重复提交与自动清零", *clamp_window(start, 80_000, 180_000, total),
             [("clk","bin"),("awaddr","hex"),("wdata","hex"),("wstrb","hex"),("awvalid","bin"),("wvalid","bin"),("start","bin"),("command_addr","hex"),("command_len","dec"),("done","bin"),("starts","dec")]),
            ("17_regs_ack_status.png", "上行确认脉冲、WSTRB过滤与状态寄存器", *clamp_window(ack, 80_000, 220_000, total),
             [("clk","bin"),("awaddr","hex"),("wdata","hex"),("wstrb","hex"),("ack","bin"),("acks","dec"),("araddr","hex"),("rdata","hex"),("RX_READY_BLOCKS","dec"),("RX_HEAD_SEQ","dec"),("RX_DROPPED_FRAMES","dec")]),
        ]
    return []


def fmt(bits, width, radix):
    if any(c in bits for c in "xz"):
        return bits.upper()
    value = int(bits, 2)
    if radix == "dec":
        return str(value)
    if radix == "hex":
        return f"0x{value:0{max(1,(width+3)//4)}X}"
    return str(value)


def render(events, widths, filename, title, start, end, specs, titled):
    width_px, left, right = 2100, 440, 40
    top = 145 if titled else 92
    row_h, bottom = 58, 34
    image = Image.new("RGB", (width_px, top + row_h * len(specs) + bottom), "#0b1016")
    draw = ImageDraw.Draw(image)
    f_title = ImageFont.truetype(FONT_CN, 34)
    f_sig = ImageFont.truetype(FONT_MONO, 23)
    f_val = ImageFont.truetype(FONT_MONO, 18)
    f_axis = ImageFont.truetype(FONT_MONO, 18)
    if titled:
        draw.text((28, 18), title, font=f_title, fill="#f3f5f7")
        draw.text((28, 67), "VCD波形重绘图", font=f_title, fill="#77bdfb")
    span = max(1, end - start)
    xof = lambda t: left + int((t-start) * (width_px-left-right) / span)
    for i in range(11):
        x = left + int(i*(width_px-left-right)/10)
        draw.line((x,top-12,x,image.height-bottom+8),fill="#24313e")
        draw.text((x-36,top-43),f"{(start+span*i/10)/1e6:.3f}",font=f_axis,fill="#b2bdc8")
    draw.text((width_px-70,top-70),"us",font=f_axis,fill="#b2bdc8")
    for row,(leaf,radix) in enumerate(specs):
        name = find_name(events, filename.split('_',2)[1] if False else "", leaf) if False else None
        matches = [n for n in events if n.endswith("/"+leaf)]
        preferred = [n for n in matches if "/bus/" in n]
        name = (preferred or sorted(matches,key=lambda n:(n.count('/'),len(n))))[0]
        y0, yc = top+row*row_h, top+row*row_h+row_h//2
        draw.line((20,y0+row_h-1,width_px-right,y0+row_h-1),fill="#1c2833")
        draw.text((24,y0+15),leaf,font=f_sig,fill="#dae2ea")
        seq, before, inside = events[name], "x", []
        for t,v in seq:
            if t <= start: before=v
            elif t <= end: inside.append((t,v))
            else: break
        points=[(start,before)]+inside+[(end,None)]
        sw=widths[name]
        if sw==1 and radix=="bin":
            py=None
            for j in range(len(points)-1):
                t,v=points[j]; t2=points[j+1][0]; x1,x2=xof(t),xof(t2)
                yy=y0+10 if v=="1" else y0+row_h-10 if v=="0" else yc
                color="#43ef7c" if v in "01" else "#ff5c68"
                if py is not None: draw.line((x1,py,x1,yy),fill=color,width=2)
                draw.line((x1,yy,x2,yy),fill=color,width=3); py=yy
        else:
            for j in range(len(points)-1):
                t,v=points[j]; t2=points[j+1][0]; x1,x2=xof(t),xof(t2)
                color="#46d37a" if not any(c in v for c in "xz") else "#ff5c68"
                draw.line((x1,yc,x2,yc),fill=color,width=3)
                if j: draw.line((x1-4,yc-9,x1+4,yc+9),fill=color,width=2)
                label=fmt(v,sw,radix)
                if x2-x1>60:
                    max_chars=max(4,int((x2-x1-8)/11)); shown=label if len(label)<=max_chars else label[:max_chars-2]+".."
                    draw.text((x1+5,y0+8),shown,font=f_val,fill="#ffd166")
    draw.rectangle((1,1,image.width-2,image.height-2),outline="#73808d",width=2)
    image.save((OUT_TITLE if titled else OUT_CLEAN)/filename,optimize=True)


manifest=[]
for case in ("1g","tx","rx_fifo","ring","axi","axi_tail","regs"):
    vcd=RAW/case/f"{case}_full.vcd"
    events,widths,total=load_vcd(vcd)
    for filename,title,start,end,signals in specs_for(case,events,total):
        if not (0 <= start < end <= total):
            raise RuntimeError(f"invalid window {filename}: {start}..{end}/{total}")
        for leaf,_ in signals:
            if not any(n.endswith("/"+leaf) for n in events):
                raise KeyError(f"{filename}: {leaf}")
        render(events,widths,filename,title,start,end,signals,False)
        render(events,widths,filename,title,start,end,signals,True)
        manifest.append({"figure":filename,"title":title,"case":case,"vcd":str(vcd.relative_to(ROOT)),"start_ps":start,"end_ps":end,"signals":[x[0] for x in signals]})

(EVIDENCE/"wave_manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf-8")
print(f"WAVEFORM_RENDER_PASS figures={len(manifest)}")
