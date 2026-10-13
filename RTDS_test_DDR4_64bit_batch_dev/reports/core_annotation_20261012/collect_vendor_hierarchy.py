from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import json
root = Path(r'C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev')
ip = root/'RTDS_test_DDR4_64bit.srcs/sources_1/ip/rtds_ddr4_mig/rtl'
names = ['rtds_ddr4_mig.sv','rtds_ddr4_mig_ddr4.sv','rtds_ddr4_mig_ddr4_mem_intfc.sv','ddr4_v2_2_mc.sv','ddr4_v2_2_mc_group.sv']
with ZipFile(root/'reports/core_annotation_20261012/vendor_hierarchy.zip','w',ZIP_DEFLATED) as z:
    for name in names:
        fs = list(ip.rglob(name))
        if len(fs)!=1: raise RuntimeError((name,len(fs)))
        z.write(fs[0],fs[0].relative_to(root).as_posix())
print(json.dumps({'files':len(names)}))
