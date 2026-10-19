"""Layer 1: PCIe endpoint discovery and FPGA BAR register access.

This module does not submit DMA and contains no RTDS queue/business protocol.
"""
import os
import shutil
import stat
import subprocess
import time
from pathlib import Path

from rtds_common import LabError, SAFE_REGS, parse_io


class PcieEndpoint:
    """Resolve one Xilinx endpoint and its XDMA character devices."""

    def __init__(self, args, report):
        self.args = args
        self.report = report
        root = Path(args.sysfs)
        candidates = []
        for path in root.iterdir():
            try:
                vendor = (path / 'vendor').read_text().strip()
                device = (path / 'device').read_text().strip()
            except OSError:
                continue
            if vendor == '0x10ee' and device == '0x8032':
                candidates.append(path)
        if args.bdf:
            candidates = [path for path in candidates if path.name == args.bdf]
        if len(candidates) != 1:
            raise LabError(
                'Expected one 10ee:8032 endpoint, found %d; select --bdf' %
                len(candidates))

        self.pci = candidates[0]
        first = (self.pci / 'resource').read_text().splitlines()[0].split()
        self.base, end, flags = [int(value, 16) for value in first]
        if self.base == 0 or end - self.base + 1 < 0x3c or not flags & 0x200:
            raise LabError('Invalid BAR0 memory resource')

        driver = self.pci / 'driver'
        if not driver.is_symlink() or driver.resolve().name != 'xdma':
            raise LabError('Endpoint is not bound to xdma')

        self.devices = {
            name: Path(args.dev_root) / ('xdma%d_%s' % (args.device_index, name))
            for name in ('user', 'h2c_0', 'c2h_0')
        }
        self._verify_nodes()
        self.reject_external_users()

        report.doc['endpoint'] = {
            'bdf': self.pci.name,
            'bar0': hex(self.base),
            'driver': driver.resolve().name,
            'nodes': {key: str(value) for key, value in self.devices.items()},
        }

    def _verify_nodes(self):
        for node in self.devices.values():
            if not node.exists() or not stat.S_ISCHR(node.stat().st_mode):
                raise LabError('XDMA character device missing: ' + str(node))

        for node in self.devices.values():
            st = node.stat()
            char_path = Path('/sys/dev/char') / (
                '%d:%d' % (os.major(st.st_rdev), os.minor(st.st_rdev)))
            if self.pci.name not in str(char_path.resolve()):
                raise LabError(
                    'Device node does not resolve to selected BDF: ' + str(node))

    def reject_external_users(self):
        identities = {
            (os.major(path.stat().st_rdev), os.minor(path.stat().st_rdev))
            for path in self.devices.values()
        }
        owners = []
        for proc in Path('/proc').iterdir():
            if not proc.name.isdigit() or int(proc.name) == os.getpid():
                continue
            try:
                for fd in (proc / 'fd').iterdir():
                    st = fd.stat()
                    if (stat.S_ISCHR(st.st_mode) and
                            (os.major(st.st_rdev), os.minor(st.st_rdev))
                            in identities):
                        owners.append(int(proc.name))
                        break
            except (OSError, PermissionError):
                continue
        if owners:
            raise LabError(
                'Other process owns XDMA nodes: %r. '
                'Stop the business program first.' % owners)


class RegisterAccess:
    """Safe BAR0 access. No DMA and no RTDS queue policy."""

    def __init__(self, endpoint, args, report):
        self.endpoint = endpoint
        self.args = args
        self.report = report
        self.base = endpoint.base
        self.io = shutil.which('io')
        if not self.io:
            raise LabError('io tool not found')

    def rd(self, offset, read_clear=False):
        if offset not in SAFE_REGS and not (offset == 0x10 and read_clear):
            raise LabError('Register read is not in safe allowlist')
        address = self.base + offset
        try:
            process = subprocess.run(
                [self.io, '-4', '-r', hex(address)],
                capture_output=True,
                text=True,
                timeout=self.args.state_timeout,
                check=True)
        except (subprocess.SubprocessError, OSError) as exc:
            raise LabError('io read failed: %s' % exc)
        return parse_io(process.stdout, address)

    def wr(self, offset, value):
        if not self.args.exclusive or offset not in (0x14, 0x24, 0x28):
            raise LabError(
                'Write requires --exclusive and an allowed register')
        self.report.log(
            'WRITE_INTENT', offset=hex(offset), value=hex(value), retry=False)
        try:
            subprocess.run(
                [self.io, '-4', '-w', hex(self.base + offset), hex(value)],
                capture_output=True,
                text=True,
                timeout=self.args.state_timeout,
                check=True)
        except (subprocess.SubprocessError, OSError) as exc:
            raise LabError(
                'io write failed/uncertain; no retry: %s' % exc)
        self.report.log('WRITE_RETURNED', offset=hex(offset))

    def snapshot(self, label):
        values = {hex(offset): self.rd(offset) for offset in SAFE_REGS}
        self.report.log('REGISTERS', label=label, values=values)
        return values

    def wait(self, offset, wanted):
        deadline = time.monotonic() + self.args.state_timeout
        last = None
        while time.monotonic() < deadline:
            last = self.rd(offset)
            if last == wanted:
                self.report.log(
                    'STATE_READY', offset=hex(offset), value=last)
                return last
            time.sleep(0.01)
        raise LabError(
            'State timeout offset=0x%x wanted=%d last=%r' %
            (offset, wanted, last))
