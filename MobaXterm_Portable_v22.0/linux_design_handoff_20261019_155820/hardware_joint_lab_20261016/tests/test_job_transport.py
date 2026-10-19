"""Transport input constraints and no-retry behavior; no SSH or hardware accessed."""
import sys
import unittest
from pathlib import Path
from unittest import mock
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/'pc'))
import lab_remote


class JobTransportTests(unittest.TestCase):
    uri='ssh://vivado-srv/C:/project/RTDS/DDR/lab/jobs/gui_20261019_test'

    def test_unsafe_paths_are_rejected(self):
        for uri in ('ssh://bad host/C:/project/RTDS/x','ssh://vivado-srv/C:/Windows',
                    'ssh://vivado-srv/C:/project/RTDS/../Windows',
                    "ssh://vivado-srv/C:/project/RTDS/x'y",
                    'ssh://vivado-srv/C:/project/RTDS/x?do=reset'):
            with self.assertRaises(RuntimeError):
                lab_remote.windows_job_url(uri)

    def test_remote_inspection_uses_verified_alias_and_no_retry(self):
        with mock.patch.object(lab_remote,'ssh_win',return_value='status=ok\nlive=191\n') as remote:
            result=lab_remote.hw_call(self.uri,'inspect')
            self.assertEqual(result['live'],'191')
            self.assertEqual(remote.call_count,1)
            self.assertEqual(remote.call_args.args[0],'vivado-srv')
            script=remote.call_args.args[1]
            self.assertIn('[IO.File]::Move',script)
            self.assertIn('inspect',script)

    def test_uncertain_injection_is_not_retried(self):
        with mock.patch.object(lab_remote,'ssh_win',side_effect=RuntimeError('transport lost')) as remote:
            with self.assertRaises(RuntimeError):
                lab_remote.hw_call(self.uri,'inject')
            self.assertEqual(remote.call_count,1)

    def test_invalid_operations_never_reach_ssh(self):
        with mock.patch.object(lab_remote,'ssh_win') as remote:
            for action,param in (('reset',None),('inject','twice'),('arm','anything'),('save','other')):
                with self.assertRaises(RuntimeError):
                    lab_remote.hw_call(self.uri,action,param)
            remote.assert_not_called()


if __name__=='__main__':
    unittest.main(verbosity=2)
