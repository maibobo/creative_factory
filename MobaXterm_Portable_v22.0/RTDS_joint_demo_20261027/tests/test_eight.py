"""Exercise queue ordering and failure handling without hardware or network."""
import argparse
import importlib.util
import os
from pathlib import Path
import sys
import tempfile
import types
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parent.parent
if os.name == 'nt':
    sys.modules.setdefault('fcntl', types.SimpleNamespace())
spec = importlib.util.spec_from_file_location('rtds_lab', ROOT / 'arm' / 'rtds_lab.py')
lab = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lab)


class Report:
    def __init__(self, path):
        self.path = path
        self.doc = {'blocks': [], 'steps': []}
    def log(self, event, **fields):
        self.doc['steps'].append({'event': event, **fields})


class Hardware:
    def __init__(self):
        self.queue = []
        self.sequence = 0
        self.acks = []
        self.reads = []
        self.fail_dma = False
    def rd(self, offset, read_clear=False):
        self.reads.append(offset)
        if offset == 0x10:
            assert read_clear
            return 1
        base = {0x00: 0x2001, 0x04: 0x20260914, 0x08: 0x40000,
                0x20: 0, 0x24: 0x8000, 0x28: 0x8000, 0x2c: 3,
                0x30: len(self.queue), 0x38: 0}
        if offset in (0x18, 0x1c, 0x34):
            return self.queue[0][(0x18, 0x1c, 0x34).index(offset)] if self.queue else 0
        return base[offset]
    def wr(self, offset, value):
        assert (offset, value) == (0x14, 1)
        self.acks.append(self.queue.pop(0))
    def wait(self, offset, value):
        if self.rd(offset) != value:
            raise lab.LabError('unexpected state')
    def snapshot(self, label):
        return {hex(i): self.rd(i) for i in (0, 4, 8, 0x20, 0x24, 0x28, 0x2c, 0x30, 0x38)}
    def dma(self, direction, address, size, path):
        if self.fail_dma:
            raise lab.LabError('DMA failed/short')
        assert direction == 'c2h' and size == 16
        path.write_bytes(lab.UP_DATA + b'\x00' * 8)
        return {'completed': 16}


class Control:
    def __init__(self, hw):
        self.hw = hw
        self.calls = []
    def call(self, action, **params):
        self.calls.append((action, params))
        if action == 'inject':
            seq = self.hw.sequence
            self.hw.queue.append((lab.UP_BASE + (seq % 8) * lab.UP_STRIDE, 8, seq))
            self.hw.sequence += 1
        return {'status': 'ok'}


class EightTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.report = Report(Path(self.temp.name))
        self.hw = Hardware()
        self.control = Control(self.hw)
        self.args = argparse.Namespace(capture=True, capture_reads=True, dwell=2)
        self.exp = lab.Experiments(self.hw, self.control, self.report, self.args)
        self.exp.baseline = self.hw.snapshot('baseline')
    def tearDown(self):
        self.temp.cleanup()
    def test_eight_slots_capture_and_safe_ack(self):
        with mock.patch.object(lab.time, 'sleep') as sleep:
            self.exp.up(eight=True)
        self.assertEqual(len(self.hw.acks), 8)
        self.assertEqual(len(set(x[0] for x in self.hw.acks)), 8)
        self.assertEqual([x[2] for x in self.hw.acks], list(range(8)))
        self.assertEqual(sum(c[0] == 'inject' for c in self.control.calls), 8)
        self.assertEqual(sum(c == ('arm', {'test': 'dma_read'}) for c in self.control.calls), 8)
        self.assertEqual(sum(c == ('arm', {'test': 'fdma_up'}) for c in self.control.calls), 8)
        self.assertEqual(sum(x == 0x10 for x in self.hw.reads), 1)
        self.assertEqual(sum(call.args == (2,) for call in sleep.call_args_list), 16)
        self.assertTrue(all(b['ack_confirmed'] for b in self.report.doc['blocks']))
    def test_dma_failure_never_acknowledges(self):
        self.hw.fail_dma = True
        with mock.patch.object(lab.time, 'sleep'):
            with self.assertRaisesRegex(lab.LabError, 'DMA failed'):
                self.exp.up(eight=True)
        self.assertEqual(len(self.hw.queue), 8)
        self.assertEqual(self.hw.acks, [])
    def test_continuous_mode_has_no_deliberate_dwell(self):
        self.args.capture = self.args.capture_reads = False
        self.args.dwell = 0
        with mock.patch.object(lab.time, 'sleep') as sleep:
            self.exp.up(eight=True)
        # The notification stability check sleeps; it is not demonstration pacing.
        self.assertFalse(any(s.get('event') == 'DEMO_HOLD' for s in self.report.doc['steps']))
        self.assertFalse(any(action in ('arm', 'save') for action, _ in self.control.calls))


if __name__ == '__main__':
    unittest.main()
