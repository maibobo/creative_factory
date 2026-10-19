"""Layer 3: RTDS register/DMA protocol and ownership rules.

This layer decides *when* DMA is legal, which FPGA card addresses are allowed,
when data is considered valid, and when a queue block may be acknowledged.
"""
import sys
import time

from rtds_common import (
    LabError, UP_BASE, UP_COUNT, UP_DATA, UP_STRIDE, compare_bytes)


class RtdsProtocol:
    def __init__(self, regs, dma, control, report, args):
        self.regs = regs
        self.dma = dma
        self.control = control
        self.report = report
        self.args = args
        self.baseline = None
        self.last_seq = None

    def health(self, values):
        if (values['0x0'] != 0x2001 or
                values['0x4'] != 0x20260914 or
                values['0x8'] != 0x40000):
            raise LabError('Identity registers mismatch')
        if values['0x2c'] & 3 != 3 or values['0x2c'] & 0x1c:
            raise LabError(
                'DDR is not ready or error flags are set; '
                'evidence retained, no clear')
        if values['0x20'] != 0:
            raise LabError('Downlink is busy')
        if self.baseline and values['0x38'] != self.baseline['0x38']:
            raise LabError('Dropped-word counter changed')

    def preflight(self):
        self.baseline = self.regs.snapshot('baseline')
        self.health(self.baseline)
        if self.baseline['0x30'] != 0:
            raise LabError(
                'Old blocks present. Do not blindly acknowledge; '
                'save and inspect first.')
        if self.baseline['0x38'] == 0xffffffff:
            raise LabError(
                'Drop counter saturated; cannot prove no new drops')
        self.report.log('DROP_BASELINE', value=self.baseline['0x38'])

    def _dma(self, direction, address, size, path):
        """Apply RTDS lab address/ownership policy before generic XDMA."""
        if not self.args.exclusive:
            raise LabError('DMA requires --exclusive')
        if direction == 'h2c' and (address != 0x8000 or size != 16):
            raise LabError(
                'Lab H2C is restricted to 16 bytes at 0x8000')
        if direction == 'c2h':
            uplink_slot = (
                UP_BASE <= address < UP_BASE + UP_COUNT * UP_STRIDE and
                (address - UP_BASE) % UP_STRIDE == 0)
            if address != 0x8000 and not uplink_slot:
                raise LabError('Lab C2H address outside test regions')
        return self.dma.transfer(direction, address, size, path)

    def config(self):
        old = (self.regs.rd(0x24), self.regs.rd(0x28))
        try:
            for address, length in ((0x8000, 0x10), (0x8010, 0x20)):
                self.regs.wait(0x20, 0)
                self.regs.wr(0x24, address)
                self.regs.wr(0x28, length)
                actual = (
                    self.regs.rd(0x24),
                    self.regs.rd(0x28),
                    self.regs.rd(0x20))
                if actual != (address, length, 0):
                    raise LabError('Configuration readback mismatch')
                self.report.log(
                    'CONFIG_VERIFIED',
                    address=hex(address),
                    length=length)
        finally:
            values = self.regs.snapshot('before_config_restore')
            self.health(values)
            self.regs.wr(0x24, old[0])
            self.regs.wr(0x28, old[1])
            if (self.regs.rd(0x24), self.regs.rd(0x28)) != old:
                raise LabError('Original configuration restore failed')
            self.report.log(
                'CONFIG_RESTORED',
                address=hex(old[0]),
                length=old[1])

    def ddr(self):
        if self.args.no_jtag:
            self.report.log(
                'JTAG_NOT_USED',
                reason='Direct ARM H2C/C2H; '
                       'VIO/ILA validation is not claimed')
        else:
            self.control.call('inspect')

        pattern = bytes(range(16))
        tx = self.report.path / 'ddr_tx.bin'
        rx = self.report.path / 'ddr_rx.bin'
        tx.write_bytes(pattern)

        if self.args.capture:
            self.control.call('arm', test='dma_write')
        self._dma('h2c', 0x8000, 16, tx)

        if self.args.capture:
            self.control.call('save', kind='native')
            self.control.call('arm', test='dma_read')
        self._dma('c2h', 0x8000, 16, rx)

        received = rx.read_bytes()
        compare_bytes(pattern, received)
        self.report.log(
            'DATA_MATCH',
            effective=16,
            requested=16,
            data_hex=received.hex())
        if self.args.capture:
            self.control.call('save', kind='native')

    def inject(self, count):
        old_head = self.head() if count > 1 else None
        if self.args.capture:
            self.control.call('arm', test='fdma_up')
        self.control.call('inject')
        self.regs.wait(0x30, count)
        self.health(self.regs.snapshot('after_inject_%d' % count))
        if old_head is not None and self.head() != old_head:
            raise LabError('Head changed while another block was enqueued')
        if self.args.capture:
            self.control.call('save', kind='fdma')

    def head(self):
        return (
            self.regs.rd(0x18),
            self.regs.rd(0x1c),
            self.regs.rd(0x34))

    def consume(self, count, check_notify=False):
        for remaining in range(count, 0, -1):
            if self.regs.rd(0x30) != remaining:
                raise LabError('Unexpected queue count before read')

            address, effective, sequence = before = self.head()
            slot_ok = (
                UP_BASE <= address < UP_BASE + UP_COUNT * UP_STRIDE and
                (address - UP_BASE) % UP_STRIDE == 0)
            if effective != 8 or not slot_ok:
                raise LabError(
                    'Unexpected test-block address/length: %r' % (before,))
            if (self.last_seq is not None and
                    sequence != ((self.last_seq + 1) & 0xffffffff)):
                raise LabError('Block sequence discontinuity')

            if check_notify and remaining == count:
                deadline = time.monotonic() + 1.0
                while time.monotonic() < deadline:
                    if (self.head() != before or
                            self.regs.rd(0x30) != remaining):
                        raise LabError(
                            'Unacknowledged head/count changed')
                    time.sleep(0.05)
                self.health(
                    self.regs.snapshot('before_notification_clear'))
                notification = self.regs.rd(0x10, read_clear=True)
                self.report.log(
                    'READ_CLEAR_ONCE',
                    offset='0x10',
                    value=notification)
                if notification & 1 != 1:
                    raise LabError(
                        'Expected user notification bit absent; '
                        'check other consumers')
                if (self.head() != before or
                        self.regs.rd(0x30) != remaining):
                    raise LabError(
                        'Notification clear released or changed queue head')

            rx = self.report.path / (
                'up_%03d_seq_%08x.bin' %
                (len(self.report.doc['blocks']), sequence))
            result = self._dma('c2h', address, 16, rx)
            received = rx.read_bytes()
            compare_bytes(UP_DATA, received[:effective])

            self.health(self.regs.snapshot('before_ack'))
            if self.head() != before or self.regs.rd(0x30) != remaining:
                raise LabError(
                    'Queue changed during DMA; no acknowledgement')

            block = {
                'address': hex(address),
                'sequence': sequence,
                'effective': effective,
                'requested': 16,
                'completed': result['completed'],
                'data_hex': received[:effective].hex(),
                'file': rx.name,
                'ack_intent': False,
                'ack_confirmed': False,
            }
            self.report.doc['blocks'].append(block)
            block['ack_intent'] = True
            self.report.log(
                'BLOCK_DATA_VERIFIED', block=block.copy())

            self.regs.wr(0x14, 1)
            self.regs.wait(0x30, remaining - 1)
            block['ack_confirmed'] = True
            self.last_seq = sequence
            self.report.log(
                'BLOCK_ACK_CONFIRMED',
                sequence=sequence,
                remaining=remaining - 1)

        if self.regs.rd(0x18) != 0 or self.regs.rd(0x1c) != 0:
            raise LabError(
                'Empty queue did not clear head address/length')

    def up(self, multi=False):
        self.control.call('inspect')
        saved_config = (self.regs.rd(0x24), self.regs.rd(0x28))

        for batch_size in ((2, 8, 2) if multi else (1,)):
            for count in range(1, batch_size + 1):
                self.inject(count)
            self.consume(batch_size, check_notify=True)
            self.report.log(
                'QUEUE_BATCH_VERIFIED', blocks=batch_size)

        if (self.regs.rd(0x24), self.regs.rd(0x28)) != saved_config:
            raise LabError('Uplink changed downlink configuration')

        if multi:
            addresses = [
                int(block['address'], 16)
                for block in self.report.doc['blocks']]
            if len(set(addresses)) != 8:
                raise LabError('Did not exercise all 8 ring slots')
            self.report.log(
                'RING_WRAP_VERIFIED',
                total_blocks=len(addresses),
                distinct_slots=8)

    def run(self):
        self.preflight()
        case = self.args.case

        if case == 'config':
            self.config()
        elif case == 'ddr':
            self.ddr()
        elif case in ('single', 'multi'):
            self.up(case == 'multi')
        elif case == 'env':
            self.report.log(
                'ENVIRONMENT_VERIFIED',
                python=sys.version.split()[0],
                io=self.regs.io)
        elif case == 'regs':
            self.report.log('REGISTERS_VERIFIED')

        self.health(self.regs.snapshot('final'))
        if self.regs.rd(0x30) != 0:
            raise LabError('Queue is not empty at experiment end')
        if (case in ('ddr', 'single', 'multi') and
                not self.args.no_jtag):
            self.control.call('snapshot')
