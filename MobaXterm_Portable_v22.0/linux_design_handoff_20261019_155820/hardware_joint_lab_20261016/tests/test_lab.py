"""Offline behavioral checks; no io, PCIe, JTAG, or real DMA is accessed."""
import argparse
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import types
import unittest
from unittest import mock
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if os.name == 'nt':
    sys.modules.setdefault('fcntl', types.SimpleNamespace())
spec = importlib.util.spec_from_file_location('rtds_lab', ROOT/'arm'/'rtds_lab.py')
lab = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lab)


class FakeReport:
    def __init__(self, path):
        self.path = path
        self.doc = {'blocks': [], 'steps': []}

    def log(self, event, **kwargs):
        self.doc['steps'].append({'event': event, **kwargs})


class FakeHardware:
    def __init__(self, path):
        self.path = path
        self.regs = {'0x0': 0x2001, '0x4': 0x20260914, '0x8': 0x40000, '0x20': 0,
                     '0x24': 0x8000, '0x28': 0x8000, '0x2c': 3, '0x30': 1,
                     '0x18': 0x100000, '0x1c': 8, '0x34': 0, '0x38': 0}
        self.writes, self.reads = [], []
        self.data = lab.UP_DATA + b'\xa5'*8
        self.dma_error = None
        self.corrupt_on_clear = False

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
            self.regs.update({'0x30': 0, '0x18': 0, '0x1c': 0})
        else:
            self.regs[hex(offset)] = value

    def wait(self, offset, value):
        if self.rd(offset) != value:
            raise lab.LabError('State timeout')

    def snapshot(self, label):
        return self.regs.copy()

    def dma(self, direction, address, size, path):
        if self.dma_error:
            raise lab.LabError(self.dma_error)
        path.write_bytes(self.data)
        return {'completed': len(self.data)}


class LabTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name)
        self.report = FakeReport(self.path)
        self.hw = FakeHardware(self.path)
        self.exp = lab.Experiments(self.hw, None, self.report, argparse.Namespace(capture=False))
        self.exp.baseline = self.hw.regs.copy()

    def tearDown(self):
        self.temp.cleanup()

    def test_io_exact_address_and_value(self):
        self.assertEqual(lab.parse_io('f0200000:  00002001\n', 0xf0200000), 0x2001)
        self.assertEqual(lab.parse_io('0xf0200004:  0x20260914\n', 0xf0200004), 0x20260914)

    def test_io_bad_address_ambiguous_or_error_is_rejected(self):
        for text in ('f0200004: 00002001', 'f0200000: 1\nf0200000: 2', 'permission denied'):
            with self.assertRaises(lab.LabError):
                lab.parse_io(text, 0xf0200000)

    def test_byte_comparison_reports_precise_offset(self):
        with self.assertRaisesRegex(lab.LabError, 'offset=0x2'):
            lab.compare_bytes(b'\x00\x01\x02', b'\x00\x01\xff')
        with self.assertRaisesRegex(lab.LabError, 'length'):
            lab.compare_bytes(b'12', b'1')

    def test_success_acknowledges_once_after_data_comparison(self):
        self.exp.consume(1)
        self.assertEqual(self.hw.writes, [(0x14, 1)])
        self.assertTrue(self.report.doc['blocks'][0]['ack_confirmed'])
        self.assertFalse(any(offset == 0x10 for offset, _ in self.hw.reads))

    def test_data_mismatch_never_acknowledges(self):
        self.hw.data = b'\xff'*16
        with self.assertRaisesRegex(lab.LabError, 'mismatch'):
            self.exp.consume(1)
        self.assertEqual(self.hw.writes, [])

    def test_dma_error_short_and_timeout_never_acknowledge(self):
        for error in ('DMA error', 'DMA failed/short', 'DMA timeout'):
            self.hw.dma_error = error
            with self.assertRaises(lab.LabError):
                self.exp.consume(1)
            self.assertEqual(self.hw.writes, [])

    def test_read_clear_side_effect_is_detected_before_dma_and_ack(self):
        self.hw.corrupt_on_clear = True
        with self.assertRaisesRegex(lab.LabError, 'clear'):
            self.exp.consume(1, check_notify=True)
        self.assertEqual(sum(offset == 0x10 for offset, _ in self.hw.reads), 1)
        self.assertEqual(self.hw.writes, [])
        self.assertEqual(list(self.path.glob('up_*.bin')), [])

    def test_sequence_gap_never_acknowledges(self):
        self.exp.last_seq = 5
        with self.assertRaisesRegex(lab.LabError, 'sequence'):
            self.exp.consume(1)
        self.assertEqual(self.hw.writes, [])

    def test_sequence_wrap_is_valid(self):
        self.exp.last_seq = 0xffffffff
        self.exp.consume(1)
        self.assertEqual(self.exp.last_seq, 0)

    def test_illegal_head_address_or_length_never_acknowledges(self):
        for key, value in (('0x18', 0x8000), ('0x18', 0x100010), ('0x1c', 16)):
            old = self.hw.regs.copy()
            self.hw.regs[key] = value
            with self.assertRaises(lab.LabError):
                self.exp.consume(1)
            self.assertEqual(self.hw.writes, [])
            self.hw.regs = old

    def test_configuration_restores_original_values_without_start(self):
        self.exp.config()
        self.assertEqual((self.hw.rd(0x24), self.hw.rd(0x28)), (0x8000, 0x8000))
        self.assertFalse(any(offset == 0x20 for offset, _ in self.hw.writes))

    def test_old_queue_is_not_blindly_drained(self):
        with self.assertRaisesRegex(lab.LabError, 'Old blocks'):
            self.exp.preflight()
        self.assertEqual(self.hw.writes, [])

    def test_default_snapshot_excludes_read_clear(self):
        self.assertNotIn(0x10, lab.SAFE_REGS)
        self.assertNotIn(0x14, lab.SAFE_REGS)

    def test_actual_dma_wrapper_short_transfer_is_not_retried(self):
        hw = lab.Hardware.__new__(lab.Hardware)
        hw.args = argparse.Namespace(exclusive=True, dma_timeout=0.01)
        hw.report = self.report
        hw.devices = {'c2h_0': Path('/dev/fake_c2h')}
        result = subprocess.CompletedProcess([], 5, '{"completed":8,"requested":16}', 'short')
        with mock.patch.object(lab.subprocess, 'run', return_value=result) as run:
            with self.assertRaisesRegex(lab.LabError, 'short'):
                hw.dma('c2h', 0x100000, 16, self.path/'unused')
            self.assertEqual(run.call_count, 1)

    def test_actual_dma_wrapper_timeout_is_not_retried(self):
        hw = lab.Hardware.__new__(lab.Hardware)
        hw.args = argparse.Namespace(exclusive=True, dma_timeout=0.01)
        hw.report = self.report
        hw.devices = {'c2h_0': Path('/dev/fake_c2h')}
        with mock.patch.object(lab.subprocess, 'run', side_effect=subprocess.TimeoutExpired('dma', .01)) as run:
            with self.assertRaisesRegex(lab.LabError, 'timeout'):
                hw.dma('c2h', 0x100000, 16, self.path/'unused')
            self.assertEqual(run.call_count, 1)

    def test_uncertain_ack_write_is_never_retried(self):
        hw = lab.Hardware.__new__(lab.Hardware)
        hw.args = argparse.Namespace(exclusive=True, state_timeout=0.01)
        hw.report, hw.io, hw.base = self.report, 'fake_io', 0xf0200000
        with mock.patch.object(lab.subprocess, 'run', side_effect=subprocess.TimeoutExpired('io', .01)) as run:
            with self.assertRaisesRegex(lab.LabError, 'no retry'):
                hw.wr(0x14, 1)
            self.assertEqual(run.call_count, 1)

    @unittest.skipIf(os.name == 'nt', 'Compile native helper on Linux/ARM')
    def test_real_c_helper_file_fixture_roundtrip_and_short_no_retry(self):
        binary = self.path/'rtds_dma'
        subprocess.run(['cc', '-std=c11', '-Wall', '-Wextra', '-Werror', str(ROOT/'arm'/'rtds_dma.c'),
                        '-o', str(binary)], check=True)
        dev, tx, rx = self.path/'fake_device', self.path/'tx', self.path/'rx'
        dev.write_bytes(b'\0'*64)
        tx.write_bytes(bytes(range(16)))
        one = subprocess.run([str(binary), 'h2c', str(dev), '16', '16', str(tx)], capture_output=True, text=True)
        self.assertEqual(one.returncode, 0, one.stderr)
        two = subprocess.run([str(binary), 'c2h', str(dev), '16', '16', str(rx)], capture_output=True, text=True)
        self.assertEqual(two.returncode, 0, two.stderr)
        self.assertEqual(rx.read_bytes(), tx.read_bytes())
        short = subprocess.run([str(binary), 'c2h', str(dev), '64', '16', str(self.path/'short')],
                               capture_output=True, text=True)
        self.assertEqual(short.returncode, 5)
        self.assertEqual(json.loads(short.stdout)['completed'], 0)
        self.assertFalse((self.path/'short').exists())
        bad = subprocess.run([str(binary), 'h2c', str(dev), '17', '16', str(tx)], capture_output=True)
        self.assertEqual(bad.returncode, 2)


if __name__ == '__main__':
    unittest.main(verbosity=2)
