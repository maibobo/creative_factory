"""Check fixed ILA capabilities without hardware or Vivado."""
import tkinter
import unittest
from pathlib import Path


class IlaSettings(unittest.TestCase):
    def setUp(self):
        self.t = tkinter.Tcl()
        self.t.call('source', str(Path(__file__).resolve().parent.parent/'vivado'/'pcie_joint_debug_base.tcl'))
        self.t.eval('''
            set ::value BASIC_ONLY
            set ::writes 0
            set ::readonly 1
            proc get_property {property object} {return $::value}
            proc set_property {property value object} {
                incr ::writes
                if {$::readonly} {error {read-only property}}
                set ::value $value
            }
        ''')

    def test_already_correct_readonly_mode_is_not_written(self):
        self.t.call('::rtds_joint::require_setting', 'core', 'CONTROL.TRIGGER_MODE', 'BASIC_ONLY')
        self.assertEqual(int(self.t.getvar('::writes')), 0)

    def test_incompatible_readonly_mode_stops(self):
        with self.assertRaises(tkinter.TclError):
            self.t.call('::rtds_joint::require_setting', 'core', 'CONTROL.TRIGGER_MODE', 'ADVANCED_ONLY')

    def test_mutable_setting_written_and_checked(self):
        self.t.setvar('::readonly', 0)
        self.t.call('::rtds_joint::require_setting', 'core', 'CONTROL.TRIGGER_MODE', 'ADVANCED_ONLY')
        self.assertEqual(int(self.t.getvar('::writes')), 1)
        self.assertEqual(self.t.getvar('::value'), 'ADVANCED_ONLY')


if __name__ == '__main__':
    unittest.main(verbosity=2)
