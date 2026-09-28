"""Build seven self-contained local HTML GUIs, with VCD events and source snapshots."""
from pathlib import Path
import csv, hashlib, json, re
from summarize_local_wave_sessions import ROOT, OUT, CASES, norm, PURPOSE

def read_events(path):
    scopes, declarations, events, last = [], {}, {}, {}
    now = 0
    for raw in path.open(encoding='utf-8', errors='replace'):
        s = raw.strip()
        if s.startswith('$scope '): scopes.append(s.split()[2])
        elif s.startswith('$upscope'): scopes.pop()
        elif s.startswith('$var '):
            p = s.split(); declarations[norm('/'+'/'.join(scopes+[p[4]]))]=(p[3],int(p[2])); events.setdefault(p[3],[])
        elif s.startswith('#'): now=int(s[1:])
        elif s and s[0] in '01xXzZbBrR':
            if s[0] in 'bBrR':
                p=s[1:].split()
                if len(p)!=2: continue
                value,code=p
            else: value,code=s[0],s[1:]
            if code in events and last.get(code)!=value.lower():
                events[code].append([now,value.lower()]);last[code]=value.lower()
    return declarations,events

def modules_in(sources):
    modules={}
    for i,source in enumerate(sources):
        text=source['text']; pattern=r'\b(module|interface)\s+(\w+)\b'
        for m in re.finditer(pattern,text):
            if text[text.rfind('\n',0,m.start())+1:m.start()].strip().startswith('//'): continue
            finish=re.search(r'\bend(module|interface)\b',text[m.end():])
            stop=m.end()+finish.end() if finish else len(text)
            modules[m[2]]=(i,text[m.start():stop],text[:m.start()].count('\n'))
    return modules

def standard_module(name):
    return name.lower().startswith('xpm_') or bool(re.fullmatch(r'RTDS_FPGA_(?:\w*CDC|RESET_SYNC)', name))

def closing(text, start):
    depth=0
    for p in range(start,len(text)):
        if text[p]=='(': depth+=1
        elif text[p]==')':
            depth-=1
            if depth==0: return p
    raise ValueError('Unbalanced HDL connection/parameter expression')

def boundary_connections(modules, sources, case):
    dut_names={'1g':'RTDS_1G_PERIODIC_TX','tx':'fdma_aurora_brg_tx','rx_fifo':'RTDS_RX_FRAME_FIFO','ring':'RTDS_RX_BLOCK_WRITER','axi':'CONV_DMA','axi_tail':'CONV_DMA','regs':'INFO_EXCH'}
    # Connections are extracted from the parent DUT, not inferred from port names.
    info=modules.get(dut_names[case])
    if not info: return {}
    source,body,offset=info
    clean=re.sub(r'/\*.*?\*/|//[^\n]*',lambda m:re.sub(r'[^\n]',' ',m[0]),body,flags=re.S)
    result={}
    for module in (n for n in modules if standard_module(n)):
        for m in re.finditer(r'\b'+re.escape(module)+r'\b',clean):
            p=m.end()
            while p<len(clean) and clean[p].isspace(): p+=1
            if p<len(clean) and clean[p]=='#':
                p+=1
                while clean[p].isspace(): p+=1
                p=closing(clean,p)+1
            inst=re.match(r'\s*(\w+)\s*\(',clean[p:])
            if not inst: continue
            start=p+inst.end()-1; stop=closing(clean,start)
            for port in re.finditer(r'\.(\w+)\s*\(',clean[start+1:stop]):
                opening=start+1+port.end()-1; end=closing(clean,opening)
                expr=body[opening+1:end].strip()
                item={'instance':inst[1],'module':module,'port':port[1],'expression':expr,'source':source,'line':offset+body[:opening].count('\n')+1}
                for name in set(re.findall(r'\b[A-Za-z_]\w*\b',expr)):
                    result.setdefault(f'/tb_rtds_{case}/U_DUT/{name}',[]).append(item)
    return result

def build():
    template=(ROOT/'scripts/local_wave_viewer.html').read_text(encoding='utf-8')
    manifest=json.loads((OUT/'manifest.json').read_text(encoding='utf-8-sig'))
    report=[]
    for entry in manifest:
        case=entry['case']; folder=OUT/case
        hashes=json.loads((folder/'source_hashes.json').read_text(encoding='utf-8-sig'))
        sources=[]
        for s in hashes:
            p=Path(s['path']); content=p.read_bytes()
            assert hashlib.sha256(content).hexdigest()==s['sha256']
            sources.append(dict(s,text=content.decode('utf-8-sig',errors='replace')))
        lookup={s['path']:i for i,s in enumerate(sources)}
        mappings={r['signal']:r for r in csv.DictReader((folder/'signal_sources.csv').open(encoding='utf-8-sig'))}
        modules=modules_in(sources)
        instances={}
        for parent,(_,body,_) in modules.items():
            # Recognize known module names and skip balanced parameter overrides.
            for child in modules:
                for m in re.finditer(r'\b'+re.escape(child)+r'\b',body):
                    pos=m.end()
                    while pos<len(body) and body[pos].isspace(): pos+=1
                    if pos<len(body) and body[pos]=='#':
                        pos+=1
                        while pos<len(body) and body[pos].isspace(): pos+=1
                        if pos>=len(body) or body[pos]!='(': continue
                        depth=0
                        while pos<len(body):
                            if body[pos]=='(': depth+=1
                            elif body[pos]==')':
                                depth-=1
                                if depth==0: pos+=1;break
                            pos+=1
                    instance=re.match(r'\s*(\\?\w+)\s*\(',body[pos:])
                    if instance: instances.setdefault(instance[1].lstrip('\\'),set()).add(child)
        declarations,events=read_events(folder/f'{case}.vcd')
        connections=boundary_connections(modules,sources,case)
        event_keys={key:str(i) for i,key in enumerate(events)}
        compact_events={event_keys[k]:v for k,v in events.items()}
        signals=[]
        for row in csv.DictReader((folder/'signals.csv').open(encoding='utf-8-sig')):
            path=row['signal']; decl=declarations.get(path)
            sig={'path':path,'code':event_keys[decl[0]] if decl else None,'width':decl[1] if decl else 0,'core':row['group']=='core'}
            sig['standardInternal']=any(any(standard_module(m) for m in instances.get(scope.split('.')[-1],set())) for scope in path.split('/')[1:-1])
            sig['testbenchAlias']=path.startswith(f'/tb_rtds_{case}/bus/') and path.count('/')>3
            if path in connections: sig['connections']=connections[path]
            if path in mappings:
                m=mappings[path]; sig.update(source=lookup[m['source']],line=int(m['first_code_occurrence_line']) if m['first_code_occurrence_line'] else 1,lookup=m['lookup_name'])
            else:
                for scope in reversed(path.split('/')[1:-1]):
                    candidates=instances.get(scope.split('.')[-1],set())
                    if len(candidates)!=1: continue
                    module=next(iter(candidates));source,body,line_offset=modules[module]
                    name=path.split('/')[-1].split('.')[-1]
                    for line_number,line in enumerate(body.splitlines(),line_offset+1):
                        if re.search(r'(?<![\w$])'+re.escape(name)+r'(?![\w$])',line.split('//')[0]):
                            sig.update(source=source,line=line_number,lookup=name);break
                    if 'source' in sig: break
            if sig['core'] and 'source' not in sig:
                name=path.split('/')[-1]
                tb=next(i for i,s in enumerate(sources) if Path(s['path']).name==f'tb_rtds_{case}.sv')
                for line_number,line in enumerate(sources[tb]['text'].splitlines(),1):
                    if re.search(r'(?<![\w$])'+re.escape(name)+r'(?![\w$])',line.split('//')[0]):
                        sig.update(source=tb,line=line_number,lookup=name);break
            signals.append(sig)
        unit=re.fullmatch(r'(\d+)\s*(s|ms|us|ns|ps|fs)',entry['timescale'])
        tick_ns=int(unit[1])*{'s':1e9,'ms':1e6,'us':1e3,'ns':1,'ps':1e-3,'fs':1e-6}[unit[2]]
        data={'project':'RTDS','case':case,'guide':PURPOSE[case][1],'end':entry['end_time'],'tickNs':tick_ns,'signals':signals,'events':compact_events,'sources':sources}
        with (folder/'standard_module_connections.csv').open('w',encoding='utf-8-sig',newline='') as stream:
            writer=csv.DictWriter(stream,fieldnames=['parent_signal','instance','module','port','expression','source','line']);writer.writeheader()
            for sig in signals:
                for connection in sig.get('connections',[]):
                    writer.writerow(dict(connection,parent_signal=sig['path'],source=sources[connection['source']]['path']))
        encoded=json.dumps(data,ensure_ascii=False,separators=(',',':')).replace('<','\\u003c').replace('\u2028','\\u2028').replace('\u2029','\\u2029')
        target=folder/f'{case}_viewer.html'
        target.write_text(template.replace('__WAVE_DATA__',encoded),encoding='utf-8')
        missing_core=[s['path'] for s in signals if s['core'] and 'source' not in s]
        assert not missing_core,missing_core
        report.append({'case':case,'signals':len(signals),'default_signals':sum(not s['standardInternal'] and not s['testbenchAlias'] for s in signals),'standard_internal_signals':sum(s['standardInternal'] for s in signals),'parent_connection_signals':sum(bool(s.get('connections')) for s in signals),'mapped_sources':sum('source' in s for s in signals),'core_mapped':sum(s['core'] and 'source' in s for s in signals),'core_missing':missing_core,'html_bytes':target.stat().st_size,'vcd_events':sum(len(v) for v in events.values())})
    (OUT/'offline_viewer_manifest.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8-sig')
    print(json.dumps(report,ensure_ascii=False,indent=2))

if __name__=='__main__': build()
