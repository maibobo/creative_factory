"""Validate the current board using the user's existing Vivado GUI."""
import argparse
import datetime
import json
import time
import uuid
from pathlib import Path
import lab_remote


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jobs', help='Current GUI job directory, preferably ssh://vivado-srv/C:/project/RTDS/...')
    parser.add_argument('--wait-gui', type=float, default=600)
    parser.add_argument('--boot-mode', choices=['unknown','flash','jtag'], default='unknown')
    cli = parser.parse_args()
    args = argparse.Namespace(jump='vivado-srv', arm='192.168.50.10',
                              arm_dir='/root/rtds_joint_lab_20261016', jobs=None,
                              exclusive=True, capture=False, no_jtag=False,
                              boot_mode=cli.boot_mode, live_log=True)
    session=datetime.datetime.now().strftime('%Y%m%d_%H%M%S')+'_'+uuid.uuid4().hex[:6]
    progress_path = lab_remote.ROOT/'validation'/('gui_validation_'+session+'.json')
    progress = {'pc_time': datetime.datetime.now().astimezone().isoformat(), 'status': 'RUNNING',
                'boot_mode': cli.boot_mode, 'boot_mode_source': 'Explicit user option; unknown if not specified',
                'transport':'SSH to existing Windows GUI; no mapped drive dependency',
                'runs': {}, 'phase': 'ARM preflight', 'hardware_evidence': []}

    def save():
        tmp = progress_path.with_suffix('.tmp')
        tmp.write_text(json.dumps(progress, ensure_ascii=False, indent=2), encoding='utf-8')
        tmp.replace(progress_path)
        print('PROGRESS='+str(progress_path)+' PHASE='+progress['phase'],flush=True)

    client = lab_remote.connect(args)
    save()
    try:
        # Reports remain on ARM; observer can tail this in an existing terminal.
        lab_remote.remote_exec(client, 'touch /root/rtds_joint_lab_20261016/live_status.log')
        for case in ('env', 'regs'):
            args.case = case
            progress['phase'] = case; save()
            progress['runs'][case] = lab_remote.run_case(client, args)
            save()
        progress['phase'] = 'Waiting for ::rtds_gui::start in existing Vivado'; save()
        deadline = time.monotonic()+cli.wait_gui
        while True:
            candidates = [cli.jobs] if cli.jobs else lab_remote.discover_gui_jobs(args.jump)
            if len(candidates) > 1:
                raise RuntimeError('Multiple GUI bridges; select --jobs: '+repr(candidates))
            if len(candidates) == 1:
                args.jobs = candidates[0]; break
            if time.monotonic() >= deadline:
                progress['status'] = 'WAITING_FOR_GUI'
                progress['phase'] = 'Execute ::rtds_gui::start in the existing connected GUI'; save()
                return
            time.sleep(5)
        progress['jobs'] = args.jobs
        progress['hardware_evidence'].append(lab_remote.hw_call(args.jobs, 'inspect'))
        progress['hardware_evidence'].append(lab_remote.hw_call(args.jobs, 'snapshot'))
        save()
        for case in ('config', 'ddr', 'single', 'multi'):
            args.case = case
            # First DMA and uplink captures are shown in the GUI. Do not create
            # twelve additional waveform tabs during the ring test on a slow PC.
            args.capture = case in ('ddr', 'single')
            progress['phase'] = case; save()
            progress['runs'][case] = lab_remote.run_case(client, args)
            save()
        progress['hardware_evidence'].append(lab_remote.hw_call(args.jobs, 'snapshot'))
        progress['status'] = 'PASS'
        progress['phase'] = 'Six board cases complete; real Aurora/peer tests remain separate'
        save()
        print('GUI_VALIDATION=PASS')
    except Exception as exc:
        progress['status'] = 'FAIL'
        progress['error'] = str(exc)
        if args.jobs:
            try:
                progress['failure_snapshot'] = lab_remote.hw_call(args.jobs, 'snapshot')
            except Exception as snap_error:
                progress['failure_snapshot_error'] = str(snap_error)
        save()
        raise
    finally:
        client.close()
        client._rtds_tunnel.terminate()
        client._rtds_tunnel.wait(timeout=5)


if __name__ == '__main__':
    main()
