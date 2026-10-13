from pathlib import Path
import json,csv,re,hashlib,shutil,datetime,bisect,html,xml.etree.ElementTree as ET,sys
sys.stdout.reconfigure(encoding='utf-8')
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
RUN=ROOT/'verification_20261012/post_timing_quick_20261012'
OLD=ROOT/'evidence/local_wave_sessions/recovery_and_1g_20261012'
OUT=Path('\\\\?\\'+str(ROOT/'evidence/local_wave_sessions/recovery_and_1g_20261012_post_timing_staging'))
OUT.mkdir(exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
results=json.loads((RUN/'summary.json').read_text('utf-8'))
sources_index=json.loads((RUN/'source_hashes.json').read_text('utf-8'))
completion=json.loads((RUN/'completion.json').read_text('utf-8'))
assert completion['completed'] and len(results)==60
INFO={
'ready_recovery':('TC-F11','三类失效后的旧读排空与新任务','先观察旧busy及隔离，再观察新任务数据；软件忙结束不能代替旧读结束。'),
'recovery_cross_variants':('TC-F15','四类失效×六个位置及停钟恢复','前24轮覆盖4×6，累计100轮；用户域没有停止确认时不得仅按等待拍数重启。'),
'sync':('TC-M08','250MHz同源2µs事件与50µs GPIO','toggle每2000ns翻转，GPIO每50000ns一周期；翻转间隔与高低完整周期分别测量。'),
'1g':('TC-M01','十组参数、四拍帧与反压断链','四个接受边沿组成一帧；Byte6为F0，四拍REM=3；停顿拍必须保持。'),
'byte1_1g':('TC-F09','DDR Byte1经真实adapter配置1G','0/11不启动，首个合法1～10锁定；后续帧继续提取Byte1但不覆盖已锁定参数。'),
'backend_read':('TC-F13','DDR读突发中断与已展示R保持','pending表示AR已接受而最后R未接受；left表示未装入保持寄存器的拍数。'),
'backend_write':('TC-F14','DDR写中断、剩余W排空与B保持','AW接受不代表写成功；故障后收完原W但不写存储，B响应才结束事务。'),
'ring':('TC-M02','上行拼接、尾字、队列与成功B响应','数据接受、成功响应、可读块、CPU确认分别观察；此组周期缩为200拍。'),
'backend_edge_recovery':('TC-F13/TC-F14补充','故障与R接受同拍：原始失败定位','保留失败判据与终止时刻；观察storage_ready下降和已展示响应装载先后。')}
MEAN={
'tx_recovering':'旧任务的DDR返回及跨域帧结束事件尚在清理；为1时普通新业务不能直接启动',
'tx_active':'下行业务任务有效，区别于CONV_DMA仍占用旧读',
'tx_deliver_enable':'当前读拍允许进入发送FIFO和Byte1提取；旧读排空时为0',
'tx_quiet_count':'已满足busy释放、用户停止确认和无旧完成事件后连续8拍的安静计数',
'tx_user_quiet_fdma':'用户域发送桥已停止/复位的确认同步回FDMA域',
'tx_frame_done_fdma':'用户域EOF实际接受后跨域返回的帧完成脉冲',
'tx_restart_pending':'正常收尾期间暂存的一条合法下一命令；不代表无限队列',
'fdma_rbusy':'CONV_DMA的读事务仍在途；不能只用0x20判断它已释放',
'fdma_rareq':'按帧提交DDR读请求，配合rbusy避免重复发起',
'fdma_rsize':'一次FDMA读的64bit拍数，每16Byte帧为2拍',
'fdma_raddr':'本帧卡端DDR字节地址，连续帧加16',
'fdma_rvalid':'DDR返回拍有效；与fdma_rready同拍才被接受',
'fdma_rready':'正常听发送桥许可；停止交付后仅在旧busy为1时继续排空',
'fdma_rdata':'64bit读载荷；adapter帧首接受时从[15:8]提取Byte1',
'cfg_byte':'帧首实际接受的Byte1编号，不保证该编号合法',
'cfg_valid':'帧首配置事件；仅是交付，不代表1G已完成跨域锁定',
'cfg_byte_valid':'配置编号输入事件；1G只锁定首个合法编号',
'configured':'首次合法配置已由用户域成组接收并确认',
'configured_id':'已锁定的首次合法1～10编号，后续输入不覆盖',
'cfg_user':'用户域锁存的完整48bit参数，{Vin32bit,duty16bit}',
'period_tick':'用户域检测到源toggle变化后形成的单拍发送机会',
'tick_toggle_2us':'源域每500个250MHz拍翻转；相邻翻转2µs，完整高低周期4µs',
'tick_2us':'与tick_toggle_2us相同的源事件连线',
'gpio_50us':'高低各6250个250MHz拍的GPIO，完整周期50µs',
'cpu_sync_50us':'GPIO源输出，与2µs事件共用时钟及复位',
'skipped_periods':'已配置、恢复等待结束后的忙/反压发送机会跳过计数；32bit自然回绕',
'storage_ready':'存储模型/MIG及其接口可用；不代表旧错误响应已经排空',
'ddr_ready':'存储可用且读写abort都已清除；新的业务可接受条件之一',
'ready':'按层级识别：B.ready为DDR业务可用，tx_ready为下游接受能力',
'recovery_read_pending':'AR已接受、最后R尚未由业务侧接受，持续记录原事务',
'recovery_read_abort':'读突发已遇存储失效，剩余未展示拍需补齐错误响应',
'recovery_read_left':'尚未装入R保持寄存器的拍数，9bit支持256；不是尚未由CPU接受的拍数',
'recovery_read_id':'原AR接受时保存的ID，错误填充也使用同一ID',
'recovery_rvalid':'后端已展示给上游的R拍有效，受反压时不能撤销或修改字段',
'recovery_rload':'后端将真实/补齐R装入保持寄存器的内部事件',
'recovery_rdata':'R保持寄存器数据；故障后新装入错误拍为0，已展示原拍保持',
'recovery_rid':'R保持寄存器ID，来自原ARID',
'recovery_rresp':'R保持响应码，0=OKAY，2=SLVERR；已展示OKAY不被故障改写',
'recovery_rlast':'保持的R是否原突发最后一拍；结合R接受才结束pending',
'recovery_write_pending':'AW已接受、B尚未由业务侧接受',
'recovery_write_abort':'已接受写突发经历存储失效，剩余W只接收/丢弃',
'recovery_write_left':'原突发尚未从上游接受的W拍数',
'recovery_write_id':'原AWID，最终错误B保持同一ID',
'recovery_bvalid':'已经展示B响应；受反压保持BID/BRESP，接受后结束pending',
'recovery_bid':'保持的B响应ID',
'recovery_bresp':'保持的写响应码；未展示的故障B为SLVERR，已经展示的OKAY保持',
'recovery_bload':'全数原W接受后将真实/错误B装入保持寄存器的事件',
'mem_wvalid':'实际转发至存储接口的W有效；写abort后禁止重放旧W',
'sim_ready_pipe':'SIM_RAM分支DDR就绪两级管线，故障有本域采样延迟',
'done_event':'软件命令结束事件，包含成功完成/拒绝/中止；不是对端执行完成确认',
'hold_r':'测试台阻塞模型R返回；不是DUT内部控制',
'hold_b':'测试台阻塞模型B返回；用于积压和超时/溢出场景',
'user_clock_enable':'测试台用户时钟运行使能；停钟验证恢复逻辑必须等待实际确认',
'user_half_period':'测试台用户域半周期，交替3.2/7.9ns，区别生产接口频率',
'tx_beats':'测试台已接受的10G拍数，只有valid&&ready时递增',
'tx_frames':'测试台实际接受EOF的帧数',
'cfg_pulses':'测试台帧首配置事件数',
'done_events':'测试台软件命令结束脉冲数',
'iterations':'测试台已完成的恢复循环数',
'head_addr':'当前可读队头卡端字节地址；确认前保持',
'head_len':'队头成功写入的有效Byte数；失败写和尾字高半不计入',
'head_seq':'队头逻辑发布序号，物理索引可回绕而逻辑序号递增',
'ready_blocks':'已发布、尚未CPU确认的块数0～8',
'dropped_frames':'历史名称；实际累计丢失的32bit字数，不是帧数',
'fdma_waccept':'FDMA写数据拍被接受，与最终B成功不是同一事件',
'fdma_wdone':'原写事务响应完成事件，需要同时看fdma_werror',
'fdma_werror':'本次写响应/地址错误；为1时writer不能增加成功长度',
'fdma_wstrb':'写字节使能，FF为双字8Byte，0F为奇数尾字4Byte',
'cpu_ack':'CPU读完一块后的确认脉冲，每次只释放一个队头',
'irq_clear':'清通知，不释放可读块，也不等同cpu_ack',
'half_valid':'writer保存了一个尚未配对的低32bit字',
'used_bytes':'当前块已获得成功写响应的有效Byte数',
'publish_seq':'下一个非空成功块的逻辑序号；空周期不消耗',
'tick':'writer周期到期事件，此组PERIOD_CYCLES=200，不是生产100ms',
'state':'writer事务状态，具体编码查匹配源码localparam',
'tx_sof':'当前有效拍为帧首，反压时随载荷保持',
'tx_eof':'当前有效拍为帧尾，与valid/ready共同判断帧完成',
'gsof':'1G帧首，四拍序号0', 'geof':'1G帧尾，四拍序号3',
'gvalid':'1G有效拍，与该实例tx_ready共同判定接受',
'gdata':'1G32bit载荷，先发字节位于[31:24]',
'grem':'1G当前拍有效Byte数减一，四拍固定3',
'tx_rem':'当前有效Byte数减一；1G四拍为3，10G两拍为7',
'read_curr_st':'CONV_DMA读状态，R_DATA表示仍等待/接受旧数据'}

def meaning(path):
    n=path.rsplit('/',1)[-1]
    if n in MEAN:return MEAN[n]
    if re.search(r'clk|clock',n,re.I):return '该层级时钟；按上升沿联合valid/ready判断接受，频率取匹配测试台'
    if re.search(r'reset|rst',n,re.I):return '复位控制；_n低有效；区分业务全局复位与DDR系统/用户接口复位'
    if n in ('pcie_up','channel_up','lane_up','link_up_fdma'):return 'PCIe/Aurora就绪激励或FDMA域同步汇总；下降触发任务中止'
    if re.search(r'(?:aw|ar)addr$',n,re.I):return 'AXI字节地址，地址只在本通道VALID&&READY上升沿被接受'
    if re.search(r'(?:aw|ar)len$',n,re.I):return 'AXI突发拍数减一，0表示1拍，255表示256拍'
    if re.search(r'(?:aw|ar)size$',n,re.I):return 'AXI每拍字节数log2，3为8Byte'
    if re.search(r'(?:aw|ar)burst$',n,re.I):return 'AXI突发类型，1=INCR'
    if re.search(r'(?:r|b)resp$',n,re.I):return 'AXI响应码，0=OKAY，2=SLVERR；受反压时保持'
    if re.search(r'(?:aw|ar|r|b)id$',n,re.I):return 'AXI事务ID；返回应对应原地址通道ID'
    if n.endswith(('last','LAST')):return '当前突发最后拍标志，只在VALID&&READY接受时推进结束'
    if n.endswith(('ready','READY','rdy')):return '本通道当前接受许可，与对应VALID同拍为1才握手'
    if n.endswith(('valid','VALID')):return '本通道拍/响应有效；反压时保持，单独为1不等于接受'
    if 'data' in n.lower():return '所属通道数据载荷；位宽及字节序按完整层级和匹配源码解释'
    return '辅助/内部对象；精确行为由同目录匹配源码解释，不能用短名推断为业务完成'

def parse_vcd(path):
    stack=[];sigs=[];ev={};last={};t=0;header=[];factor=None
    for raw in path.open(encoding='utf-8',errors='replace'):
        x=raw.strip()
        if factor is None:
            header.append(x)
            if x.startswith('$scope'):stack.append(x.split()[2])
            elif x.startswith('$upscope'):stack.pop()
            elif x.startswith('$var'):
                p=x.split();name=p[4];sigs.append({'path':'/'+'/'.join(stack+[name]),'width':int(p[2]),'code':p[3],'type':p[1]});ev.setdefault(p[3],[])
            elif '$enddefinitions' in x:
                m=re.search(r'\$timescale\s*(\d+)\s*(fs|ps|ns|us|ms|s)', ' '.join(header));assert m
                factor=int(m[1])*{'fs':1e-6,'ps':.001,'ns':1,'us':1000,'ms':1e6,'s':1e9}[m[2]]
            continue
        if not x:continue
        if x[0]=='#':t=int(x[1:]);continue
        if x[0] in 'bB':
            p=x[1:].split()
            if len(p)!=2:continue
            value,code=p
        elif x[0] in '01xXzZ':value,code=x[0],x[1:]
        else:continue
        value=value.lower()
        if code in ev and last.get(code)!=value:ev[code].append([t,value]);last[code]=value
    assert factor is not None and t<2**53
    return sigs,ev,factor,t

def models(sources):
    out={}
    for i,s in enumerate(sources):
        raw=s['text'];clean=re.sub(r'//[^\n]*|/\*.*?\*/',lambda m:re.sub(r'[^\n]',' ',m[0]),raw,flags=re.S)
        for m in re.finditer(r'\b(module|interface)\s+(\w+)\b',clean):
            end=re.search(r'\bend(module|interface)\b',clean[m.end():]);stop=m.end()+end.end() if end else len(raw)
            out[m[2]]=(i,raw[m.start():stop],clean[m.start():stop],raw[:m.start()].count('\n'))
    return out

def closeparen(s,k):
    level=0
    for j in range(k,len(s)):
        if s[j]=='(':level+=1
        elif s[j]==')':
            level-=1
            if not level:return j
    raise ValueError('Unbalanced static connection')

def instances(mod):
    out={};external={'xpm_cdc_single','xpm_cdc_gray','xpm_cdc_handshake','xpm_cdc_async_rst','xpm_fifo_async'}
    for parent,(i,raw,s,off) in mod.items():
        children={}
        for child in set(mod)|external:
            for m in re.finditer(r'\b'+re.escape(child)+r'\b',s):
                p=m.end()
                while p<len(s) and s[p].isspace():p+=1
                if p<len(s) and s[p]=='#':
                    p+=1
                    while p<len(s) and s[p].isspace():p+=1
                    if p>=len(s) or s[p]!='(':continue
                    p=closeparen(s,p)+1
                im=re.match(r'\s*(\w+)\s*\(',s[p:])
                if not im:continue
                a=p+im.end()-1;b=closeparen(s,a);cons=[]
                for pm in re.finditer(r'\.(\w+)\s*\(',s[a+1:b]):
                    op=a+1+pm.end()-1;end=closeparen(s,op)
                    cons.append({'instance':im[1],'module':child,'port':pm[1],'expression':raw[op+1:end].strip(),'source':i,'line':off+raw[:op].count('\n')+1})
                children[im[1]]=(child,cons)
        out[parent]=children
    return out

def value_at(events,t,previous=False):
    i=bisect.bisect_left(events,[t]) if previous else bisect.bisect_right(events,[t,chr(0x10ffff)])
    return events[i-1][1] if i else 'x'

def readable(v):
    return '0x'+format(int(v,2),'X') if re.fullmatch('[01]+',v) and len(v)>1 else v

def transactions(name,top,sigs,events,factor):
    bypath={s['path']:s for s in sigs};root='/'+top+'/'
    if name.startswith('backend_'):
        pre=root+('T/B/' if name!='backend_edge_recovery' else 'B/');clock=root+('T/clk' if name!='backend_edge_recovery' else 'clk')
        configs=[('AR',clock,pre+'arvalid',pre+'arready',['araddr','arlen','arid']),('R',clock,pre+'rvalid',pre+'rready',['rdata','rid','rresp','rlast']),('AW',clock,pre+'awvalid',pre+'awready',['awaddr','awlen','awid']),('W',clock,pre+'wvalid',pre+'wready',['wdata','wstrb','wlast']),('B',clock,pre+'bvalid',pre+'bready',['bid','bresp'])]
    elif name=='1g':
        pre=root+'bus/';configs=[('1G',root+'user_clk',pre+'tx_valid',pre+'tx_ready',['tx_data','tx_rem','tx_sof','tx_eof'])]
    elif name=='sync':return {}
    elif name=='ring':
        pre=root+'bus/';configs=[('RX字',root+'clk',pre+'frame_valid',pre+'frame_ready',['frame_data']),('写接受',root+'clk',pre+'fdma_wvalid',pre+'fdma_waccept',['fdma_wdata','fdma_wstrb','fdma_waddr'])]
    else:
        pre=root+'H/';configs=[('FDMA读',pre+'clk',pre+'fdma_rvalid',pre+'fdma_rready',['fdma_rdata','fdma_raddr']),('10G',pre+'uclk',pre+'tx_valid',pre+'tx_ready',['tx_data','tx_rem','tx_sof','tx_eof'])]
        if name=='byte1_1g':configs.append(('1G',pre+'gclk',pre+'gvalid',None,['gdata','grem','gsof','geof']))
    result={}
    for label,clock,valid,ready,fields in configs:
        if any(p not in bypath for p in [clock,valid]+([ready] if ready else [])):continue
        ce=events[bypath[clock]['code']];ve=events[bypath[valid]['code']];revs=events[bypath[ready]['code']] if ready else None
        rows=[];n=0
        for t,v in ce:
            if v!='1' or value_at(ve,t,True)!='1' or (revs is not None and value_at(revs,t,True)!='1'):continue
            n+=1
            row={'time_ns':round(t*factor,6),'handshake':n}
            for f in fields:
                q=bypath.get(pre+f)
                if q:row[f]=readable(value_at(events[q['code']],t,True))
            if n<=40:rows.append(row)
        result[label]={'count':n,'first_accepts':rows,'sampling':'VCD clock rising edge with values immediately before the timestamp; testbench assertions are authoritative for delta-cycle semantics'}
    return result

template=(Path(__file__).parent/'viewer.html').read_text('utf-8')
source_text=[]
for row in sources_index:
    p=RUN/'sources'/row['path'];assert sha(p)==row['sha256']
    if p.suffix in ('.v','.sv','.svh'):source_text.append({'path':row['path'],'text':p.read_text('utf-8-sig',errors='replace'),'sha256':row['sha256']})
mod=models(source_text);inst=instances(mod)
manifest=[];changes=[];check_tcl=['set package [file dirname [file normalize [info script]]]']
for name,(cid,title,note) in INFO.items():
    runs=[r for r in results if r['case']==name];assert len(runs)==3,name
    seed=1417633351;first=next(r for r in runs if r['seed']==seed)
    folder=OUT/name;folder.mkdir(exist_ok=True);slug=name+'_seed_'+str(seed);capture=RUN/(slug+'.capture')
    if not capture.exists():
        print('Capture not available yet:',name);continue
    for src,dst in [(RUN/(slug+'.wdb'),folder/'trace.wdb'),(capture/'trace.vcd',folder/'trace.vcd'),(capture/'recommended.wcfg',folder/'recommended.wcfg'),(capture/'recorded_signals.txt',folder/'recorded_signals.txt')]:
        assert src.exists() and src.stat().st_size,src;shutil.copy2(src,dst)
    for r in runs:
        for suffix in ('.simulate.log','.console.log','.options','.tcl'):
            p=RUN/(name+'_seed_'+str(r['seed'])+suffix)
            if p.exists():shutil.copy2(p,folder/p.name)
    if (RUN/(name+'.elaborate.log')).exists():shutil.copy2(RUN/(name+'.elaborate.log'),folder/(name+'.elaborate.log'))
    if name=='backend_edge_recovery':shutil.copy2(RUN/(slug+'.diagnostic.simulate.log'),folder/'diagnostic_capture.simulate.log')
    else:
        for suffix in ['.record.options','.record.simulate.log','.record.console.log']:
            shutil.copy2(RUN/(slug+suffix),folder/(slug+suffix))
    shutil.copytree(RUN/'sources',folder/'sources',dirs_exist_ok=True)
    (folder/'source_hashes.json').write_text(json.dumps(sources_index,ensure_ascii=False,indent=2),'utf-8')
    sigs,ev,factor,end=parse_vcd(folder/'trace.vcd');top=first['top'];duration=round(end*factor,6)
    recommended=[];wcfg=ET.parse(folder/'recommended.wcfg')
    for e in wcfg.getroot().iter():
        if e.tag=='db_ref':e.set('path','trace.wdb')
        p=e.get('fp_name') or e.get('path') or e.get('name')
        if p and p.startswith('/'):recommended.append(p)
    wcfg.write(folder/'recommended.wcfg',encoding='utf-8',xml_declaration=True)
    recommended=list(dict.fromkeys(recommended));wcfg_paths=list(recommended);paths={s['path'] for s in sigs};recommended=[p for p in recommended if p in paths]
    assert recommended,name
    signals=[];connections=[]
    for s in sigs:
        path=s['path'];parts=path.split('/')[1:];parent=top;standard=False;links=[];scopeparts=[parts[0]]
        for scope in parts[1:-1]:
            child=inst.get(parent,{}).get(scope)
            if child:
                parent,cons=child;standard|=parent.startswith('xpm_') or bool(re.fullmatch('RTDS_FPGA_(?:CFG_CDC|COUNT_CDC|RESET_SYNC)',parent))
            scopeparts.append(scope)
        if parent in mod:
            si,raw,clean,off=mod[parent];lookup=parts[-1].split('[')[0]
            m=re.search(r'\b'+re.escape(lookup)+r'\b',clean)
            if m:s.update(source=si,line=off+clean[:m.start()].count('\n')+1,lookup=lookup)
            for child,(ctype,cons) in inst.get(parent,{}).items():
                if ctype.startswith(('xpm_','RTDS_FPGA_')):
                    for c in cons:
                        if re.search(r'\b'+re.escape(lookup)+r'\b',c['expression']):links.append(c)
        s.update(meaning=meaning(path),standardInternal=standard,testbenchAlias='clocking' in path.lower() or any(x.endswith('_cb') for x in parts),core=path in recommended)
        if links:s['connections']=links;connections.extend({'parent_signal':path,**c} for c in links)
        signals.append(s)
    # Preserve complete inventory/events; default business view focuses on the recommended rows.
    data={'project':'RTDS · 时序修复后RTL证据','case':name,'guide':note+' 本包是RTL功能记录，时序通过另见实现报告；源码跳转为静态定位，不是执行断点。','end':end,'tickNs':factor,'signals':signals,'events':ev,'sources':source_text}
    encoded=json.dumps(data,ensure_ascii=False,separators=(',',':')).replace('<','\\u003c').replace('\u2028','\\u2028').replace('\u2029','\\u2029')
    adapted=template.replace("(group==='business'&&!sig.standardInternal&&!sig.testbenchAlias)","(group==='business'&&sig.core)")
    (folder/'viewer.html').write_text(adapted.replace('__WAVE_DATA__',encoded),'utf-8')
    rows=[]
    for s in signals:rows.append({'path':s['path'],'width':s['width'],'type':s['type'],'vcd_id':s['code'],'meaning':s['meaning'],'recommended':s['core'],'source':source_text[s['source']]['path'] if 'source' in s else '', 'line':s.get('line',''),'source_mapping':'static first lexical occurrence' if 'source' in s else 'unresolved'})
    with (folder/'signals.csv').open('w',encoding='utf-8-sig',newline='') as f:w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
    (folder/'signals.list').write_text('\n'.join(s['path'] for s in signals)+'\n','utf-8')
    (folder/'recommended_signals.list').write_text('\n'.join(recommended)+'\n','utf-8')
    (folder/'wcfg_signals.list').write_text('\n'.join(wcfg_paths)+'\n','utf-8')
    (folder/'wcfg_not_in_vcd.list').write_text('\n'.join(p for p in wcfg_paths if p not in paths)+'\n','utf-8')
    with (folder/'standard_module_connections.csv').open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=['parent_signal','instance','module','port','expression','source','line']);w.writeheader();w.writerows(connections)
    transitions=[]
    watched=[s for s in signals if s['core'] and s['width']<=32 and not re.search('clk|clock|data',s['path'].rsplit('/',1)[-1],re.I)]
    if name=='backend_edge_recovery':
        watched+= [s for s in signals if not s['core'] and s['path'].rsplit('/',1)[-1] in ['recovery_read_fault','recovery_rslot','recovery_read_id','recovery_write_id']]
    for s in watched:
        prev=''
        for t,v in ev[s['code']][:120]:
            transitions.append({'time_ns':round(t*factor,6),'signal':s['path'],'old':readable(prev),'new':readable(v)});prev=v
    transitions.sort(key=lambda x:x['time_ns'])
    with (folder/'observation_events.csv').open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=['time_ns','signal','old','new']);w.writeheader();w.writerows(transitions)
    tx=transactions(name,top,signals,ev,factor)
    (folder/'transactions.json').write_text(json.dumps(tx,ensure_ascii=False,indent=2),'utf-8')
    comparison={'case':name,'old_package_exists':(OLD/name).exists(),'new_duration_ns':duration}
    if (OLD/name/'trace.vcd').exists():
        osigs,oe,of,ot=parse_vcd(OLD/name/'trace.vcd');om={s['path']:s for s in osigs};comparison['old_duration_ns']=round(ot*of,6)
        comp=[]
        for path in recommended:
            if path not in om:continue
            new=next(s for s in sigs if s['path']==path)
            a=[(round(t*of,6),v) for t,v in oe[om[path]['code']]];b=[(round(t*factor,6),v) for t,v in ev[new['code']]]
            comp.append({'path':path,'same_events':a==b,'old_changes':len(a),'new_changes':len(b)})
        comparison['recommended_signal_comparison']=comp
        core=[]
        for rel in ['rtl/ddr4/rtds_ddr4_backend.sv','RTDS_test_DDR4_64bit.srcs/sources_1/new/pcie_fdma_aurora_brg_adapter.v','rtl/rtds_1g_periodic_tx.v']:
            old=OLD/name/'sources'/rel;new=RUN/'sources'/rel
            if old.exists():
                tokens=lambda p:re.sub(r'//[^\n]*|/\*.*?\*/','',p.read_text('utf-8-sig'),flags=re.S).split()
                core.append({'path':rel,'same_file_sha':sha(old)==sha(new),'same_noncomment_tokens':tokens(old)==tokens(new)})
        comparison['core_source_comparison']=core
        del oe
    (folder/'previous_capture_comparison.json').write_text(json.dumps(comparison,ensure_ascii=False,indent=2),'utf-8');changes.append(comparison)
    status='PASS' if all(r['status']=='PASS' for r in runs) else 'FAIL'
    item={'case':name,'top':top,'ids':cid.split('/'),'title':title,'guide':note,'status':status,'runs':runs,'wave_seed':seed,'duration_ns':duration,'vcd_signals':len(sigs),'recommended_signals':recommended,'events':transitions,'transactions':tx,'comparison':comparison,'folder':str(OLD/name),'files':{x:sha(folder/x) for x in ['trace.wdb','trace.vcd','recommended.wcfg','viewer.html','signals.csv','transactions.json']}}
    (folder/'capture_manifest.json').write_text(json.dumps(item,ensure_ascii=False,indent=2),'utf-8');manifest.append(item)
    opening='set here [file dirname [file normalize [info script]]]\nopen_project -read_only [file join $here project wave_'+name+'.xpr]\nopen_wave_database [file join $here trace.wdb]\nopen_wave_config [file join $here recommended.wcfg]\nputs "SAVED_POST_TIMING_WAVE_OPENED='+name+'"\n'
    (folder/'open_wave.tcl').write_text(opening,'ascii')
    (folder/('Open_'+name+'.cmd')).write_text('@echo off\r\ncall "C:\\Xilinx\\Vivado\\2020.2\\bin\\vivado.bat" -mode gui -source "%~dp0open_wave.tcl"\r\n','ascii')
    (folder/'Open_Viewer.cmd').write_text('@echo off\r\nstart "" "%~dp0viewer.html"\r\n','ascii')
    guide=f'# {cid} {title}\n\n本次时序修复后当前源码快照；种子{seed}；结束{duration}ns；实际VCD信号{len(sigs)}项；三种子结果{status}。\n\n'+note+'\n\n'
    guide+='打开：双击Open_'+name+'.cmd加载已记录WDB/WCFG；不会重跑仿真。双击Open_Viewer.cmd打开离线三窗格HTML。默认“业务”显示recommended信号，“全部”恢复VCD所有记录对象。源码跳转是静态首个标识符，标准模块连接记录保留真实表达式；未解析动态/生成层级明确为空。\n\n'
    guide+='文件：signals.csv为路径/位宽/含义，recommended_signals.list为默认信号，observation_events.csv为每重点信号前120个变化，transactions.json为基于记录边沿的前40个接受拍及全程计数，source_hashes.json绑定冻结编译源码。非打包数组或动态任务变量可能不在VCD；有效握手及判据仍以测试台检查日志为最终依据。\n\n'
    guide+='完整设计过程、变量、阶段分析、实测定位时间和历史对照见根目录《RTDS_时序修复后_快速回归与典型波形详解_20261012.docx》。\n'
    (folder/'README.md').write_text(guide,'utf-8')
    files=[x['path'] for x in sources_index if x['compiled'] and x['path'].endswith(('.v','.sv'))]
    check_tcl+=['set here [file join $package '+name+']','create_project -force wave_'+name+' [file join $here project] -part xcku040-ffva1156-2-i','set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO} [current_project]','set files {}']
    check_tcl+=['lappend files [file join $here sources {'+x+'}]' for x in files]
    check_tcl+=['add_files -fileset sim_1 -norecurse $files','set_property top '+top+' [get_filesets sim_1]','set_property verilog_define {DDR4_SIM_RAM} [get_filesets sim_1]','set_property include_dirs [list [file join $here sources regression recovery_phase2_20261011] [file join $here sources regression sim_xdma_trythrough]] [get_filesets sim_1]','update_compile_order -fileset sim_1','close_project','open_project -read_only [file join $here project wave_'+name+'.xpr]','open_wave_database [file join $here trace.wdb]','open_wave_config [file join $here recommended.wcfg]','puts "POST_TIMING_WAVE_OPEN_OK='+name+'"','close_sim','close_project']
    print('PACKAGED',name,status,'signals',len(signals),'duration_ns',duration,flush=True)
    del ev,data,encoded,signals
assert len(manifest)==9,'Expected original five + read/write/ring + diagnostic failed edge'
check_tcl+=['puts "ALL_SAVED_WAVES_OPENED=9"','exit']
(OUT/'create_and_check_projects.tcl').write_text('\n'.join(check_tcl)+'\n','utf-8')
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),'utf-8')
(OUT/'summary.json').write_text(json.dumps({'date':'2026-10-12','phase':'post timing fix','runs':results,'completion':completion,'wave_seed':1417633351},ensure_ascii=False,indent=2),'utf-8')
(OUT/'previous_package_comparison.json').write_text(json.dumps(changes,ensure_ascii=False,indent=2),'utf-8')
shutil.copy2(RUN/'baseline.json',OUT/'baseline.json')
shutil.copy2(RUN/'source_hashes.json',OUT/'source_hashes.json')
shutil.copytree(RUN/'sources',OUT/'compiled_sources',dirs_exist_ok=True)
logs=OUT/'quick_regression_logs';logs.mkdir(exist_ok=True)
for p in RUN.iterdir():
    if p.is_file() and p.suffix in ('.log','.json','.options','.tcl'):shutil.copy2(p,logs/p.name)
(OUT/'index.html').write_text('<!doctype html><meta charset="utf-8"><title>RTDS 时序修复后仿真证据</title><h1>RTDS 当前源码快速回归与典型波形</h1><p>RTL功能结果与实现时序结果分别记录。完整报告、旧包备份和源码哈希见README。</p><ul>'+''.join('<li>'+html.escape(x['case']+' '+x['title']+' '+x['status'])+' <a href="'+x['case']+'/viewer.html">波形</a> <a href="'+x['case']+'/README.md">说明</a> <a href="'+x['case']+'/signals.csv">信号表</a></li>' for x in manifest)+'</ul>','utf-8')
print('POST_TIMING_PACKAGE_STAGED',flush=True)
