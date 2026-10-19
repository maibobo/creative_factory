"""Launch the direct Windows route, passing a prompted password only on SSH stdin."""
import argparse
import getpass
import re
import subprocess
import sys
import lab_remote

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--jobs',help='ssh://vivado-srv/C:/project/RTDS/.../jobs/gui_SESSION; otherwise discover today')
options=parser.parse_args()
candidates=[options.jobs] if options.jobs else lab_remote.discover_gui_jobs()
if len(candidates)!=1:
    raise SystemExit('Expected one existing GUI bridge; specify --jobs')
alias,jobs=lab_remote.windows_job_url(candidates[0])
if not re.fullmatch(r'[A-Za-z0-9_:/.-]+',jobs):
    raise SystemExit('This launcher requires a job path without shell metacharacters or spaces')
command=('python -u C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/debug/'
    'hardware_joint_lab_20261016/pc/verify_from_windows.py --jobs '+jobs)
password=getpass.getpass('ARM password (encrypted SSH stdin, not saved): ')
print('Starting direct Windows verification; ARM live_status.log remains live.',flush=True)
p=subprocess.Popen(['ssh','-o','BatchMode=yes',alias,
    command],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
    text=True,encoding='utf-8',errors='replace',creationflags=subprocess.CREATE_NO_WINDOW)
output,_=p.communicate(password+'\n',timeout=360)
del password
print(output)
sys.exit(p.returncode)
