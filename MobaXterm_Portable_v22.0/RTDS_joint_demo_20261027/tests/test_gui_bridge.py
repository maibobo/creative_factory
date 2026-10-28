"""Lightweight Tcl interpreter tests. No Vivado, windows, or hardware is opened."""
import tempfile
import tkinter
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


class GuiBridgeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.t = tkinter.Tcl()
        self.t.call('source', str(ROOT/'vivado'/'gui_bridge.tcl'))
        self.t.setvar('::rtds_demo_gui::root', str(Path(self.tmp.name)))
        self.t.eval('''
            set ::inspections 0
            set ::injections 0
            rename ::rtds_lab::inspect ::rtds_lab::inspect_real
            proc ::rtds_lab::inspect {} {
                incr ::inspections
                return [dict create busy 0 accepted 0 rx_status 3 blocks 0 live 191]
            }
            rename ::rtds_lab::inject ::rtds_lab::inject_real
            proc ::rtds_lab::inject {} {
                incr ::injections
                return [dict create busy 0 accepted 2 rx_status 11 blocks 1 live 447]
            }
            proc current_hw_device {} {return fake_device}
        ''')

    def tearDown(self):
        self.t.call('::rtds_demo_gui::stop')
        self.tmp.cleanup()

    def start(self):
        return Path(str(self.t.call('::rtds_demo_gui::start')))

    def poll(self):
        timer = self.t.getvar('::rtds_demo_gui::timer')
        if timer:
            self.t.call('after', 'cancel', timer)
        self.t.call('::rtds_demo_gui::poll')

    def test_source_only_does_not_read_or_write_hardware(self):
        self.assertEqual(int(self.t.getvar('::rtds_demo_gui::active')), 0)
        self.assertEqual(int(self.t.getvar('::inspections')), 0)
        self.assertEqual(int(self.t.getvar('::injections')), 0)

    def test_start_and_stop_preserve_gui_connection(self):
        jobs = self.start()
        self.assertTrue((jobs/'service.ready').exists())
        self.assertIn('mode=existing_gui', (jobs/'service.ready').read_text())
        self.assertEqual(self.start(), jobs)
        self.assertEqual(int(self.t.getvar('::inspections')), 1)
        self.t.call('::rtds_demo_gui::stop')
        self.assertFalse((jobs/'service.ready').exists())
        self.assertTrue((jobs/'service.stopped').exists())
        self.assertEqual(self.t.call('current_hw_device'), 'fake_device')

    def test_injection_request_is_not_reexecuted(self):
        jobs = self.start()
        (jobs/'one.request').write_text('inject\n')
        self.poll()
        self.assertTrue((jobs/'one.done').exists())
        self.assertIn('status=ok', (jobs/'one.response').read_text())
        self.assertEqual(int(self.t.getvar('::injections')), 1)
        self.poll()
        self.assertEqual(int(self.t.getvar('::injections')), 1)

    def test_unknown_or_extra_tokens_do_not_execute(self):
        jobs = self.start()
        for i, command in enumerate(('reset', 'inject extra', 'inject; puts BAD')):
            (jobs/('bad%d.request' % i)).write_text(command)
            self.poll()
            self.assertIn('status=error', (jobs/('bad%d.response' % i)).read_text())
        self.assertEqual(int(self.t.getvar('::injections')), 0)

    def test_claimed_uncertain_request_is_not_requeued(self):
        jobs = self.start()
        (jobs/'uncertain.working').write_text('inject')
        self.poll()
        self.assertEqual(int(self.t.getvar('::injections')), 0)
        self.assertTrue((jobs/'uncertain.working').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
