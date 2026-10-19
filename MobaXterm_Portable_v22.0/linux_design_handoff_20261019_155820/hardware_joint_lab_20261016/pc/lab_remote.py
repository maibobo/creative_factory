#!/usr/bin/env python3
"""Deploy/run the ARM lab from Windows through the existing vivado-srv SSH alias.
Password is prompted or read from RTDS_ARM_PASSWORD; it is never saved in a file.
The ARM host key is taken from the jump host's previously verified known_hosts.
"""
import argparse
import datetime
import getpass
import hashlib
import json
import os
import re
import shlex
import socket
import subprocess
import sys
import time
import uuid
from pathlib import Path, PurePosixPath
from urllib.parse import urlsplit

sys.path.insert(0, str(Path.home() / '.cache' / 'rtds-lab-hostdeps'))
try:
    import paramiko
except ImportError:
    raise SystemExit('Install PC-only dependency: python -m pip install --target "%USERPROFILE%/.cache/rtds-lab-hostdeps" paramiko')

ROOT = Path(__file__).resolve().parent.parent


def ssh_win(alias, script, timeout=30):
    import base64
    encoded = base64.b64encode(script.encode('utf-16le')).decode('ascii')
    result = subprocess.run(['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=5', alias,
                             'powershell.exe -NoProfile -NonInteractive -EncodedCommand ' + encoded],
                            capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError('Windows SSH failed: ' + result.stderr)
    return result.stdout


def connect(args):
    if not re.fullmatch(r'[A-Za-z0-9_.-]+', args.jump):
        raise RuntimeError('Invalid jump-host alias')
    saved = ssh_win(args.jump, "ssh-keygen -F '%s'" % args.arm)
    client = paramiko.SSHClient()
    for line in saved.splitlines():
        fields = line.split()
        if len(fields) >= 3 and fields[0] == args.arm and fields[1] in ('ssh-ed25519', 'ecdsa-sha2-nistp256', 'ssh-rsa'):
            import base64
            key = paramiko.PKey.from_type_string(fields[1], base64.b64decode(fields[2]))
            client.get_host_keys().add(args.arm, fields[1], key)
    if not client.get_host_keys().lookup(args.arm):
        raise RuntimeError('ARM host key is not saved on the jump host; verify it before connecting')
    client.set_missing_host_key_policy(paramiko.RejectPolicy())
    password = os.environ.get('RTDS_ARM_PASSWORD') or getpass.getpass('ARM root SSH password (not saved): ')
    # Windows select() cannot use a subprocess pipe. Use a loopback-only OpenSSH
    # tunnel and a real socket, retaining existing SSH host-key and key policies.
    with socket.socket() as probe:
        probe.bind(('127.0.0.1', 0))
        port = probe.getsockname()[1]
    tunnel = subprocess.Popen(
        ['ssh', '-N', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=5',
         '-o', 'ExitOnForwardFailure=yes', '-L', '127.0.0.1:%d:%s:22' % (port, args.arm), args.jump],
        stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
    try:
        deadline = time.monotonic()+10
        while True:
            if tunnel.poll() is not None:
                raise RuntimeError('SSH tunnel failed: '+tunnel.stderr.read().decode(errors='replace'))
            try:
                proxy = socket.create_connection(('127.0.0.1', port), timeout=1)
                break
            except OSError:
                if time.monotonic() > deadline:
                    raise RuntimeError('SSH tunnel startup timeout')
                time.sleep(0.1)
        client.connect(args.arm, username='root', password=password, sock=proxy,
                       look_for_keys=False, allow_agent=False, timeout=10, auth_timeout=10, banner_timeout=10)
    except BaseException:
        tunnel.terminate()
        tunnel.wait(timeout=5)
        raise
    client._rtds_tunnel = tunnel
    del password
    client.get_transport().set_keepalive(15)
    return client


def remote_exec(client, command, timeout=60):
    _, out, err = client.exec_command(command, timeout=timeout)
    stdout, stderr = out.read().decode(), err.read().decode()
    code = out.channel.recv_exit_status()
    if code:
        raise RuntimeError('ARM command failed (%d): %s\n%s\n%s' % (code, command, stdout, stderr))
    return stdout


def deploy(client, args):
    # Keep the same advisory lock as the board runner across backup, transfer and
    # build, so deployment cannot replace a program during an active experiment.
    lock_code = ("import fcntl,sys; f=open('/run/lock/rtds_joint_lab.lock','a'); "
                 "fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB); "
                 "print('DEPLOY_LOCKED',flush=True); sys.stdin.read()")
    stdin, stdout, stderr = client.exec_command('python3 -u -c '+shlex.quote(lock_code), timeout=15)
    if stdout.readline().strip() != 'DEPLOY_LOCKED':
        raise RuntimeError('ARM lab is busy; deployment refused: '+stderr.read().decode())
    try:
        return deploy_locked(client, args)
    finally:
        stdin.channel.shutdown_write()
        stdout.channel.recv_exit_status()


def deploy_locked(client, args):
    dest = args.arm_dir
    if not re.fullmatch(r'/root/[A-Za-z0-9_/-]+', dest) or '..' in dest.split('/'):
        raise RuntimeError('arm-dir must be a simple directory under /root')
    # Refuse symlink targets so backup/copy cannot wander outside the lab directory.
    script = ("import pathlib; p=pathlib.Path(%r); assert not p.is_symlink(); "
              "p.resolve().relative_to('/root'); print(p.exists())") % dest
    exists = remote_exec(client, 'python3 -c ' + shlex.quote(script)).strip() == 'True'
    backup = None
    if exists:
        backup = dest + '_backup_' + datetime.datetime.now().strftime('%Y%m%d_%H%M%S') + '_' + uuid.uuid4().hex[:5] + '.tar.gz'
        remote_exec(client, 'tar -czf %s -C %s %s' % (shlex.quote(backup),
                    shlex.quote(str(PurePosixPath(dest).parent)), shlex.quote(PurePosixPath(dest).name)), 120)
    remote_exec(client, 'mkdir -p ' + ' '.join(shlex.quote(dest+'/'+p) for p in ('arm','docs','tests')))
    manifest = {}
    with client.open_sftp() as sftp:
        for path in sorted((ROOT / 'arm').iterdir()):
            if path.is_file() and path.suffix in ('.py', '.c', '.sh'):
                target = dest + '/arm/' + path.name
                temp = target + '.upload'
                sftp.put(str(path), temp)
                # Existing file was backed up above before atomic replacement.
                sftp.posix_rename(temp, target)
                if path.suffix == '.sh':
                    sftp.chmod(target, 0o700)
                manifest[path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
        for name in ('artifact_manifest.json',):
            p = ROOT / name
            if p.exists():
                sftp.put(str(p), dest + '/' + name)
        additional = [ROOT/'README.md'] + list((ROOT/'docs').glob('*.md')) + [ROOT/'tests'/'test_lab.py']
        for p in additional:
            if p.exists():
                target = dest+'/'+p.relative_to(ROOT).as_posix()
                sftp.put(str(p), target+'.upload')
                sftp.posix_rename(target+'.upload', target)
    print(remote_exec(client, 'sh ' + shlex.quote(dest+'/arm/build.sh')), end='')
    verify = 'import pathlib,hashlib,json; p=pathlib.Path(%r); print(json.dumps({x.name:hashlib.sha256(x.read_bytes()).hexdigest() for x in p.iterdir() if x.is_file()}))' % (dest+'/arm')
    actual = json.loads(remote_exec(client, 'python3 -c '+shlex.quote(verify)))
    if any(actual.get(k) != v for k, v in manifest.items()):
        raise RuntimeError('ARM deployed-file hash mismatch')
    result = {'arm_directory': dest, 'backup_archive': backup, 'source_sha256': manifest,
              'binary_sha256': actual['rtds_dma'], 'pc_time': datetime.datetime.now().astimezone().isoformat()}
    (ROOT / 'validation' / ('deployment_' + datetime.datetime.now().strftime('%Y%m%d_%H%M%S') + '.json')).write_text(
        json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result, indent=2))


def windows_job_url(value):
    url = urlsplit(str(value))
    if url.scheme != 'ssh' or not re.fullmatch(r'[A-Za-z0-9_.-]+', url.netloc):
        raise RuntimeError('Expected ssh://JUMP_ALIAS/C:/project/RTDS/.../jobs/SESSION')
    path = url.path.lstrip('/')
    if (not path.startswith('C:/project/RTDS/') or '..' in path.split('/') or
            any(c in path for c in ("'", '\n', '\r', '\0')) or url.query or url.fragment):
        raise RuntimeError('Unsupported remote job-directory path')
    return url.netloc, path


def hw_call_ssh(jobs, action, parameter=None, timeout=30):
    alias, remote = windows_job_url(jobs)
    if action in ('inspect', 'snapshot', 'inject', 'stop'):
        if parameter is not None:
            raise RuntimeError('Operation does not accept parameters')
    elif action == 'arm':
        if parameter not in ('dma_write', 'dma_read', 'fdma_up'):
            raise RuntimeError('Unsupported arm operation')
    elif action == 'save':
        if parameter not in ('native', 'fdma'):
            raise RuntimeError('Unsupported capture kind')
    else:
        raise RuntimeError('Unsupported GUI operation')
    token = 'job_'+uuid.uuid4().hex
    command = action+((' '+parameter) if parameter else '')
    # Use a single SSH request for submit+wait. If its outcome is uncertain, the
    # action is not retried. The GUI claims each request before executing it.
    script = r"""
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$jobs='__JOBS__'
if (-not [IO.File]::Exists($jobs+'/service.ready')) { throw 'Existing GUI bridge is not ready' }
$base=$jobs+'/__TOKEN__'
[IO.File]::WriteAllText($base+'.tmp','__COMMAND__'+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
[IO.File]::Move($base+'.tmp',$base+'.request')
$deadline=[DateTime]::UtcNow.AddSeconds(__TIMEOUT__)
while ([DateTime]::UtcNow -lt $deadline) {
    if ([IO.File]::Exists($base+'.response')) {
        [Console]::Write([IO.File]::ReadAllText($base+'.response',[Text.Encoding]::UTF8))
        [Console]::WriteLine('request_id=__TOKEN__')
        exit 0
    }
    Start-Sleep -Milliseconds 150
}
throw 'GUI response timed out; do not repeat the action. Inspect request __TOKEN__.'
"""
    script = script.replace('__JOBS__', remote).replace('__TOKEN__', token).replace(
        '__COMMAND__', command).replace('__TIMEOUT__', str(float(timeout)))
    output = ssh_win(alias, script, timeout=timeout+15)
    result = dict(line.split('=', 1) for line in output.splitlines() if '=' in line)
    if result.get('status') != 'ok':
        raise RuntimeError('Vivado: '+result.get('error', repr(result)))
    return result


def discover_gui_jobs(alias='vivado-srv'):
    if not re.fullmatch(r'[A-Za-z0-9_.-]+', alias):
        raise RuntimeError('Invalid jump alias')
    script = r"""
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$root='C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/debug/hardware_joint_lab_20261016/jobs'
$prefix='gui_'+(Get-Date -Format 'yyyyMMdd')+'_'
$items=[Collections.Generic.List[string]]::new()
foreach ($dir in [IO.Directory]::GetDirectories($root,'gui_*')) {
    if (([IO.Path]::GetFileName($dir)).StartsWith($prefix) -and [IO.File]::Exists($dir+'/service.ready')) {
        $text=[IO.File]::ReadAllText($dir+'/service.ready')
        if ($text.Contains('mode=existing_gui')) { $items.Add('ssh://__ALIAS__/'+$dir.Replace('\','/')) }
    }
}
ConvertTo-Json -InputObject @($items.ToArray()) -Compress
"""
    return json.loads(ssh_win(alias, script.replace('__ALIAS__', alias)).strip())


def hw_call(jobs, action, parameter=None, timeout=30):
    if str(jobs).startswith('ssh://'):
        return hw_call_ssh(jobs, action, parameter, timeout)
    jobs = Path(jobs)
    if (jobs / 'service.error').exists():
        raise RuntimeError((jobs / 'service.error').read_text(encoding='utf-8-sig'))
    if not (jobs / 'service.ready').exists():
        raise RuntimeError('Vivado controller is not ready: ' + str(jobs))
    name = 'job_' + uuid.uuid4().hex
    request = jobs / (name + '.request')
    tmp = jobs / (name + '.tmp')
    tmp.write_text(action + ((' ' + parameter) if parameter else '') + '\n', encoding='utf-8')
    tmp.replace(request)
    deadline = time.monotonic()+timeout
    response = jobs / (name + '.response')
    while time.monotonic() < deadline:
        if response.exists():
            data = dict(line.split('=', 1) for line in response.read_text(encoding='utf-8-sig').splitlines() if '=' in line)
            if data.get('status') != 'ok':
                raise RuntimeError('Vivado: ' + data.get('error', repr(data)))
            return data
        time.sleep(0.15)
    raise RuntimeError('Vivado handshake timeout; command is not retried: ' + action)


def download_tree(sftp, remote, local):
    import stat
    local.mkdir(parents=True, exist_ok=True)
    for item in sftp.listdir_attr(remote):
        rp, lp = remote+'/'+item.filename, local/item.filename
        if stat.S_ISDIR(item.st_mode):
            download_tree(sftp, rp, lp)
        else:
            sftp.get(rp, str(lp))


def run_case(client, args):
    run_id = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')+'_'+args.case+'_'+uuid.uuid4().hex[:5]
    remote_control = args.arm_dir+'/control/'+run_id
    remote_output = args.arm_dir+'/results'
    cmd = ['python3', '-u', args.arm_dir+'/arm/rtds_lab.py', args.case,
           '--run-id', run_id, '--pc-time', datetime.datetime.now().astimezone().isoformat(),
           '--boot-mode', args.boot_mode, '--output', remote_output]
    if args.case not in ('env', 'regs'):
        if not args.exclusive:
            raise RuntimeError('Mutating case requires --exclusive')
        cmd += ['--exclusive']
    if args.capture:
        cmd += ['--capture']
    if args.no_jtag:
        cmd += ['--no-jtag']
    manifest = ROOT / 'artifact_manifest.json'
    if manifest.exists():
        cmd += ['--artifacts-manifest', args.arm_dir+'/artifact_manifest.json']
    if args.jobs:
        cmd += ['--control-dir', remote_control]
    elif args.case in ('ddr', 'single', 'multi') and not args.no_jtag:
        raise RuntimeError('PC launcher requires --jobs for cases needing VIO; manual use: run directly on ARM')
    # No stdin prompts when the PC controller is used.
    command = shlex.join(cmd)
    if getattr(args, 'live_log', False):
        # Append an observer log in the existing ARM terminal via tail -F.
        # pipefail retains the experiment's exit status even when tee succeeds.
        command = shlex.join(['bash', '-o', 'pipefail', '-c',
                              command+' | tee -a '+shlex.quote(args.arm_dir+'/live_status.log')])
    _, out, err = client.exec_command(command, timeout=1800)
    channel = out.channel
    channel.settimeout(0.2)
    carry, errors, processed = b'', b'', set()
    failed_control = None
    with client.open_sftp() as sftp:
        try:
            while not channel.exit_status_ready():
                if channel.recv_ready():
                    carry += channel.recv(65536)
                    while b'\n' in carry:
                        line, carry = carry.split(b'\n', 1)
                        print(line.decode('utf-8', errors='replace'), flush=True)
                if channel.recv_stderr_ready():
                    errors += channel.recv_stderr(65536)
                if args.jobs:
                    try:
                        with sftp.open(remote_control+'/request.json') as f:
                            request = json.loads(f.read())
                    except FileNotFoundError:
                        request = None
                    if request and request['id'] not in processed:
                        processed.add(request['id'])
                        action = request['action']
                        try:
                            response = hw_call(args.jobs, action, request.get('test') or request.get('kind'))
                        except Exception as e:
                            response = {'status': 'error', 'error': str(e)}
                            failed_control = str(e)
                        response.update(id=request['id'])
                        tmp = remote_control+'/response.upload'
                        with sftp.open(tmp, 'w') as f:
                            f.write(json.dumps(response))
                        sftp.posix_rename(tmp, remote_control+'/response.json')
                time.sleep(0.1)
            while channel.recv_ready():
                carry += channel.recv(65536)
            if carry:
                print(carry.decode('utf-8', errors='replace'), end='')
            while channel.recv_stderr_ready():
                errors += channel.recv_stderr(65536)
            status = channel.recv_exit_status()
        finally:
            # Even failed/uncertain experiments keep the board-side evidence.
            local = ROOT / 'validation' / 'board_runs' / run_id
            try:
                download_tree(sftp, remote_output+'/'+run_id, local)
                print('RESULT_DIRECTORY='+str(local))
            except OSError as e:
                print('Evidence download incomplete: '+str(e), file=sys.stderr)
    if errors:
        print(errors.decode('utf-8', errors='replace'), file=sys.stderr)
    if status:
        raise RuntimeError('Experiment failed; no retry performed. '+(failed_control or 'See result.json'))
    return run_id


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('operation', choices=['deploy', 'run', 'hardware'])
    p.add_argument('--case', choices=['env', 'regs', 'config', 'ddr', 'single', 'multi'], default='env')
    p.add_argument('--jump', default='vivado-srv')
    p.add_argument('--arm', default='192.168.50.10')
    p.add_argument('--arm-dir', default='/root/rtds_joint_lab_20261016')
    p.add_argument('--exclusive', action='store_true')
    p.add_argument('--capture', action='store_true')
    p.add_argument('--no-jtag', action='store_true')
    p.add_argument('--live-log', action='store_true', help='Append ARM live_status.log for an existing terminal observer')
    p.add_argument('--boot-mode', choices=['flash', 'jtag', 'unknown'], default='unknown')
    p.add_argument('--jobs', help='Existing GUI jobs, e.g. ssh://vivado-srv/C:/project/RTDS/.../jobs/gui_SESSION; mapped paths also supported')
    p.add_argument('--action', choices=['inspect', 'snapshot', 'stop'], default='inspect')
    args = p.parse_args()
    if not re.fullmatch(r'[0-9.]+', args.arm):
        p.error('ARM address must be numeric IPv4')
    if args.operation == 'hardware':
        if not args.jobs:
            p.error('--jobs required')
        print(json.dumps(hw_call(args.jobs, args.action), indent=2)); return
    client = connect(args)
    try:
        if args.operation == 'deploy':
            deploy(client, args)
        else:
            run_case(client, args)
    finally:
        client.close()
        client._rtds_tunnel.terminate()
        client._rtds_tunnel.wait(timeout=5)


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, paramiko.SSHException) as exc:
        print('ERROR: '+str(exc), file=sys.stderr)
        sys.exit(1)
