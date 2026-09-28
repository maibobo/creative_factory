"""Read-only check of generated AXI ID wiring; no HDL simulation or synthesis."""
from pathlib import Path
import json
import xml.etree.ElementTree as ET

ROOT = Path('F:/RTDS_test_DDR4_64bit_batch_dev')
BD = ROOT / 'RTDS_test_DDR4_64bit.srcs/sources_1/bd/design_1'
NS = '{http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009}'

def xci_values(path):
    return {e.get(NS + 'referenceId'): e.text for e in ET.parse(path).iter(NS + 'configurableElementValue')}

v = xci_values(BD / 'ip/design_1_xbar_0/design_1_xbar_0.xci')
width = int(v['MODELPARAM_VALUE.C_AXI_ID_WIDTH'])
bases = int(v['MODELPARAM_VALUE.C_S_AXI_BASE_ID'], 16)
threads = int(v['MODELPARAM_VALUE.C_S_AXI_THREAD_ID_WIDTH'], 16)
assert width == 5
slots = [(bases >> (32*i) & 0xffffffff, threads >> (32*i) & 0xffffffff) for i in range(2)]
assert slots == [(0, 1), (16, 4)], slots
seen = set()
for slot, (base, bits) in enumerate(slots):
    mask = (1 << bits) - 1
    for original_id in range(1 << bits):
        extended_id = base | (original_id & mask)
        assert extended_id < (1 << width)
        assert extended_id not in seen
        seen.add(extended_id)
        # Crossbar f_thread_id_mask removes the source prefix before returning ID.
        returned_id = extended_id & mask
        assert returned_id == original_id

hdl = (BD / 'synth/design_1.v').read_text(encoding='utf-8')
compact = ''.join(hdl.split())
for channel in ('aw', 'ar'):
    expr = f".s_axi_{channel}id({{1'b0,s01_couplers_to_xbar_{channel.upper()}ID,1'b0,1'b0,1'b0,1'b0,s00_couplers_to_xbar_{channel.upper()}ID}})"
    assert expr in compact, expr
for channel in ('B', 'R'):
    assert f'.M_AXI_{channel}ID(S00_AXI_1_{channel}ID[0])' in compact
    assert f'.m_axi_{channel.lower()}id(auto_cc_to_s01_couplers_{channel}ID[3:0])' in compact
    assert f'.m_axi_{channel.lower()}id(xbar_to_m00_couplers_{channel}ID)' in compact

design = json.loads((BD / 'design_1.bd').read_text(encoding='utf-8'))['design']
assert design['interface_ports']['M_AXI_MEM']['parameters']['ID_WIDTH']['value'] == '5'
xdma = design['components']['xdma_0']['parameters']
assert xdma['axi_data_width']['value'] == '64_bit'
assert xdma['axisten_freq']['value'] == '250'
result = '\n'.join([
    'PASS: FDMA thread ID width=1, base=0; XDMA thread ID width=4, base=16.',
    'PASS: all 18 representable IDs have disjoint 5-bit encodings and lossless return IDs.',
    'PASS: generated AWID/ARID zero extension and BID/RID low-bit slices match thread widths.',
    'PASS: memory-side ID width=5, XDMA AXI data width=64, clock=250MHz.',
    'BD 41-2384 at these specific boundaries is expected width adaptation; no message suppression applied.',
    'This is a static wiring/parameter audit, not a timing or functional simulation result.',
]) + '\n'
(ROOT / 'reports/board_audit_20260921/axi_id_mapping_check.txt').write_text(result, encoding='utf-8')
print(result)
