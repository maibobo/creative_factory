from pathlib import Path
from bisect import bisect_right
import re
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

root = Path(r'C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev')
out = root / 'docs' / 'sync_2us_50us_waveforms'

def load_vcd(path, names):
    ids = {}
    selected = {}
    scopes = []
    scale_ns = 0.001
    in_header = True
    time_ns = 0.0
    with path.open('r', encoding='utf-8', errors='replace') as f:
        for raw in f:
            s = raw.strip()
            if in_header:
                if s.startswith('$timescale'):
                    m = re.search(r'(\d+)\s*(fs|ps|ns|us)', s)
                    if m:
                        scale_ns = int(m.group(1))*{'fs':1e-6,'ps':1e-3,'ns':1,'us':1000}[m.group(2)]
                elif s.startswith('$scope'):
                    scopes.append(s.split()[2])
                elif s.startswith('$upscope'):
                    scopes.pop()
                elif s.startswith('$var'):
                    parts = s.split()
                    if len(parts) >= 6:
                        ident, signal = parts[3], parts[4]
                        full = '.'.join(scopes+[signal])
                        ids.setdefault(ident, []).append(full)
                        if full in names:
                            selected[full] = {'id':ident,'width':int(parts[2]),'events':[]}
                elif s.startswith('$enddefinitions'):
                    in_header = False
                continue
            if s.startswith('#'):
                time_ns = int(s[1:])*scale_ns
            elif s and s[0] in '01xXzZ':
                ident, value = s[1:], s[0].lower()
                for full in ids.get(ident,[]):
                    if full in selected:
                        selected[full]['events'].append((time_ns,value))
            elif s and s[0] in 'bB':
                parts=s.split()
                if len(parts)==2:
                    value,ident=parts[0][1:].lower(),parts[1]
                    for full in ids.get(ident,[]):
                        if full in selected:
                            selected[full]['events'].append((time_ns,value))
    missing=set(names)-set(selected)
    if missing:
        available='\n'.join(sorted(full for paths in ids.values() for full in paths if any(n.split('.')[-1] in full for n in names)))
        raise RuntimeError(f'{path.name}: missing {sorted(missing)}; candidates:\n{available[:3000]}')
    for info in selected.values():
        assert info['events'], f'no events for {info}'
    return selected

def signal(data,name):
    return data[name]['events']

def value_at(events,t):
    ts=[x[0] for x in events]
    i=bisect_right(ts,t)-1
    return events[i][1] if i>=0 else 'x'

def intervals(events,start,end):
    times=[x[0] for x in events]
    i=max(0,bisect_right(times,start)-1)
    value=events[i][1] if events[i][0]<=start else 'x'
    pos=start
    while i+1<len(events) and events[i+1][0]<end:
        nxt=events[i+1][0]
        if nxt>pos:
            yield pos,nxt,value
        i+=1
        value=events[i][1]
        pos=max(nxt,start)
    if pos<end:
        yield pos,end,value

def hex_value(value,width):
    if not value or any(c not in '01' for c in value):
        return 'X'
    return f'0x{int(value,2):0{max(1,(width+3)//4)}X}'

def render(path,data,start,end,lanes,title,marks=None):
    fig,axes=plt.subplots(len(lanes),1,figsize=(15,max(4.0,1.15*len(lanes)+1.2)),sharex=True)
    if len(lanes)==1: axes=[axes]
    fig.patch.set_facecolor('white')
    fig.suptitle(title,fontsize=14,fontweight='bold')
    for ax,(label,name) in zip(axes,lanes):
        info=data[name]
        ax.set_xlim(start,end)
        ax.set_ylim(-0.05,1.05)
        ax.set_yticks([])
        ax.set_ylabel(label,rotation=0,labelpad=75,ha='right',va='center',fontsize=9)
        ax.grid(axis='x',color='#d7dce3',linewidth=.6)
        ax.spines[['top','right','left']].set_visible(False)
        if info['width']==1:
            xs=[start]
            ys=[0.75 if value_at(info['events'],start)=='1' else 0.15]
            for t,v in info['events']:
                if start<t<end:
                    xs.append(t);ys.append(0.75 if v=='1' else 0.15)
            xs.append(end);ys.append(ys[-1])
            ax.step(xs,ys,where='post',color='#1763a6',linewidth=1.5)
        else:
            for a,b,v in intervals(info['events'],start,end):
                color='#dbeafe' if all(c in '01' for c in v) else '#f2f2f2'
                ax.add_patch(Rectangle((a,.22),max(b-a,0.001),.55,facecolor=color,edgecolor='#6b9bd3',linewidth=.6))
                if (b-a) > (end-start)*.055:
                    ax.text((a+b)/2,.5,hex_value(v,info['width']),ha='center',va='center',fontsize=8,clip_on=True)
        if marks:
            for t in marks:
                if start<=t<=end: ax.axvline(t,color='#eb7f33',linewidth=.8,alpha=.55)
    axes[-1].set_xlabel('Time (ns)')
    fig.tight_layout(rect=[0,0,1,.96])
    fig.savefig(path,dpi=160,facecolor='white')
    plt.close(fig)
    assert path.stat().st_size>10000, f'blank/invalid plot: {path}'

tb=load_vcd(out/'timebase.vcd',[
    'tb_rtds_sync.clk_250m',
    'tb_rtds_sync.cpu_sync_50us',
    'tb_rtds_sync.tick_toggle_2us',
    'tb_rtds_sync.dut.count_2us',
])
gpio=signal(tb,'tb_rtds_sync.cpu_sync_50us')
ticks=signal(tb,'tb_rtds_sync.tick_toggle_2us')
rise=next(t for t,v in gpio if v=='1')
tick_marks=[t for t,v in ticks if rise<=t<rise+50000]
assert len(tick_marks)==25, f'expected 25 source events, got {len(tick_marks)}'
render(out/'timebase_overview.png',tb,max(0,rise-50),rise+52000,[
    ('CPU GPIO 50 us','tb_rtds_sync.cpu_sync_50us'),
    ('2 us event toggle','tb_rtds_sync.tick_toggle_2us'),
], 'Shared 250 MHz timebase: 25 events in each 50 us cycle',tick_marks)
render(out/'timebase_zoom.png',tb,max(0,rise-20),rise+6150,[
    ('CPU GPIO','tb_rtds_sync.cpu_sync_50us'),
    ('2 us toggle','tb_rtds_sync.tick_toggle_2us'),
], 'GPIO rising edge aligns with the first 2 us source event',tick_marks)

g=load_vcd(out/'one_g.vcd',[
    'tb_rtds_1g.user_clk','tb_rtds_1g.tick_toggle_2us',
    'tb_rtds_1g.bus.tx_ready','tb_rtds_1g.bus.tx_valid',
    'tb_rtds_1g.bus.tx_sof','tb_rtds_1g.bus.tx_eof',
    'tb_rtds_1g.bus.tx_rem','tb_rtds_1g.bus.tx_data',
    'tb_rtds_1g.U_DUT.period_tick','tb_rtds_1g.U_DUT.skipped_periods',
])
sof=signal(g,'tb_rtds_1g.bus.tx_sof')
first_sof=next(t for t,v in sof if v=='1')
render(out/'one_g_frame.png',g,first_sof-90,first_sof+230,[
    ('1G user_clk','tb_rtds_1g.user_clk'),
    ('2 us event','tb_rtds_1g.U_DUT.period_tick'),
    ('tx_ready','tb_rtds_1g.bus.tx_ready'),
    ('tx_valid','tb_rtds_1g.bus.tx_valid'),
    ('SOF','tb_rtds_1g.bus.tx_sof'),
    ('EOF','tb_rtds_1g.bus.tx_eof'),
    ('REM','tb_rtds_1g.bus.tx_rem'),
    ('DATA','tb_rtds_1g.bus.tx_data'),
], 'Aurora 1G: four 32-bit beats, Byte6 = F0', [first_sof])
skip=signal(g,'tb_rtds_1g.U_DUT.skipped_periods')
skip_change=next(t for t,v in skip if all(c in '01' for c in v) and int(v,2)>0)
render(out/'one_g_backpressure.png',g,skip_change-1700,skip_change+2600,[
    ('2 us event','tb_rtds_1g.U_DUT.period_tick'),
    ('tx_ready','tb_rtds_1g.bus.tx_ready'),
    ('tx_valid','tb_rtds_1g.bus.tx_valid'),
    ('SOF','tb_rtds_1g.bus.tx_sof'),
    ('EOF','tb_rtds_1g.bus.tx_eof'),
    ('DATA','tb_rtds_1g.bus.tx_data'),
    ('skipped','tb_rtds_1g.U_DUT.skipped_periods'),
], 'Backpressure: hold in-flight data, skip later events', [skip_change])
print('RENDER_OK figures=4 first_sof_ns=',first_sof,'first_skip_ns=',skip_change)
