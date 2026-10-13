from pathlib import Path
import json,re,subprocess,datetime
V=Path('F:/RTDS_test_DDR4_64bit_batch_dev/verification_20261011')
print('DATE',datetime.datetime.now().isoformat())
for name in ['random_regression','random_additional','random_final','random_backend_final','random_period_retry','real_mig_recovery','rootport_current','rootport_current_o0']:
    print('\nDIRECTORY',name)
    d=V/name
    for file in ['running_tool.json','completion.json','summary_current.json']:
        p=d/file
        if p.exists():print(file,p.read_text('utf-8')[:1200])
    p=d/'summary.json'
    if p.exists():
        data=json.loads(p.read_text('utf-8'));rows=data if isinstance(data,list) else data.get('runs',[])
        for row in rows:
            log=d/row.get('log','NO_LOG');text=log.read_text('utf-8',errors='replace') if log.is_file() else ''
            hits=re.findall(r'(?m)^.*(?:Fatal:|Error:|ERROR:|TEST PASS|ROOTPORT_PASS|WALLCLOCK_TIMEOUT).*$' ,text)
            if row.get('status')!='PASS' or name in ['random_backend_final','random_period_retry','real_mig_recovery']:print(row.get('case'),row.get('seed'),row.get('status'),row.get('exit_code'),'markers',hits[-4:])
    for fname in ['elaborate.log','vivado.log']:
        p=d/fname
        if p.exists():print(fname,'tail',p.read_text('utf-8',errors='replace').splitlines()[-4:])
print('\nTASKLIST')
print(subprocess.run(['tasklist','/fo','csv'],capture_output=True,text=True,encoding='gbk',errors='replace').stdout)
