from __future__ import annotations

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "evidence" / "v201_quick_wave_draft_v2"
RAW = ROOT / "evidence" / "v201_quick_wave_draft" / "raw"
OUT = EVIDENCE / "figures_no_title_png"
OUT_TITLED = EVIDENCE / "figures_with_title_png"
OUT.mkdir(parents=True, exist_ok=True)
OUT_TITLED.mkdir(parents=True, exist_ok=True)
FONT_CN = r"C:\Windows\Fonts\msyh.ttc"
FONT_MONO = r"C:\Windows\Fonts\consola.ttf"


def load_vcd(path: Path):
    scopes, codes, widths, events = [], {}, {}, {}
    now, definitions = 0, True
    with path.open("r", encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            line = raw.strip()
            if definitions:
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
                    definitions = False
                continue
            if not line:
                continue
            if line[0] == "#":
                now = int(line[1:])
            elif line[0] in "01xXzZ":
                if line[1:] in codes:
                    events[codes[line[1:]]].append((now, line[0].lower()))
            elif line[0] in "bB":
                value, code = line[1:].split(None, 1)
                if code in codes:
                    events[codes[code]].append((now, value.lower()))
    return events, widths, now


def known(bits):
    return not any(c in bits for c in "xz")


def integer(bits):
    return int(bits, 2) if known(bits) else None


def resolve(events, case, leaf, prefer="bus"):
    choices = [n for n in events if n.endswith("/" + leaf)]
    if not choices:
        raise KeyError(f"{case}: {leaf}")
    roots = {
        "bus": f"/tb_rtds_{case}/bus/",
        "top": f"/tb_rtds_{case}/",
        "dut": f"/tb_rtds_{case}/U_DUT/",
        "ram": f"/tb_rtds_{case}/U_RAM/",
    }
    prefix = roots.get(prefer, prefer)
    exact = [n for n in choices if n.startswith(prefix)]
    return sorted(exact or choices, key=lambda n: (n.count("/"), len(n)))[0]


def times(events, name, value=None, rising=False, after=0):
    result, previous = [], None
    for t, bits in events[name]:
        if t < after:
            previous = bits
            continue
        iv = integer(bits)
        hit = iv == value if value is not None else True
        if rising:
            hit = bits == "1" and previous != "1"
        if hit:
            result.append(t)
        previous = bits
    return result


def first(events, name, value=None, rising=False, after=0):
    found = times(events, name, value, rising, after)
    if not found:
        raise RuntimeError(f"event missing: {name} value={value} after={after}")
    return found[0]


def around(center, before, after, total):
    return (max(0, center-before), min(total, center+after))


def fmt(bits, width, radix):
    if not known(bits):
        return bits.upper()
    value = int(bits, 2)
    if radix == "hex":
        return f"0x{value:0{max(1,(width+3)//4)}X}"
    if radix == "addr":
        return f"0x{value:X}"
    if radix == "dec":
        return str(value)
    if radix == "state":
        return str(value)
    return str(value)


def value_at(seq, moment):
    value = "x"
    for t, v in seq:
        if t > moment:
            break
        value = v
    return value


def events_in(seq, start, end):
    return [(t, v) for t, v in seq if start < t <= end]


def add_slice(events, widths, source, target, high, low):
    """从已记录调试总线生成只用于绘图的数值切片，不改变仿真证据。"""
    width = high-low+1
    out=[]
    previous=None
    for t,bits in events[source]:
        if known(bits):
            value=(int(bits,2)>>low)&((1<<width)-1)
            sliced=f"{value:0{width}b}"
        else:
            sliced="x"*width
        if sliced != previous:
            out.append((t,sliced)); previous=sliced
    events[target]=out
    widths[target]=width


def render(case, events, widths, filename, title, segments, groups, titled=False):
    width_px, label_w, right = 2300, 520, 42
    title_h = 72 if titled else 0
    axis_h, row_h, group_h, bottom = 62, 58, 42, 28
    rows = sum(1 + len(g[2]) for g in groups)
    height = title_h + axis_h + rows*row_h + len(groups)*group_h + bottom
    img = Image.new("RGB", (width_px, height), "#0A1017")
    draw = ImageDraw.Draw(img)
    ft = ImageFont.truetype(FONT_CN, 34)
    fg = ImageFont.truetype(FONT_CN, 25)
    fs = ImageFont.truetype(FONT_MONO, 22)
    fv = ImageFont.truetype(FONT_MONO, 18)
    fa = ImageFont.truetype(FONT_MONO, 17)
    if titled:
        draw.text((26, 17), title, font=ft, fill="#F4F7FA")
    plot_top = title_h + axis_h
    plot_w = width_px-label_w-right
    gap = 28 if len(segments) > 1 else 0
    seg_w = (plot_w-gap*(len(segments)-1))/len(segments)
    x0s = [label_w+i*(seg_w+gap) for i in range(len(segments))]

    def xpos(t, idx):
        a, b = segments[idx]
        return x0s[idx] + (t-a)*seg_w/max(1,b-a)

    for idx, (a, b) in enumerate(segments):
        for j in range(6):
            x = x0s[idx] + j*seg_w/5
            draw.line((x, plot_top-8, x, height-bottom), fill="#22313F", width=1)
            draw.text((x-34, plot_top-37), f"{(a+(b-a)*j/5)/1e6:.3f}", font=fa, fill="#B8C3CD")
        if idx:
            bx = x0s[idx]-gap/2
            draw.line((bx-7,plot_top-16,bx+2,plot_top-2),fill="#F4C95D",width=3)
            draw.line((bx+2,plot_top-16,bx+11,plot_top-2),fill="#F4C95D",width=3)
    draw.text((width_px-70, plot_top-61), "us", font=fa, fill="#B8C3CD")

    y = plot_top
    for domain, clock_spec, signals in groups:
        draw.rectangle((16,y,width_px-right,y+group_h-3), fill="#172738")
        draw.text((28,y+6),domain,font=fg,fill="#8DD6FF")
        y += group_h
        for label, leaf, radix, prefer in [clock_spec] + signals:
            name = resolve(events, case, leaf, prefer)
            seq, sw = events[name], widths[name]
            yc = y + row_h//2
            draw.line((16,y+row_h-1,width_px-right,y+row_h-1),fill="#1C2833")
            draw.text((28,y+15),label,font=fs,fill="#E2E8EF")
            for si,(a,b) in enumerate(segments):
                points=[(a,value_at(seq,a))]+events_in(seq,a,b)+[(b,None)]
                if sw == 1 and radix == "bin":
                    prev_y=None
                    for k in range(len(points)-1):
                        t,v=points[k]; t2=points[k+1][0]
                        xa,xb=xpos(t,si),xpos(t2,si)
                        yy=y+9 if v=="1" else y+row_h-9 if v=="0" else yc
                        color="#42F27D" if v in "01" else "#FF6170"
                        if prev_y is not None:
                            draw.line((xa,prev_y,xa,yy),fill=color,width=2)
                        draw.line((xa,yy,xb,yy),fill=color,width=3)
                        prev_y=yy
                else:
                    rail=12
                    for k in range(len(points)-1):
                        t,v=points[k]; t2=points[k+1][0]
                        xa,xb=xpos(t,si),xpos(t2,si)
                        color="#54D98C" if known(v) else "#FF6170"
                        if k:
                            draw.line((xa-6,yc-rail,xa+6,yc+rail),fill=color,width=2)
                            draw.line((xa-6,yc+rail,xa+6,yc-rail),fill=color,width=2)
                        draw.line((xa+6 if k else xa,yc-rail,xb,yc-rail),fill=color,width=2)
                        draw.line((xa+6 if k else xa,yc+rail,xb,yc+rail),fill=color,width=2)
                        label_text=fmt(v,sw,radix)
                        tw=draw.textbbox((0,0),label_text,font=fv)[2]
                        if xb-xa >= tw+12:
                            draw.text(((xa+xb-tw)/2,yc-10),label_text,font=fv,fill="#FFD166")
            y += row_h
    draw.rectangle((1,1,width_px-2,height-2),outline="#728191",width=2)
    img.save((OUT_TITLED if titled else OUT)/filename,optimize=True)


def S(label, leaf, radix="bin", prefer="bus"):
    return (label, leaf, radix, prefer)


def add(figures, case, ev, wd, total, name, title, segments, groups):
    for group in groups:
        for spec in [group[1]] + group[2]:
            resolve(ev,case,spec[1],spec[3])
    render(case,ev,wd,name,title,segments,groups,False)
    render(case,ev,wd,name,title,segments,groups,True)
    figures.append({"file":name,"title":title,"case":case,"segments_ps":segments,
                    "groups":[{"domain":g[0],"signals":[g[1][0]]+[s[0] for s in g[2]]} for g in groups]})


figures=[]
loaded={}
for case in ("1g","tx","rx_fifo","ring","axi","axi_tail","regs"):
    loaded[case]=load_vcd(RAW/case/f"{case}_full.vcd")

# 1G配置与发送
case="1g"; ev,wd,total=loaded[case]; n=lambda leaf,p="bus":resolve(ev,case,leaf,p)
cfg=first(ev,n("configured"),1); sof=times(ev,n("tx_sof"),rising=True)
skip=first(ev,n("skipped_periods"),1); downs=times(ev,n("channel_up"),0); down=next(t for t in downs if t>cfg)
up=first(ev,n("channel_up"),1,after=down+1); post_sof=[t for t in sof if t>up]
add(figures,case,ev,wd,total,"01_config_cdc.png","1 首次合法配置译码与跨时钟锁存",[around(cfg,700_000,1_200_000,total)],[
    ("250MHz配置域",S("src_clk","src_clk","bin","top"),[S("cfg_byte","cfg_byte","hex"),S("cfg_byte_valid","cfg_byte_valid"),S("decode_valid","decode_valid","bin","dut"),S("cfg_hold","cfg_hold","hex","dut"),S("cfg_req","cfg_req","bin","dut"),S("configured","configured"),S("configured_id","configured_id","dec")]),
    ("31.25MHz 1G用户域",S("user_clk","user_clk","bin","top"),[S("req_sync","req_sync","bin","dut"),S("cfg_user","cfg_user","hex","dut"),S("cfg_ack","cfg_ack","bin","dut")])])
add(figures,case,ev,wd,total,"02a_1g_payload.png","2a 6Byte载荷的两次接口握手",[around(sof[0],180_000,220_000,total)],[
    ("31.25MHz 1G用户域",S("user_clk","user_clk","bin","top"),[S("tx_curr_st","tx_curr_st","state","dut"),S("tx_valid","tx_valid"),S("tx_ready","tx_ready"),S("tx_sof","tx_sof"),S("tx_eof","tx_eof"),S("tx_rem","tx_rem","dec"),S("tx_data","tx_data","hex")])])
add(figures,case,ev,wd,total,"02b_1g_cadence.png","2b 连续发送机会的63拍周期",[(max(0,sof[0]-120_000),min(total,sof[1]+160_000))],[
    ("31.25MHz 1G用户域",S("user_clk","user_clk","bin","top"),[S("period_count","period_count","dec","dut"),S("period_tick","period_tick","bin","dut"),S("tx_sof","tx_sof"),S("completed_frames","completed_frames","dec","top")])])
add(figures,case,ev,wd,total,"03a_1g_backpressure.png","3a 反压保持与周期任务跳过",[around(skip,1_000_000,1_400_000,total)],[
    ("31.25MHz 1G用户域",S("user_clk","user_clk","bin","top"),[S("tx_curr_st","tx_curr_st","state","dut"),S("tx_ready","tx_ready"),S("tx_valid","tx_valid"),S("tx_sof","tx_sof"),S("tx_eof","tx_eof"),S("tx_rem","tx_rem","dec"),S("tx_data","tx_data","hex"),S("skipped_periods","skipped_periods","dec")])])
recovery_end=post_sof[1] if len(post_sof)>1 else up+5_000_000
add(figures,case,ev,wd,total,"03b_1g_link_recovery.png","3b 链路下降、重新准备与多帧恢复",[around(down,220_000,260_000,total),(max(0,up-180_000),min(total,recovery_end+240_000))],[
    ("31.25MHz 1G用户域",S("user_clk","user_clk","bin","top"),[S("channel_up","channel_up"),S("arm_count","arm_count","dec","dut"),S("tx_curr_st","tx_curr_st","state","dut"),S("tx_valid","tx_valid"),S("tx_sof","tx_sof"),S("tx_eof","tx_eof"),S("tx_data","tx_data","hex"),S("completed_frames","completed_frames","dec","top")])])

# 下行发送桥
case="tx"; ev,wd,total=loaded[case]; n=lambda leaf,p="bus":resolve(ev,case,leaf,p)
add_slice(ev,wd,n("dbg_fdma","top"),"/tb_rtds_tx/derived/fifo_write_count",35,26)
add_slice(ev,wd,n("dbg_user","top"),"/tb_rtds_tx/derived/fifo_read_count",36,27)
lim300=first(ev,n("limit"),300); req1=first(ev,n("rareq"),rising=True)
peak_t=max(((t,integer(v) or 0) for t,v in ev[n("peak_words","top")]),key=lambda x:x[1])[0]
ready_after=first(ev,n("ready"),1,after=lim300+1)
add(figures,case,ev,wd,total,"04_downlink_frame.png","4 16Byte下行帧边界、数据顺序与地址步进",[around(req1,90_000,260_000,total)],[
    ("250MHz FDMA读取域",S("fdma_clk","fdma_clk","bin","top"),[S("raddr","raddr","hex"),S("rareq","rareq"),S("rbusy","rbusy"),S("rvalid","rvalid"),S("rready","rready"),S("rdata","rdata","hex")]),
    ("156.25MHz 10G用户域",S("user_clk","user_clk","bin","top"),[S("tx_state","tx_state","state","dut"),S("valid","valid"),S("ready","ready"),S("sof","sof"),S("eof","eof"),S("tx_data","tx_data","hex"),S("received","received","dec","top")])])
add(figures,case,ev,wd,total,"05a_tx_fifo_fill.png","5a 300帧输入使FIFO占用达到504",[around(peak_t,500_000,450_000,total)],[
    ("250MHz FDMA读取域",S("fdma_clk","fdma_clk","bin","top"),[S("limit","limit","dec"),S("fifo_write_count","fifo_write_count","dec"),S("fifo_almost_full","fifo_almost_full","bin","dut"),S("peak_words","peak_words","dec","top"),S("fifo_overflow","fifo_overflow","bin","dut")]),
    ("156.25MHz 10G用户域",S("user_clk","user_clk","bin","top"),[S("ready","ready"),S("valid","valid"),S("tx_data","tx_data","hex")])])
add(figures,case,ev,wd,total,"05b_tx_fifo_drain.png","5b 接收端恢复后FIFO开始按序排空",[around(ready_after,60_000,220_000,total)],[
    ("250MHz FDMA读取域",S("fdma_clk","fdma_clk","bin","top"),[S("fifo_write_count","fifo_write_count","dec"),S("fifo_overflow","fifo_overflow","bin","dut")]),
    ("156.25MHz 10G用户域",S("user_clk","user_clk","bin","top"),[S("fifo_read_count","fifo_read_count","dec"),S("ready","ready"),S("valid","valid"),S("sof","sof"),S("eof","eof"),S("tx_data","tx_data","hex"),S("received","received","dec","top"),S("fifo_underflow","fifo_underflow","bin","dut")])])

# 接收异步FIFO
case="rx_fifo"; ev,wd,total=loaded[case]; n=lambda leaf,p="bus":resolve(ev,case,leaf,p)
first_in=first(ev,n("rx_valid"),rising=True); drop=first(ev,n("drop_bin","dut"),1); ready_read=first(ev,n("frame_ready"),1)
add(figures,case,ev,wd,total,"06_rx_fifo_cdc.png","6 接收数据跨时钟顺序传递",[around(first_in,80_000,230_000,total)],[
    ("156.25MHz接收域",S("user_clk","user_clk","bin","top"),[S("rx_valid","rx_valid"),S("rx_sof","rx_sof"),S("rx_eof","rx_eof"),S("rx_data","rx_data","hex"),S("rx_ready","rx_ready")]),
    ("250MHz存储域",S("mem_clk","mem_clk","bin","top"),[S("frame_valid","frame_valid"),S("frame_ready","frame_ready"),S("frame_data","frame_data","hex"),S("fifo_full","fifo_full"),S("received","received","dec","top")])])
add(figures,case,ev,wd,total,"07a_rx_fifo_full_drop.png","7a FIFO满时记录一个32bit有效字损失",[around(drop,110_000,170_000,total)],[
    ("156.25MHz接收域",S("user_clk","user_clk","bin","top"),[S("rx_valid","rx_valid"),S("rx_data","rx_data","hex"),S("rx_ready","rx_ready"),S("drop_bin","drop_bin","dec","dut")]),
    ("250MHz存储域",S("mem_clk","mem_clk","bin","top"),[S("fifo_almost_full","fifo_almost_full"),S("fifo_full","fifo_full"),S("dropped_frames","dropped_frames","dec")])])
add(figures,case,ev,wd,total,"07b_rx_fifo_release.png","7b 计数跨域、FIFO排空与后续接收恢复",[around(ready_read,120_000,250_000,total)],[
    ("156.25MHz接收域",S("user_clk","user_clk","bin","top"),[S("drop_bin","drop_bin","dec","dut"),S("rx_valid","rx_valid"),S("rx_ready","rx_ready")]),
    ("250MHz存储域",S("mem_clk","mem_clk","bin","top"),[S("dropped_frames","dropped_frames","dec"),S("fifo_full","fifo_full"),S("frame_ready","frame_ready"),S("frame_valid","frame_valid"),S("frame_data","frame_data","hex"),S("received","received","dec","top")])])

# 上行块写入
case="ring"; ev,wd,total=loaded[case]; n=lambda leaf,p="bus":resolve(ev,case,leaf,p)
pair=first(ev,n("pair_start","dut"),rising=True); tail=first(ev,n("tail_start","dut"),rising=True)
tick=first(ev,n("tick","dut"),rising=True); push=first(ev,n("push_block","dut"),rising=True); ack=first(ev,n("cpu_ack"),rising=True,after=push)
seq8=first(ev,n("head_seq"),8); seq16=first(ev,n("head_seq"),16); full=first(ev,n("ready_blocks"),8)
drop_ring=first(ev,n("dropped_frames"),1); ack_full=first(ev,n("cpu_ack"),rising=True,after=full)
delay_start=first(ev,n("response_delay","top"),300); inj=first(ev,n("inject_error","top"),1); inj_off=first(ev,n("inject_error","top"),0,after=inj+1)
add(figures,case,ev,wd,total,"08a_pair_pack.png","8a 两个低32bit字组成一个64bit DDR写数据",[around(pair,70_000,130_000,total)],[
    ("250MHz存储与DDR写域",S("clk","clk","bin","top"),[S("frame_data","frame_data","hex"),S("frame_valid","frame_valid"),S("frame_ready","frame_ready"),S("half_data","half_data","hex","dut"),S("half_valid","half_valid","bin","dut"),S("pair_start","pair_start","bin","dut"),S("fdma_waddr","fdma_waddr","hex"),S("fdma_wdata","fdma_wdata","hex"),S("fdma_wstrb","fdma_wstrb","hex"),S("fdma_wdone","fdma_wdone")])])
add(figures,case,ev,wd,total,"08b_tail_pack.png","8b 单个剩余字使用低四字节写入DDR",[around(tail,70_000,150_000,total)],[
    ("250MHz存储与DDR写域",S("clk","clk","bin","top"),[S("half_data","half_data","hex","dut"),S("half_valid","half_valid","bin","dut"),S("tail_start","tail_start","bin","dut"),S("active_transfer","active_transfer","hex","dut"),S("fdma_waddr","fdma_waddr","hex"),S("fdma_wdata","fdma_wdata","hex"),S("fdma_wstrb","fdma_wstrb","hex"),S("fdma_wvalid","fdma_wvalid"),S("fdma_waccept","fdma_waccept"),S("fdma_wdone","fdma_wdone"),S("used_bytes","used_bytes","dec","dut")])])
add(figures,case,ev,wd,total,"09a_segment_end.png","9a 100ms采集段结束请求与最后一个DDR写事务",[around(tick,70_000,180_000,total)],[
    ("250MHz存储与DDR写域",S("clk","clk","bin","top"),[S("time_count","time_count","dec","dut"),S("tick","tick","bin","dut"),S("seal_pending","seal_pending","bin","dut"),S("half_valid","half_valid","bin","dut"),S("tail_start","tail_start","bin","dut"),S("write_curr_st","write_curr_st","state","dut"),S("fdma_wdone","fdma_wdone")])])
add(figures,case,ev,wd,total,"09b_queue_and_ack.png","9b DDR写成功后加入待取队列并由CPU确认",[(max(0,push-80_000),min(total,ack+80_000))],[
    ("250MHz存储与CPU交互域",S("clk","clk","bin","top"),[S("write_success","write_success","bin","dut"),S("seal_done","seal_done","bin","dut"),S("push_block","push_block","bin","dut"),S("queued","queued","dec","dut"),S("irq","irq"),S("head_addr","head_addr","hex"),S("head_len","head_len","dec"),S("head_seq","head_seq","dec"),S("cpu_ack","cpu_ack"),S("pop_block","pop_block","bin","dut")])])
round_centers=[push,seq8,seq16]
for idx,center in enumerate(round_centers,1):
    add(figures,case,ev,wd,total,f"10{chr(96+idx)}_ring_round{idx}.png",f"10{chr(96+idx)} 八块地址第{idx}轮使用",[around(center,160_000,2_900_000,total)],[
        ("250MHz块队列域",S("clk","clk","bin","top"),[S("write_block","write_block","dec","dut"),S("read_block","read_block","dec","dut"),S("queued","queued","dec","dut"),S("head_addr","head_addr","hex"),S("head_len","head_len","dec"),S("head_seq","head_seq","dec"),S("publish_seq","publish_seq","dec","dut"),S("cpu_ack","cpu_ack")])])
add(figures,case,ev,wd,total,"11a_queue_full.png","11a 八块均待取时保持队头并记录新增数据损失",[around(drop_ring,180_000,260_000,total)],[
    ("250MHz块队列域",S("clk","clk","bin","top"),[S("frame_valid","frame_valid"),S("frame_data","frame_data","hex"),S("queued","queued","dec","dut"),S("head_addr","head_addr","hex"),S("head_seq","head_seq","dec"),S("reject_word","reject_word","bin","dut"),S("dropped_frames","dropped_frames","dec")])])
add(figures,case,ev,wd,total,"11b_queue_resume.png","11b CPU确认后队头推进并恢复DDR写入",[around(ack_full,100_000,300_000,total)],[
    ("250MHz块队列域",S("clk","clk","bin","top"),[S("cpu_ack","cpu_ack"),S("pop_block","pop_block","bin","dut"),S("queued","queued","dec","dut"),S("read_block","read_block","dec","dut"),S("head_addr","head_addr","hex"),S("head_seq","head_seq","dec"),S("frame_ready","frame_ready")])])
add(figures,case,ev,wd,total,"12a_delayed_response.png","12a DDR写响应延迟期间不增加待取块数",[around(delay_start,100_000,1_500_000,total)],[
    ("250MHz DDR写域",S("clk","clk","bin","top"),[S("response_delay","response_delay","dec","top"),S("fdma_wareq","fdma_wareq"),S("fdma_wvalid","fdma_wvalid"),S("fdma_waccept","fdma_waccept"),S("write_curr_st","write_curr_st","state","dut"),S("fdma_wdone","fdma_wdone"),S("ready_blocks","ready_blocks","dec"),S("head_seq","head_seq","dec")])])
fail_t=first(ev,n("write_failure","dut"),rising=True,after=inj)
recover_done=first(ev,n("fdma_wdone"),rising=True,after=inj_off)
add(figures,case,ev,wd,total,"12b_error_recovery.png","12b AXI写错误的影响与后续成功恢复",[around(fail_t,100_000,180_000,total),around(recover_done,120_000,200_000,total)],[
    ("250MHz DDR写域",S("clk","clk","bin","top"),[S("inject_error","inject_error","bin","top"),S("fdma_waddr","fdma_waddr","hex"),S("fdma_wdone","fdma_wdone"),S("fdma_werror","fdma_werror"),S("write_failure","write_failure","bin","dut"),S("used_bytes","used_bytes","dec","dut"),S("dropped_frames","dropped_frames","dec"),S("ready_blocks","ready_blocks","dec"),S("head_seq","head_seq","dec")])])

# AXI地址、边界与部分写
case="axi"; ev,wd,total=loaded[case]; n=lambda leaf,p="bus":resolve(ev,case,leaf,p)
high_addrs=[0x100000+i*0x40000 for i in range(8)]
aw_centers=[first(ev,n("M_AXI_AWADDR"),a) for a in high_addrs]
ar_centers=[first(ev,n("M_AXI_ARADDR"),a) for a in high_addrs]
add(figures,case,ev,wd,total,"13a_high_address_write.png","13a 八个256KiB块基址形成独立AXI写事务",[around(t,24_000,48_000,total) for t in aw_centers],[
    ("250MHz AXI写域",S("M_AXI_ACLK","M_AXI_ACLK","bin","top"),[S("M_AXI_AWADDR","M_AXI_AWADDR","addr"),S("M_AXI_AWLEN","M_AXI_AWLEN","dec"),S("M_AXI_AWVALID","M_AXI_AWVALID"),S("M_AXI_AWREADY","M_AXI_AWREADY"),S("M_AXI_WDATA","M_AXI_WDATA","hex"),S("M_AXI_BVALID","M_AXI_BVALID"),S("M_AXI_BRESP","M_AXI_BRESP","hex")])])
add(figures,case,ev,wd,total,"13b_high_address_readback.png","13b 高地址读回数据互不混叠",[around(t,24_000,56_000,total) for t in ar_centers],[
    ("250MHz AXI读域",S("M_AXI_ACLK","M_AXI_ACLK","bin","top"),[S("M_AXI_ARADDR","M_AXI_ARADDR","addr"),S("M_AXI_ARVALID","M_AXI_ARVALID"),S("M_AXI_ARREADY","M_AXI_ARREADY"),S("M_AXI_RDATA","M_AXI_RDATA","hex"),S("M_AXI_RVALID","M_AXI_RVALID"),S("M_AXI_RREADY","M_AXI_RREADY"),S("M_AXI_RLAST","M_AXI_RLAST")])])
cross_aw=[first(ev,n("M_AXI_AWADDR"),a) for a in (0x180FF8,0x181000,0x181800,0x182000)]
cross_ar=[first(ev,n("M_AXI_ARADDR"),a) for a in (0x180FF8,0x181000,0x181800,0x182000)]
bvalid_after=[t for t in times(ev,n("M_AXI_BVALID"),rising=True) if t>cross_aw[0]][:4]
rlast_after=[t for t in times(ev,n("M_AXI_RLAST"),rising=True) if t>cross_ar[0]][:4]
write_segments=[(max(0,a-24_000),min(total,b+28_000)) for a,b in zip(cross_aw,bvalid_after)]
read_segments=[(max(0,a-24_000),min(total,b+28_000)) for a,b in zip(cross_ar,rlast_after)]
add(figures,case,ev,wd,total,"14a_4k_write_split.png","14a 520拍写请求按4KiB边界拆成四个AXI突发",write_segments,[
    ("250MHz AXI写域",S("M_AXI_ACLK","M_AXI_ACLK","bin","top"),[S("fdma_waddr","fdma_waddr","addr"),S("fdma_wsize","fdma_wsize","dec"),S("M_AXI_AWADDR","M_AXI_AWADDR","addr"),S("M_AXI_AWLEN","M_AXI_AWLEN","dec"),S("M_AXI_AWVALID","M_AXI_AWVALID"),S("M_AXI_AWREADY","M_AXI_AWREADY"),S("M_AXI_WLAST","M_AXI_WLAST"),S("M_AXI_BVALID","M_AXI_BVALID")])])
add(figures,case,ev,wd,total,"14b_4k_read_split.png","14b 对应读请求按相同边界拆分并连续返回",read_segments,[
    ("250MHz AXI读域",S("M_AXI_ACLK","M_AXI_ACLK","bin","top"),[S("fdma_raddr","fdma_raddr","addr"),S("fdma_rsize","fdma_rsize","dec"),S("M_AXI_ARADDR","M_AXI_ARADDR","addr"),S("M_AXI_ARLEN","M_AXI_ARLEN","dec"),S("M_AXI_ARVALID","M_AXI_ARVALID"),S("M_AXI_RDATA","M_AXI_RDATA","hex"),S("M_AXI_RVALID","M_AXI_RVALID"),S("M_AXI_RLAST","M_AXI_RLAST")])])

case="axi_tail"; ev,wd,total=loaded[case]; n=lambda leaf,p="bus":resolve(ev,case,leaf,p)
ff=first(ev,n("fdma_wstrb"),0xFF); low=first(ev,n("fdma_wstrb"),0x0F); rv=first(ev,n("M_AXI_RVALID"),rising=True)
for suffix,title,center in (("15a_wstrb_ff.png","15a 全八字节初始写入",ff),("15b_wstrb_0f.png","15b 仅低四字节更新",low),("15c_wstrb_readback.png","15c 读回确认高32bit保持、低32bit更新",rv)):
    add(figures,case,ev,wd,total,suffix,title,[around(center,55_000,90_000,total)],[
        ("250MHz AXI访问域",S("M_AXI_ACLK","M_AXI_ACLK","bin","top"),[S("fdma_wdata","fdma_wdata","hex"),S("fdma_wstrb","fdma_wstrb","hex"),S("M_AXI_WDATA","M_AXI_WDATA","hex"),S("M_AXI_WSTRB","M_AXI_WSTRB","hex"),S("M_AXI_WVALID","M_AXI_WVALID"),S("M_AXI_WREADY","M_AXI_WREADY"),S("M_AXI_BVALID","M_AXI_BVALID"),S("M_AXI_RDATA","M_AXI_RDATA","hex"),S("M_AXI_RVALID","M_AXI_RVALID")])])

# AXI-Lite寄存器
case="regs"; ev,wd,total=loaded[case]; n=lambda leaf,p="bus":resolve(ev,case,leaf,p)
start=first(ev,n("start"),rising=True); done=first(ev,n("done"),rising=True); next_start=first(ev,n("start"),rising=True,after=done+1)
ack1=first(ev,n("ack"),rising=True); status_centers=[first(ev,n("araddr"),a) for a in (0x30,0x34,0x38)]
add(figures,case,ev,wd,total,"16a_submit_start.png","16a 0x20提交状态产生一次下行启动脉冲",[around(start,80_000,100_000,total)],[
    ("250MHz AXI-Lite寄存器域",S("clk","clk","bin","top"),[S("awaddr","awaddr","hex"),S("wdata","wdata","hex"),S("wstrb","wstrb","hex"),S("CPU_WR_DONE","CPU_WR_DONE","hex","dut"),S("CPU_WR_DONE_d","CPU_WR_DONE_d","bin","dut"),S("CPU_WR_DONE_pos","CPU_WR_DONE_pos","bin","dut"),S("start","start"),S("command_addr","command_addr","hex"),S("command_len","command_len","dec"),S("starts","starts","dec","top")])])
add(figures,case,ev,wd,total,"16b_submit_clear_restart.png","16b 忙时重复提交无效、硬件清零后允许再次启动",[around(done,90_000,80_000,total),around(next_start,60_000,90_000,total)],[
    ("250MHz AXI-Lite寄存器域",S("clk","clk","bin","top"),[S("done","done"),S("CPU_WR_DONE","CPU_WR_DONE","hex","dut"),S("CPU_WR_DONE_pos","CPU_WR_DONE_pos","bin","dut"),S("start","start"),S("command_addr","command_addr","hex"),S("command_len","command_len","dec"),S("starts","starts","dec","top"),S("rdata","rdata","hex")])])
add(figures,case,ev,wd,total,"17a_ack_wstrb.png","17a 0x14确认脉冲与低字节WSTRB过滤",[around(ack1,70_000,150_000,total)],[
    ("250MHz AXI-Lite寄存器域",S("clk","clk","bin","top"),[S("awaddr","awaddr","hex"),S("wdata","wdata","hex"),S("wstrb","wstrb","hex"),S("ack","ack"),S("acks","acks","dec","top"),S("rdata","rdata","hex")])])
add(figures,case,ev,wd,total,"17b_status_reads.png","17b 0x30、0x34、0x38状态寄存器读回",[around(t,30_000,50_000,total) for t in status_centers],[
    ("250MHz AXI-Lite寄存器域",S("clk","clk","bin","top"),[S("araddr","araddr","hex"),S("arvalid","arvalid"),S("arready","arready"),S("rvalid","rvalid"),S("rdata","rdata","hex"),S("RX_READY_BLOCKS","RX_READY_BLOCKS","dec","dut"),S("RX_HEAD_SEQ","RX_HEAD_SEQ","dec","dut"),S("RX_DROPPED_FRAMES","RX_DROPPED_FRAMES","dec","dut")])])

EVIDENCE.mkdir(parents=True,exist_ok=True)
(EVIDENCE/"wave_manifest.json").write_text(json.dumps(figures,ensure_ascii=False,indent=2),encoding="utf-8")
print(f"WAVEFORM_V2_PASS figures={len(figures)}")
