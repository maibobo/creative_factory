#!/usr/bin/env python3
"""RTDS board-side lab runner, Python >=3.8, standard library only.

Architecture:
  Layer 1: rtds_regs.py          PCIe discovery + BAR register access
  Layer 2: rtds_dma_transport.py one-shot H2C/C2H transport
  Layer 3: rtds_protocol.py      RTDS ordering, queue ownership and ACK policy

This file is deliberately only the CLI/report/control orchestration layer.
No automatic resets, FPGA programming, driver reloads, user-interrupt
registration, or acknowledgement retries are performed.
"""
import argparse
import csv
import datetime
import fcntl
import hashlib
import json
import platform
import re
import subprocess
import sys
import time
import uuid
from pathlib import Path

from rtds_common import (
    LabError, SAFE_REGS, UP_BASE, UP_COUNT, UP_DATA, UP_STRIDE,
    atomic_json, compare_bytes, parse_io)
from rtds_dma_transport import XdmaTransport
from rtds_protocol import RtdsProtocol
from rtds_regs import PcieEndpoint, RegisterAccess

# Compatibility name for existing offline code that imported Experiments.
Experiments = RtdsProtocol


class Report:
    def __init__(self, args):
        self.args = args
        self.run_id = args.run_id or ('arm_' + uuid.uuid4().hex[:12])
        if not re.fullmatch(r'[A-Za-z0-9_.-]{1,100}', self.run_id):
            raise LabError(
                'run-id must contain only letters, digits, _, -, .')

        self.path = Path(args.output) / self.run_id
        self.path.mkdir(parents=True, exist_ok=False)
        self.started = time.monotonic()
        self.doc = {
            'run_id': self.run_id,
            'case': args.case,
            'status': 'RUNNING',
            'pc_time': args.pc_time,
            'boot_mode': args.boot_mode,
            'arm_wall_time_untrusted': datetime.datetime.now().isoformat(),
            'arm_monotonic_start': self.started,
            'kernel': platform.release(),
            'machine': platform.machine(),
            'steps': [],
            'blocks': [],
            'evidence': [],
            'exclusive_declared': args.exclusive,
            'note': 'VIO mode validates DDR/C2H, not real Aurora RX.',
        }
        self.log(
            'START',
            **{key: value for key, value in self.doc.items()
               if key not in ('steps', 'blocks')})

        program_files = (
            'rtds_lab.py',
            'rtds_common.py',
            'rtds_regs.py',
            'rtds_dma_transport.py',
            'rtds_protocol.py',
            'rtds_dma.c',
            'rtds_dma',
        )
        for name in program_files:
            file_path = Path(__file__).parent / name
            if file_path.exists():
                self.doc.setdefault('program_sha256', {})[name] = (
                    hashlib.sha256(file_path.read_bytes()).hexdigest())

        if args.artifacts_manifest:
            self.doc['fpga_artifacts'] = json.loads(
                Path(args.artifacts_manifest).read_text(encoding='utf-8'))

    def log(self, event, **fields):
        item = {
            'elapsed': round(time.monotonic() - self.started, 6),
            'event': event,
            **fields,
        }
        self.doc['steps'].append(item)
        line = json.dumps(item, ensure_ascii=False)
        with (self.path / 'run.log').open('a', encoding='utf-8') as stream:
            stream.write(line + '\n')
        print(line, flush=True)
        atomic_json(self.path / 'result.json', self.doc)

    def finish(self, status, error=None):
        self.doc.update(
            status=status,
            error=error,
            elapsed_seconds=time.monotonic() - self.started)
        self.log('FINISH', status=status, error=error)
        with (self.path / 'summary.csv').open(
                'w', newline='', encoding='utf-8-sig') as stream:
            writer = csv.DictWriter(
                stream,
                fieldnames=[
                    'run_id', 'case', 'status', 'boot_mode',
                    'pc_time', 'elapsed_seconds', 'error'])
            writer.writeheader()
            writer.writerow(
                {key: self.doc.get(key) for key in writer.fieldnames})


class Control:
    """Manual gate or file handshake; never a timed blind trigger."""

    def __init__(self, args, report):
        self.args = args
        self.report = report
        self.seq = 0
        self.root = Path(args.control_dir) if args.control_dir else None
        if self.root:
            self.root.mkdir(parents=True, exist_ok=False)

    def call(self, action, **params):
        self.seq += 1
        self.report.log(
            'CONTROL_REQUEST',
            action=action,
            sequence=self.seq,
            params=params)

        if not self.root:
            prompts = {
                'inspect':
                    'Run ::rtds_lab::inspect. Confirm link/DDR=1, '
                    'fault=0, busy=0. Enter PASS: ',
                'arm':
                    'Run ::rtds_joint::arm %s. Confirm ILA is waiting, '
                    'then enter PASS: ' % params.get('test'),
                'inject':
                    'Run ::rtds_lab::inject. Wait for accepted=2, '
                    'busy=0, fault=0, then enter PASS: ',
                'save':
                    'Run ::rtds_lab::save %s, retain the evidence, '
                    'then enter PASS: ' % params.get('kind'),
                'snapshot':
                    'Run ::rtds_joint::snapshot and keep its output, '
                    'then enter PASS: ',
            }
            try:
                confirmed = input(prompts[action]).strip() == 'PASS'
            except EOFError:
                confirmed = False
            if not confirmed:
                raise LabError(
                    'Manual control confirmation missing: ' + action)
            response = {'manual_ack': True, 'action': action}
        else:
            request_id = '%03d_%s' % (
                self.seq, uuid.uuid4().hex[:8])
            request = {'id': request_id, 'action': action, **params}
            atomic_json(self.root / 'request.json', request)

            deadline = time.monotonic() + self.args.control_timeout
            response = None
            while time.monotonic() < deadline:
                response_path = self.root / 'response.json'
                if response_path.exists():
                    candidate = json.loads(
                        response_path.read_text(encoding='utf-8'))
                    if candidate.get('id') == request_id:
                        response = candidate
                        break
                time.sleep(0.1)

            if response is None:
                raise LabError(
                    'Control handshake timeout: ' + action)
            if response.get('status') != 'ok':
                raise LabError(
                    'Hardware control failed: %r' % response)

        self.report.doc['evidence'].append(response)
        self.report.log(
            'CONTROL_COMPLETE',
            action=action,
            response=response)
        return response


def arguments(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        'case',
        choices=['env', 'regs', 'config', 'ddr', 'single', 'multi'])
    parser.add_argument(
        '--exclusive',
        action='store_true',
        help='Declare other software stopped; required for writes/DMA')
    parser.add_argument(
        '--capture',
        action='store_true',
        help='Arm and save the appropriate ILA for each transfer/injection')
    parser.add_argument(
        '--no-jtag',
        action='store_true',
        help='DDR-only CPU data loop; no VIO/ILA verification claimed')
    parser.add_argument(
        '--output',
        default=str(Path(__file__).parent.parent / 'results'))
    parser.add_argument('--run-id')
    parser.add_argument('--pc-time', default='not supplied')
    parser.add_argument(
        '--boot-mode',
        choices=['flash', 'jtag', 'unknown'],
        default='unknown')
    parser.add_argument(
        '--control-dir',
        help='Unique directory for the PC controller SFTP handshake')
    parser.add_argument('--state-timeout', type=float, default=2.0)
    parser.add_argument('--dma-timeout', type=float, default=10.0)
    parser.add_argument('--control-timeout', type=float, default=600.0)
    parser.add_argument('--bdf')
    parser.add_argument('--device-index', type=int, default=0)
    parser.add_argument('--sysfs', default='/sys/bus/pci/devices')
    parser.add_argument('--dev-root', default='/dev')
    parser.add_argument('--artifacts-manifest')

    args = parser.parse_args(argv)
    if min(
            args.state_timeout,
            args.dma_timeout,
            args.control_timeout) <= 0:
        parser.error('timeouts must be positive')
    if args.case not in ('env', 'regs') and not args.exclusive:
        parser.error(
            'This experiment requires --exclusive; '
            'stop other hardware users first')
    if args.no_jtag and (
            args.capture or args.case in ('single', 'multi')):
        parser.error(
            '--no-jtag cannot be combined with capture '
            'or VIO uplink experiments')
    return args


def main(argv=None):
    args = arguments(argv)
    report = None
    regs = None

    lock = open('/run/lock/rtds_joint_lab.lock', 'a')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print(
            'Another RTDS experiment is running',
            file=sys.stderr)
        return 2

    try:
        report = Report(args)

        endpoint = PcieEndpoint(args, report)
        regs = RegisterAccess(endpoint, args, report)
        dma = XdmaTransport(
            args, report, endpoint.devices)
        protocol = RtdsProtocol(
            regs, dma, Control(args, report), report, args)

        protocol.run()
        report.finish('PASS')
        return 0

    except (
            LabError,
            OSError,
            subprocess.SubprocessError,
            KeyboardInterrupt,
            ValueError) as exc:
        if report:
            report.log('FAILURE', error=str(exc))
            if regs:
                try:
                    regs.snapshot('failure_no_read_clear')
                except Exception as snapshot_error:
                    report.log(
                        'SNAPSHOT_FAILED',
                        error=str(snapshot_error))
            report.finish(
                'FAIL',
                str(exc) or type(exc).__name__)
        else:
            print(str(exc), file=sys.stderr)
        return 1

    finally:
        lock.close()


if __name__ == '__main__':
    sys.exit(main())
