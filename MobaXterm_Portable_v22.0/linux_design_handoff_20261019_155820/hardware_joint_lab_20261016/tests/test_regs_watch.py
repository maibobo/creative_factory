import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

spec=importlib.util.spec_from_file_location('regs_watch',Path(__file__).resolve().parent.parent/'arm/rtds_regs_watch.py')
viewer=importlib.util.module_from_spec(spec);spec.loader.exec_module(viewer)


class ViewerTests(unittest.TestCase):
    def test_idle_and_temperature_jitter_are_silent(self):
        old={o:0 for o,_,_ in viewer.REGS}
        new=dict(old);new[0x0c]=1
        self.assertEqual(viewer.change_output(new,old,['R SNAPSHOT unchanged'],1.0),'')
        self.assertIn('TEMP_RAW',viewer.change_output(new,old,[],1.0,True))

    def test_business_change_prints_only_affected_register(self):
        old={o:0 for o,_,_ in viewer.REGS}
        new=dict(old);new[0x30]=8
        output=viewer.change_output(new,old,[],2.0)
        self.assertIn('RX_BLOCKS',output)
        self.assertIn('00000000 -> 00000008',output)
        self.assertNotIn('DOWN_START_ADDR',output)
        self.assertNotIn('\x1b',output)

    def test_main_idle_does_not_reprint_baseline(self):
        values={o:0 for o,_,_ in viewer.REGS};values[0]=0x2001
        with mock.patch.object(viewer.shutil,'which',return_value='io'), \
             mock.patch.object(viewer,'discover_bar',return_value=('fake',0xf0200000)), \
             mock.patch.object(viewer,'sample',side_effect=[values,dict(values),KeyboardInterrupt]), \
             mock.patch.object(viewer.time,'sleep'), \
             mock.patch.object(viewer.sys,'stdout') as out:
            self.assertEqual(viewer.main(['--log','nonexistent_log']),0)
        rendered=''.join(str(c.args[0]) for c in out.write.call_args_list if c.args)
        self.assertEqual(rendered.count('RTDS register viewer'),1)
        self.assertNotIn('\x1b',rendered)

    def test_only_safe_individual_reads(self):
        calls=[]
        def run(argv,**kwargs):
            calls.append(argv)
            address=int(argv[-1],16)
            value=0x2001 if address==0xf0200000 else 0
            return subprocess.CompletedProcess(argv,0,stdout='%08x: %08x\n' % (address,value))
        with mock.patch.object(viewer.subprocess,'run',side_effect=run):
            values=viewer.sample(0xf0200000,'io')
        self.assertEqual(len(values),13)
        self.assertTrue(all(x[1:3]==['-4','-r'] for x in calls))
        self.assertNotIn(0xf0200010,[int(x[-1],16) for x in calls])
        self.assertNotIn(0xf0200014,[int(x[-1],16) for x in calls])

    def test_bad_identity_stops_after_first_read(self):
        with mock.patch.object(viewer.subprocess,'run',return_value=
                subprocess.CompletedProcess([],0,stdout='f0200000: ffffffff\n')) as run:
            with self.assertRaises(RuntimeError):
                viewer.sample(0xf0200000,'io')
            self.assertEqual(run.call_count,1)

    def test_zero_bar_refused(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'fake_bdf';p.mkdir()
            (p/'vendor').write_text('0x10ee');(p/'device').write_text('0x8032')
            (p/'resource').write_text('0 1000 200\n')
            with self.assertRaises(RuntimeError):
                viewer.discover_bar(Path(tmp))

    def test_journal_only_displays_events(self):
        self.assertIn('not completion proof',viewer.Journal.describe(
            dict(event='WRITE_INTENT',offset='0x14',value='0x1')))
        self.assertIsNone(viewer.Journal.describe(dict(event='EXECUTE',command='anything')))


if __name__=='__main__':
    unittest.main(verbosity=2)
