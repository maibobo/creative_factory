"""Layer 2: one-shot XDMA userspace transport.

The C helper is still the tested syscall boundary. This wrapper only chooses the
H2C/C2H node, launches one helper process, and validates its completion result.
It has no knowledge of RTDS register offsets or queue ACK semantics.
"""
import json
import subprocess
from pathlib import Path

from rtds_common import LabError


class XdmaTransport:
    def __init__(self, args, report, devices, helper=None):
        self.args = args
        self.report = report
        self.devices = devices
        self.helper = Path(helper) if helper else Path(__file__).parent / 'rtds_dma'

    def transfer(self, direction, address, size, path):
        if direction not in ('h2c', 'c2h'):
            raise LabError('Unsupported DMA direction: ' + str(direction))
        device = self.devices['h2c_0' if direction == 'h2c' else 'c2h_0']
        path = Path(path)
        command = [
            str(self.helper), direction, str(device),
            hex(address), str(size), str(path),
        ]
        self.report.log(
            'DMA_SUBMIT',
            direction=direction,
            card_address=hex(address),
            requested=size,
            data_file=path.name)
        try:
            process = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=self.args.dma_timeout)
        except subprocess.TimeoutExpired:
            raise LabError(
                'DMA timeout; queue is retained; no resubmit/acknowledgement')

        try:
            result = json.loads(process.stdout.strip())
        except ValueError:
            raise LabError(
                'DMA helper invalid output: %r %r' %
                (process.stdout, process.stderr))
        if not isinstance(result, dict):
            raise LabError('DMA helper output is not a JSON object')

        self.report.log(
            'DMA_RETURN', **result,
            returncode=process.returncode,
            stderr=process.stderr)
        if process.returncode or result.get('completed') != size:
            raise LabError('DMA failed/short; no acknowledgement')
        return result
