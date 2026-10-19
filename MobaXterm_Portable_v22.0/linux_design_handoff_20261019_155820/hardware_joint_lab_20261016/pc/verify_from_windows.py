"""Run on the Windows machine attached to JTAG, directly connecting to ARM.

An outer SSH launcher supplies the password on encrypted stdin, never argv/files.
Use the existing GUI job directory; no additional captures or hardware session.
"""
import argparse
import datetime
import json
import sys
import uuid
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parent/'hostdeps_20261019'))
import lab_remote


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jobs',required=True)
    cli=parser.parse_args()
    jobs=Path(cli.jobs)
    if not (jobs/'service.ready').is_file():
        raise RuntimeError('Existing GUI bridge not ready')
    password=sys.stdin.readline().rstrip('\r\n')
    if not password:
        raise RuntimeError('Missing password on encrypted stdin')
    client=lab_remote.paramiko.SSHClient()
    client.load_host_keys(str(Path.home()/'.ssh'/'known_hosts'))
    client.set_missing_host_key_policy(lab_remote.paramiko.RejectPolicy())
    client.connect('192.168.50.10',username='root',password=password,
                   look_for_keys=False,allow_agent=False,timeout=10,auth_timeout=10,banner_timeout=10)
    del password
    client.get_transport().set_keepalive(15)
    args=argparse.Namespace(arm_dir='/root/rtds_joint_lab_20261016',jobs=jobs,
        exclusive=True,capture=False,no_jtag=False,boot_mode='unknown',live_log=True)
    session=datetime.datetime.now().strftime('%Y%m%d_%H%M%S')+'_'+uuid.uuid4().hex[:6]
    path=lab_remote.ROOT/'validation'/('direct_windows_validation_'+session+'.json')
    report={'pc_time':datetime.datetime.now().astimezone().isoformat(),
        'route':'Windows directly to ARM; same existing GUI bridge',
        'jobs':str(jobs),'status':'RUNNING','runs':{},'capture':False,'boot_mode':'unknown'}
    def save():
        path.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
        print('DIRECT_PROGRESS='+str(path),flush=True)
    save()
    try:
        report['before']=lab_remote.hw_call(jobs,'inspect')
        for case in ('env','regs','config','ddr','single','multi'):
            args.case=case
            report['phase']=case;save()
            report['runs'][case]=lab_remote.run_case(client,args)
            save()
        report['after']=lab_remote.hw_call(jobs,'inspect')
        report['snapshot']=lab_remote.hw_call(jobs,'snapshot')
        report['status']='PASS'
        save()
    except Exception as exc:
        report.update(status='FAIL',error=str(exc))
        save()
        raise
    finally:
        client.close()


if __name__=='__main__':
    main()
