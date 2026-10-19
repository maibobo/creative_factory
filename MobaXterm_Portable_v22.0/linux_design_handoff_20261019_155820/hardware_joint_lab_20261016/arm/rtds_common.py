"""Shared constants and side-effect-free helpers for RTDS ARM tools."""
import json
import re
from pathlib import Path

SAFE_REGS = (0x00, 0x04, 0x08, 0x0c, 0x18, 0x1c, 0x20, 0x24, 0x28,
             0x2c, 0x30, 0x34, 0x38)
UP_DATA = bytes.fromhex('11 00 00 00 22 00 00 00')
UP_BASE, UP_STRIDE, UP_COUNT = 0x100000, 0x40000, 8


class LabError(RuntimeError):
    """Controlled RTDS lab failure."""


def atomic_json(path, value):
    path = Path(path)
    tmp = path.with_suffix('.tmp')
    tmp.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')
    tmp.replace(path)


def parse_io(text, address):
    """Parse one exact 32-bit `io -4 -r` result for the requested address."""
    found = re.findall(
        r'^\s*(?:0x)?([0-9a-fA-F]+):\s+(?:0x)?([0-9a-fA-F]{1,8})\s*$',
        text, re.M)
    matches = [int(v, 16) for a, v in found if int(a, 16) == address]
    if len(matches) != 1:
        raise LabError('Cannot parse io read at 0x%x: %r' % (address, text))
    return matches[0]


def compare_bytes(expected, actual):
    if len(expected) != len(actual):
        raise LabError('Data length mismatch: expected=%d actual=%d' %
                       (len(expected), len(actual)))
    for i, (want, got) in enumerate(zip(expected, actual)):
        if want != got:
            raise LabError(
                'Data mismatch offset=0x%x expected=%02x actual=%02x' %
                (i, want, got))
