from pathlib import Path
import json,shutil,hashlib,csv,re,datetime
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
RUN=ROOT/'verification_20261012/doc_wave_final'
OUT=ROOT/'evidence/local_wave_sessions/recovery_and_1g_20261012'
OUT.mkdir(parents=True,exist_ok=True)
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
completion=json.loads((RUN/'completion.json').read_text('utf-8'))
assert completion['completed'] and completion['runs']==15,completion
results=json.loads((RUN/'summary.json').read_text('utf-8'))
sources=json.loads((RUN/'source_hashes.json').read_text('utf-8'))
header=ROOT/'regression/sim_xdma_trythrough/rp_api.svh'
if header.exists():sources.append({'path':str(header.relative_to(ROOT)).replace('\\','/'),'sha256':H(header),'recorded':'package-time include snapshot'})
SEED=1417633351
info={
'ready_recovery':('TC-F11','DDR/PCIe/Aurora失效后无全局复位恢复','观察旧fdma_rbusy结束、tx_recovering隔离旧数据、三类恢复后32Byte新任务4拍且完成事件1次。'),
'recovery_cross_variants':('TC-F15','四种失效与六个传输位置组合','100次循环覆盖channel、PCIe、DDR、lane失效，读请求/读busy/R已返回/接受首拍/SOF后/EOF后六处边界；停用户时钟时不得提前启动。'),
'sync':('TC-M08','同源2µs事件及50µs GPIO','250MHz域每500拍翻转事件；GPIO12500拍一周期，高低各6250拍，每周期25次事件，复位清零。'),
'1g':('TC-M01','1G十组配置四拍发送及反压/断链','比较1～10号完整参数、首个合法配置锁定、4×32bit载荷、Byte6=F0、四拍REM3、反压保持与跳过、断链配置保持。'),
'byte1_1g':('TC-F09','真实adapter取Byte1并配置实际四拍1G','经真实INFO_EXCH/CONV_DMA/DDR模型/adapter将帧首Byte1交付实际1G，0/11不启动，首个合法ID锁定，后续ID不覆盖。')}
def meaning(path):
    n=path.split('/')[-1].lower()
    specific={'tx_recovering':'上一任务读返回/跨域事件清理；为1时不能启动新任务',
    'tx_active':'当前下行业务任务有效','tx_deliver_enable':'旧数据能否进入发送桥和Byte1提取',
    'tx_quiet_count':'满足旧busy结束和用户停止确认后的8拍安静计数',
    'tx_user_quiet_fdma':'用户域发送桥停止确认已同步回FDMA域',
    'fdma_rbusy':'CONV_DMA仍占用读事务；为0才释放旧读',
    'read_curr_st':'CONV_DMA读状态；R_DATA表示等待/接收R数据',
    'cfg_byte':'帧首实际接受的Byte1配置编号','cfg_valid':'每帧首读拍配置事件',
    'cfg_byte_valid':'每帧首读拍配置事件','configured':'首次合法配置跨域确认',
    'configured_id':'首次合法编号，后续不覆盖','period_tick':'用户域恢复的单拍周期事件',
    'tick_toggle_2us':'250MHz域每2µs翻转一次的源事件标志',
    'tick_2us':'250MHz域每2µs翻转一次的源事件标志','gpio_50us':'50µs GPIO，高低各25µs',
    'cpu_sync_50us':'50µs GPIO，高低各25µs','skipped_periods':'忙/反压时跳过的发送机会计数',
    'storage_ready':'存储接口实际可用；不同于业务错误收尾完成',
    'ddr_ready':'存储可用且旧错误事务不再阻塞新业务',
    'recovery_read_pending':'AR已接受、最后R尚未被业务侧接受',
    'recovery_read_abort':'旧读经历存储失效，尚需补齐错误R',
    'recovery_read_left':'尚未装入业务侧响应寄存器的读拍数',
    'recovery_rvalid':'后端已展示的R有效；反压时保持字段',
    'recovery_rresp':'后端保持的R响应码，0=OKAY、2=SLVERR',
    'recovery_rlast':'当前保持R是否最后一拍','done_event':'清软件命令忙的结束事件',
    'hold_r':'测试台阻塞DDR模型R返回','hold_b':'测试台阻塞DDR模型B返回',
    'tx_restart_pending':'正常结束清理时暂存的一条下一命令'}
    if n in specific:return specific[n]
    if 'clk' in n:return '所属模块/接口时钟，按完整层级区分时钟域'
    if 'reset' in n or 'rst' in n:return '复位或测试台存储复位控制，注意_n低有效'
    if n in ('pcie_up','pcie_link_up','channel_up','lane_up','link_up_fdma'):return '链路/就绪控制或同步汇总；失效触发旧任务停止'
    if n.endswith('ready') or n.endswith('rdy'):return '当前通道接受许可；必须与对应valid同拍判断'
    if n.endswith('valid'):return '当前通道有效；单独为1不表示已接受'
    if 'data' in n or n in ('gdata','tx_d'):return '数据载荷，按对应接口字节序阅读'
    if n.endswith('sof'):return '帧首标志，保持到当前拍握手'
    if n.endswith('eof') or n.endswith('last'):return '帧尾/突发末拍标志，结合valid/ready'
    if n.endswith('rem'):return '该拍有效字节数减一'
    if 'count' in n or 'frames' in n or 'beats' in n:return 'RTL或测试台计数，按路径区分实现与记分板'
    return '精确记录对象；含义见同目录sources中的同名声明/驱动/检查'

watch={'ready_recovery':['H/channel_up','H/pcie_up','H/ddr_reset_n','H/fdma_rbusy','H/U_ADAPTER/tx_recovering','H/U_ADAPTER/tx_user_quiet_fdma','H/done_event'],
'recovery_cross_variants':['H/channel_up','H/lane_up','H/pcie_up','H/ddr_reset_n','H/user_clock_enable','H/U_ADAPTER/tx_recovering','H/fdma_rbusy','iterations'],
'sync':['rst_n','tick_toggle_2us','cpu_sync_50us'],
'1g':['bus/rst_n','bus/cfg_byte','bus/configured','bus/configured_id','bus/tx_sof','bus/tx_eof','bus/tx_valid','bus/tx_ready','bus/skipped_periods','bus/channel_up'],
'byte1_1g':['H/cfg_byte','H/cfg_valid','H/configured','H/configured_id','H/tick_2us','H/gpio_50us','H/gsof','H/geof','H/gvalid','frames']}

def vcd_index(vcd,name,top):
    stack=[];variables=[];lines=[]
    with vcd.open('r',encoding='utf-8',errors='replace') as f:
        for line in f:
            lines.append(line)
            x=line.strip()
            if x.startswith('$scope'):stack.append(x.split()[2])
            elif x.startswith('$upscope'):stack.pop()
            elif x.startswith('$var'):
                m=re.match(r'\$var\s+(\w+)\s+(\d+)\s+(\S+)\s+(.+?)\s+\$end',x)
                if m:
                    leaf=m[4];path='/'+('/'.join(stack+[leaf.split(' ')[0]]))
                    variables.append({'path':path,'width':int(m[2]),'type':m[1],'vcd_id':m[3],'meaning':meaning(path)})
            elif '$enddefinitions' in x:break
        header=''.join(lines);m=re.search(r'\$timescale\s*(\d+)\s*(fs|ps|ns|us|ms|s)',header)
        assert m,header[:500];factor=int(m[1])*{'fs':1e-6,'ps':1e-3,'ns':1,'us':1e3,'ms':1e6,'s':1e9}[m[2]]
        keys={'/'+top+'/'+tail for tail in watch[name]}
        ids={v['vcd_id']:v['path'] for v in variables if v['path'] in keys}
        edges=[];values={};counts={};t=0
        for line in f:
            s=line.strip()
            if not s:continue
            if s[0]=='#':t=int(s[1:]);continue
            if s[0] in 'bBrR':
                ss=s[1:].split()
                if len(ss)!=2:continue
                value,idx=ss
            else:value,idx=s[0],s[1:]
            if idx in ids and values.get(idx)!=value:
                path=ids[idx];counts[path]=counts.get(path,0)+1
                if counts[path]<=100:edges.append({'time_ns':round(t*factor,6),'signal':path,'old':values.get(idx,''),'new':value})
                values[idx]=value
    return variables,edges,round(t*factor,6)

manifest=[];project_tcl=['set package [file dirname [file normalize [info script]]]']
for name,(cid,title,note) in info.items():
    runs=[x for x in results if x['case']==name]
    assert len(runs)==3,(name,runs)
    first=next(x for x in runs if x['seed']==SEED)
    folder=OUT/name;folder.mkdir(exist_ok=True)
    slug=name+'_seed_'+str(SEED);capture=RUN/(slug+'.capture')
    for src,dst in [(RUN/(slug+'.wdb'),folder/'trace.wdb'),(capture/'trace.vcd',folder/'trace.vcd'),(capture/'recommended.wcfg',folder/'recommended.wcfg'),(capture/'recorded_signals.txt',folder/'recorded_signals.txt')]:
        assert src.exists() and src.stat().st_size,src;shutil.copy2(src,dst)
    for e in runs:
        for suffix in ['.simulate.log','.console.log','.options','.tcl']:
            p=RUN/(name+'_seed_'+str(e['seed'])+suffix)
            if p.exists():shutil.copy2(p,folder/p.name)
    shutil.copy2(RUN/(name+'.elaborate.log'),folder/(name+'.elaborate.log'))
    # Self-contained snapshots retain include paths and every compiled source hash.
    for row in sources:
        p=ROOT/row['path'];assert H(p)==row['sha256'],'Source changed after capture: '+str(p)
        q=folder/'sources'/row['path'];q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
    for p in [ROOT/'RTDS_test_DDR4_64bit.srcs/sources_1/new/TOP.v',ROOT/'RTDS_test_DDR4_64bit.xpr']:
        q=folder/'sources'/p.relative_to(ROOT);q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
    (folder/'source_hashes.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2),'utf-8')
    variables,edges,duration=vcd_index(folder/'trace.vcd',name,first['top'])
    assert variables and duration>0,name
    for path,rows,fields in [(folder/'signals.csv',variables,['path','width','type','vcd_id','meaning']),
    (folder/'observation_events.csv',edges,['time_ns','signal','old','new'])]:
        with path.open('w',encoding='utf-8-sig',newline='') as f:
            writer=csv.DictWriter(f,fieldnames=fields);writer.writeheader();writer.writerows(rows)
    (folder/'signals.list').write_text('\n'.join(v['path'] for v in variables)+'\n','utf-8')
    # Default WCFG preserves exact paths; list them separately for easy import/review.
    from xml.etree import ElementTree as ET
    tree=ET.parse(folder/'recommended.wcfg');recommended=[]
    for obj in tree.getroot().iter():
        value=obj.get('path') or obj.get('name')
        if value and value.startswith('/') and value in {v['path'] for v in variables}:recommended.append(value)
    # Vivado writes wave_object path in xml attributes in 2020.2; fallback explicit watch list.
    if not recommended:recommended=[v['path'] for v in variables if any(v['path'].endswith('/'+tail) for tail in watch[name])]
    recommended=list(dict.fromkeys(recommended))
    (folder/'recommended_signals.list').write_text('\n'.join(recommended)+'\n','utf-8')
    guide=f'# {cid} {title}\n\n'+note+f'\n\n本次远程当前源码仿真，三种子：'+', '.join(str(x['seed'])+':'+x['status'] for x in runs)+f'。波形记录种子{SEED}，仿真全程{duration}ns，VCD信号{len(variables)}项。\n\n'
    guide+='1. 在资源管理器进入本目录，双击 `Open_'+name+'.cmd`。\n2. 等待Vivado打开 `project/wave_'+name+'.xpr`、`trace.wdb` 和 `recommended.wcfg`；这是已记录波形，不会重跑仿真。\n3. 在Wave窗口点击Zoom Fit查看全程，再按观察事件表选择时间段放大。输入框/光标时间单位为ns；数据总线右键Radix选Hexadecimal。\n4. `recommended_signals.list`为默认观察信号；`signals.csv`列出实际VCD记录的路径、位宽、编码与含义。WDB里需补信号时，在Scope选对应实例、Objects中选对象后右键Add to Wave Window。只显示已经记录的对象，不声称所有数组都被记录。\n5. 比对valid与ready同一上升沿，再查看该拍数据；状态变0或单独valid=1均不能替代握手计数。\n\n'
    guide+='## 手动打开\n\nVivado菜单File → Open Project，选择本目录project下的XPR；再在Tcl Console运行：\n\n```tcl\nopen_wave_database {'+str(folder/'trace.wdb').replace('\\','/')+'}\nopen_wave_config {'+str(folder/'recommended.wcfg').replace('\\','/')+'}\n```\n\n'
    guide+='## 定位文件\n\n`observation_events.csv`列出关键控制信号实际变化时间（每信号最多前100次，非完整事件计数）。从失效/复位边沿向后查看恢复状态，再看新任务帧；完整轨迹在WDB/VCD。匹配源码在`sources`，其哈希在`source_hashes.json`。\n'
    (folder/'README.md').write_text(guide,'utf-8')
    opening='''set here [file dirname [file normalize [info script]]]
open_project -read_only [file join $here project wave_CASE.xpr]
open_wave_database [file join $here trace.wdb]
open_wave_config [file join $here recommended.wcfg]
puts "SAVED_WAVE_OPENED=CASE (recorded evidence; no rerun)"
'''.replace('CASE',name)
    (folder/'open_wave.tcl').write_text(opening,'ascii')
    (folder/('Open_'+name+'.cmd')).write_text('@echo off\r\nset "RTDS_VIVADO=C:\\Xilinx\\Vivado\\2020.2\\bin\\vivado.bat"\r\nif exist "D:\\Xilinx_2020_2\\Vivado\\2020.2\\bin\\vivado.bat" set "RTDS_VIVADO=D:\\Xilinx_2020_2\\Vivado\\2020.2\\bin\\vivado.bat"\r\ncall "%RTDS_VIVADO%" -mode gui -source "%~dp0open_wave.tcl"\r\n','ascii')
    rel_sources=['sources/'+x['path'] for x in sources if x['path'].endswith(('.sv','.v'))]
    project_tcl+=['set here [file join $package '+name+']',
    'create_project -force wave_'+name+' [file join $here project] -part xcku040-ffva1156-2-i',
    'set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO} [current_project]',
    'set files {}']
    project_tcl+=['lappend files [file join $here {'+p+'}]' for p in rel_sources]
    project_tcl+=['add_files -fileset sim_1 -norecurse $files',
    'set_property top '+first['top']+' [get_filesets sim_1]',
    'set_property verilog_define {DDR4_SIM_RAM} [get_filesets sim_1]',
    'set_property include_dirs [list [file join $here sources regression recovery_phase2_20261011] [file join $here sources regression sim_xdma_trythrough]] [get_filesets sim_1]',
    'update_compile_order -fileset sim_1','close_project',
    'open_project -read_only [file join $here project wave_'+name+'.xpr]',
    'open_wave_database [file join $here trace.wdb]',
    'open_wave_config [file join $here recommended.wcfg]',
    'puts "PACKAGE_WAVE_OPEN_OK='+name+'"','close_sim','close_project']
    item={'case':name,'ids':[cid],'title':title,'status':'PASS' if all(x['status']=='PASS' for x in runs) else 'FAIL',
    'runs':runs,'wave_seed':SEED,'duration_ns':duration,'vcd_signals':len(variables),'recommended_signals':recommended,
    'folder':str(folder),'events':edges,'files':{x:H(folder/x) for x in ['trace.wdb','trace.vcd','recommended.wcfg','signals.csv','observation_events.csv']}}
    (folder/'capture_manifest.json').write_text(json.dumps(item,ensure_ascii=False,indent=2),'utf-8');manifest.append(item)
(OUT/'create_and_check_projects.tcl').write_text('\n'.join(project_tcl)+'\n','utf-8')
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),'utf-8')
(OUT/'summary.json').write_text(json.dumps({'date':'2026-10-12','root':str(ROOT),'verification':'verification_20261012/doc_wave_final','runs':results,'completion':completion},ensure_ascii=False,indent=2),'utf-8')
overview='# 远程当前恢复与四拍1G仿真证据 · 2026-10-12\n\n根目录：'+str(OUT)+'\n\n'
for x in manifest:overview+='- '+x['ids'][0]+' '+x['title']+'：'+x['status']+'，三种子；进入 `'+x['case']+'` 双击对应Open.cmd。WDB/VCD记录种子1417633351。\n'
overview+='\n每组包含Vivado项目、匹配源码、三种子日志、WDB/VCD、默认WCFG、完整信号列表、关键事件时间表和打开步骤。实际TOP连接核查与模块/行为模型仿真分开，不把本包称为完整TOP/GT/板级验证。\n'
(OUT/'README.md').write_text(overview,'utf-8')
(OUT/'index.html').write_text('<!doctype html><meta charset="utf-8"><title>RTDS 仿真证据 20261012</title><h1>恢复与四拍1G</h1><p>每组README包含Vivado操作步骤；Open.cmd在Windows资源管理器中运行。</p><ul>'+''.join('<li>'+x['ids'][0]+' '+x['title']+' '+x['status']+' <a href="'+x['case']+'/README.md">步骤</a> <a href="'+x['case']+'/signals.csv">信号表</a> <a href="'+x['case']+'/observation_events.csv">时间表</a></li>' for x in manifest)+'</ul>','utf-8')
print(json.dumps({'package':str(OUT),'cases':[(x['case'],x['status'],x['duration_ns'],x['vcd_signals']) for x in manifest]},ensure_ascii=False))
