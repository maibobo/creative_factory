"""Decode saved CSV only; never open hardware or issue a transfer."""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PREFIX = 'u_pcie/U_PCIE_LINK_DEBUG/'


def read_rows(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f)
        next(reader)  # Vivado radix description, not a sample.
        return list(reader)


def field(value, high, low):
    return (value >> low) & ((1 << (high-low+1))-1)


result = {}
for path in sorted((ROOT/'captures').glob('*.csv')):
    rows = read_rows(path)
    trigger = [int(r['Sample in Buffer']) for r in rows if r['TRIGGER'] == '1']
    item = {'file': path.name, 'samples': len(rows), 'trigger_samples': trigger}
    if 'native' in path.name:
        decoded = []
        for r in rows:
            v = int(r[PREFIX+'ila_axi[215:0]'], 16)
            decoded.append(dict(sample=int(r['Sample in Buffer']),
                aw=field(v,1,0)==3, w=field(v,3,2)==3,
                b=field(v,5,4)==3, ar=field(v,7,6)==3, r=field(v,9,8)==3,
                bresp=field(v,11,10), rresp=field(v,13,12),
                wlast=field(v,14,14), rlast=field(v,15,15), strb=field(v,23,16),
                awaddr=field(v,55,24), araddr=field(v,87,56),
                wdata=field(v,151,88), rdata=field(v,215,152)))
        events = {k:[d for d in decoded if d[k]] for k in ('aw','w','b','ar','r')}
        item['handshake_counts'] = {k:len(v) for k,v in events.items()}
        item['events'] = events
        item['all_error_probes_zero'] = all(int(r[PREFIX+'ila_errors[8:0]'],16)==0 for r in rows)
        assert item['all_error_probes_zero']
        if events['aw']:
            assert len(events['aw'])==1 and events['aw'][0]['awaddr']==0x8000
            assert len(events['w'])==2 and len(events['b'])==1
            assert all(d['strb']==255 for d in events['w'])
            data=b''.join(d['wdata'].to_bytes(8,'little') for d in events['w'])
            assert [d['wlast'] for d in events['w']]==[0,1]
            assert events['b'][0]['bresp']==0
            item['direction']='H2C'
        else:
            assert len(events['ar'])==1 and events['ar'][0]['araddr']==0x8000
            assert len(events['r'])==2
            assert [d['rlast'] for d in events['r']]==[0,1]
            assert all(d['rresp']==0 for d in events['r'])
            data=b''.join(d['rdata'].to_bytes(8,'little') for d in events['r'])
            item['direction']='C2H'
        assert data==bytes(range(16))
        item['accepted_data_hex']=data.hex()
    else:
        p='u_pcie/'
        active=[r for r in rows if r[p+'fdma_wareq']=='1']
        valid=[r for r in rows if r[p+'fdma_w_source_valid']=='1']
        assert active and valid
        assert all(int(r[p+'fdma_waddr[31:0]'],16)==0x100000 for r in active+valid)
        assert all(int(r[p+'fdma_wsize[15:0]'],16)==1 for r in active+valid)
        assert all(int(r[p+'fdma_wdata[63:0]'],16)==0x2200000011 for r in valid)
        states=[]
        for r in rows:
            state=int(r[p+'adapter_rx_state_dbg[3:0]'],16)
            if not states or states[-1]!=state: states.append(state)
        item.update(write_address='0x100000', write_size_64bit_beats=1,
            source_data_64bit='0000002200000011', writer_state_sequence=states,
            source_valid_samples=[int(r['Sample in Buffer']) for r in valid],
            note='Source valid is not a transfer-accept pulse; its duration is not a word count.')
        assert states==[0,1,2,3,0]
    item['status']='PASS'
    result[path.name]=item
(ROOT/'capture_decode.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({k:{'status':v['status'],'samples':v['samples'],
    'counts':v.get('handshake_counts'),'writer_states':v.get('writer_state_sequence')} for k,v in result.items()},indent=2))
