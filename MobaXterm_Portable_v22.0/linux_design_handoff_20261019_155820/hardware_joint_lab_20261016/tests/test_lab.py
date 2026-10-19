"""Offline behavioral checks; no io, PCIe, JTAG, or real DMA is accessed."""
import argparse
import json
import os
import subprocess
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parent.parent
ARM = ROOT / 'arm'
if str(ARM) not in sys.path:
    sys.path.insert(0, str(ARM))
if os.name == 'nt':
    sys.modules.setdefault('fcntl', types.SimpleNamespace())

import rtds_dma_transport as dma_mod
import rtds_lab as lab
import rtds_regs as regs_mod


class FakeReport:
    def __init__(self, path):
        self.path = path
        self.doc = {'blocks': [], 'steps': []}

    def log(self, event, **kwargs):
        self.doc['steps'].append({'event': event, **kwargs})


class FakeRegs:
    def __init__(self):
        self.regs = {
            '0x0': 0x2001,
            '0x4': 0x20260914,
            '0x8': 0x40000,
            '0x20': 0,
            '0x24': 0x8000,
            '0x28': 0x8000,
            '0x2c': 3,
            '0x30': 1,
            '0x18': 0x100000,
            '0x1c': 8,
            '0x34': 0,
            '0x38': 0,
        }
        self.writes = []
        self.reads = []
        self.corrupt_on_clear = False
        self.io = 'fake_io'

    def rd(self, offset, read_clear=False):
        self.reads.append((offset, read_clear))
        if offset == 0x10:
            assert read_clear
            if self.corrupt_on_clear:
                self.regs['0x18'] += 0x40000
            return 1
        return self.regs[hex(offset)]

    def wr(self, offset, value):
        self.writes.append((offset, value))
        if offset == 0x14:
            self.regs.update({
                '0x30': 0,
                '0x18': 0,
                '0x1c': 0,
            })
        else:
            self.regs[hex(offset)] = value

    def wait(self, offset, value):
        if self.rd(offset) != value:
            raise lab.LabError('State timeout')

    def snapshot(self, label):
        del label
        return self.regs.copy()


class FakeDma:
    def __init__(self, path):
        self.path = path
        self.data = lab.UP_DATA + b'\xa5' * 8
        self.error = None
        self.calls = []

    def transfer(self, direction, address, size, path):
        self.calls.append((direction, address, size, Path(path)))
        if self.error:
            raise lab.LabError(self.error)
        Path(path).write_bytes(self.data)
        return {'completed': len(self.data)}


class LabTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name)
        self.report = FakeReport(self.path)
        self.regs = FakeRegs()
        self.dma = FakeDma(self.path)
        args = argparse.Namespace(
            capture=False,
            exclusive=True,
            no_jtag=False)
        self.exp = lab.RtdsProtocol(
            self.regs, self.dma, None, self.report, args)
        self.exp.baseline = self.regs.regs.copy()

    def tearDown(self):
        self.temp.cleanup()

    def test_io_exact_address_and_value(self):
        self.assertEqual(
            lab.parse_io('f0200000:  00002001\n', 0xf0200000),
            0x2001)
        self.assertEqual(
            lab.parse_io('0xf0200004:  0x20260914\n', 0xf0200004),
            0x20260914)

    def test_io_bad_address_ambiguous_or_error_is_rejected(self):
        for text in (
                'f0200004: 00002001',
                'f0200000: 1\nf0200000: 2',
                'permission denied'):
            with self.assertRaises(lab.LabError):
                lab.parse_io(text, 0xf0200000)

    def test_byte_comparison_reports_precise_offset(self):
        with self.assertRaisesRegex(lab.LabError, 'offset=0x2'):
            lab.compare_bytes(
                b'\x00\x01\x02',
                b'\x00\x01\xff')
        with self.assertRaisesRegex(lab.LabError, 'length'):
            lab.compare_bytes(b'12', b'1')

    def test_success_acknowledges_once_after_data_comparison(self):
        self.exp.consume(1)
        self.assertEqual(self.regs.writes, [(0x14, 1)])
        self.assertTrue(
            self.report.doc['blocks'][0]['ack_confirmed'])
        self.assertFalse(
            any(offset == 0x10 for offset, _ in self.regs.reads))

    def test_data_mismatch_never_acknowledges(self):
        self.dma.data = b'\xff' * 16
        with self.assertRaisesRegex(lab.LabError, 'mismatch'):
            self.exp.consume(1)
        self.assertEqual(self.regs.writes, [])

    def test_dma_error_short_and_timeout_never_acknowledge(self):
        for error in (
                'DMA error',
                'DMA failed/short',
                'DMA timeout'):
            self.dma.error = error
            with self.assertRaises(lab.LabError):
                self.exp.consume(1)
            self.assertEqual(self.regs.writes, [])

    def test_read_clear_side_effect_is_detected_before_dma_and_ack(self):
        self.regs.corrupt_on_clear = True
        with self.assertRaisesRegex(lab.LabError, 'clear'):
            self.exp.consume(1, check_notify=True)
        self.assertEqual(
            sum(offset == 0x10 for offset, _ in self.regs.reads),
            1)
        self.assertEqual(self.regs.writes, [])
        self.assertEqual(list(self.path.glob('up_*.bin')), [])

    def test_sequence_gap_never_acknowledges(self):
        self.exp.last_seq = 5
        with self.assertRaisesRegex(lab.LabError, 'sequence'):
            self.exp.consume(1)
        self.assertEqual(self.regs.writes, [])

    def test_sequence_wrap_is_valid(self):
        self.exp.last_seq = 0xffffffff
        self.exp.consume(1)
        self.assertEqual(self.exp.last_seq, 0)

    def test_illegal_head_address_or_length_never_acknowledges(self):
        for key, value in (
                ('0x18', 0x8000),
                ('0x18', 0x100010),
                ('0x1c', 16)):
            old = self.regs.regs.copy()
            self.regs.regs[key] = value
            with self.assertRaises(lab.LabError):
                self.exp.consume(1)
            self.assertEqual(self.regs.writes, [])
            self.regs.regs = old

    def test_protocol_rejects_dma_outside_lab_regions_before_transport(self):
        with self.assertRaisesRegex(lab.LabError, 'outside'):
            self.exp._dma('c2h', 0x12340, 16, self.path / 'bad')
        self.assertEqual(self.dma.calls, [])

    def test_configuration_restores_original_values_without_start(self):
        self.exp.config()
        self.assertEqual(
            (self.regs.rd(0x24), self.regs.rd(0x28)),
            (0x8000, 0x8000))
        self.assertFalse(
            any(offset == 0x20 for offset, _ in self.regs.writes))

    def test_old_queue_is_not_blindly_drained(self):
        with self.assertRaisesRegex(lab.LabError, 'Old blocks'):
            self.exp.preflight()
        self.assertEqual(self.regs.writes, [])

    def test_default_snapshot_excludes_read_clear(self):
        self.assertNotIn(0x10, lab.SAFE_REGS)
        self.assertNotIn(0x14, lab.SAFE_REGS)

    def test_transport_short_transfer_is_not_retried(self):
        args = argparse.Namespace(dma_timeout=0.01)
        transport = lab.XdmaTransport(
            args,
            self.report,
            {
                'h2c_0': Path('/dev/fake_h2c'),
                'c2h_0': Path('/dev/fake_c2h'),
            },
            helper='/fake/rtds_dma')
        result = subprocess.CompletedProcess(
            [], 5,
            '{"completed":8,"requested":16}',
            'short')
        with mock.patch.object(
                dma_mod.subprocess, 'run',
                return_value=result) as run:
            with self.assertRaisesRegex(lab.LabError, 'short'):
                transport.transfer(
                    'c2h', 0x100000, 16,
                    self.path / 'unused')
            self.assertEqual(run.call_count, 1)

    def test_transport_timeout_is_not_retried(self):
        args = argparse.Namespace(dma_timeout=0.01)
        transport = lab.XdmaTransport(
            args,
            self.report,
            {
                'h2c_0': Path('/dev/fake_h2c'),
                'c2h_0': Path('/dev/fake_c2h'),
            },
            helper='/fake/rtds_dma')
        with mock.patch.object(
                dma_mod.subprocess, 'run',
                side_effect=subprocess.TimeoutExpired(
                    'dma', .01)) as run:
            with self.assertRaisesRegex(lab.LabError, 'timeout'):
                transport.transfer(
                    'c2h', 0x100000, 16,
                    self.path / 'unused')
            self.assertEqual(run.call_count, 1)

    def test_uncertain_ack_write_is_never_retried(self):
        regs = regs_mod.RegisterAccess.__new__(
            regs_mod.RegisterAccess)
        regs.args = argparse.Namespace(
            exclusive=True,
            state_timeout=0.01)
        regs.report = self.report
        regs.io = 'fake_io'
        regs.base = 0xf0200000
        with mock.patch.object(
                regs_mod.subprocess, 'run',
                side_effect=subprocess.TimeoutExpired(
                    'io', .01)) as run:
            with self.assertRaisesRegex(lab.LabError, 'no retry'):
                regs.wr(0x14, 1)
            self.assertEqual(run.call_count, 1)

    @unittest.skipIf(
        os.name == 'nt',
        'Compile native helper on Linux/ARM')
    def test_real_c_helper_file_fixture_roundtrip_and_short_no_retry(self):
        binary = self.path / 'rtds_dma'
        subprocess.run(
            [
                'cc', '-std=c11', '-Wall', '-Wextra', '-Werror',
                str(ROOT / 'arm' / 'rtds_dma.c'),
                '-o', str(binary),
            ],
            check=True)

        dev = self.path / 'fake_device'
        tx = self.path / 'tx'
        rx = self.path / 'rx'
        dev.write_bytes(b'\0' * 64)
        tx.write_bytes(bytes(range(16)))

        one = subprocess.run(
            [
                str(binary), 'h2c', str(dev),
                '16', '16', str(tx),
            ],
            capture_output=True,
            text=True)
        self.assertEqual(one.returncode, 0, one.stderr)

        two = subprocess.run(
            [
                str(binary), 'c2h', str(dev),
                '16', '16', str(rx),
            ],
            capture_output=True,
            text=True)
        self.assertEqual(two.returncode, 0, two.stderr)
        self.assertEqual(rx.read_bytes(), tx.read_bytes())

        short = subprocess.run(
            [
                str(binary), 'c2h', str(dev),
                '64', '16', str(self.path / 'short'),
            ],
            capture_output=True,
            text=True)
        self.assertEqual(short.returncode, 5)
        self.assertEqual(
            json.loads(short.stdout)['completed'],
            0)
        self.assertFalse((self.path / 'short').exists())

        bad = subprocess.run(
            [
                str(binary), 'h2c', str(dev),
                '17', '16', str(tx),
            ],
            capture_output=True)
        self.assertEqual(bad.returncode, 2)


if __name__ == '__main__':
    unittest.main(verbosity=2)
