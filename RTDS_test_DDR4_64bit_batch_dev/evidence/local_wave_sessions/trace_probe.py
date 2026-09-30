"""Read local VCD evidence for a bounded time interval (no simulator required).

Usage: python trace_probe.py ring 0 100 bus/frame_valid U_DUT/pair_start
Times passed on the command line are ns; VCD timestamps are ps.
"""
from bisect import bisect_right
from pathlib import Path
import argparse
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / "scripts"))
from build_offline_wave_viewers import read_events  # noqa: E402


def decode(value, width):
    if value is None:
        return "?"
    if any(ch in value for ch in "xz"):
        return value
    if width == 1:
        return value
    number = int(value, 2)
    return "0x{:0{}X} ({})".format(number, max(1, (width + 3) // 4), number)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("case", choices=("ring", "axi", "regs"))
    parser.add_argument("start_ns", type=float)
    parser.add_argument("end_ns", type=float)
    parser.add_argument("signals", nargs="+")
    parser.add_argument("--rise-only", action="store_true")
    parser.add_argument("--fall-only", action="store_true")
    parser.add_argument("--snapshot", action="store_true")
    args = parser.parse_args()
    declarations, events = read_events(HERE / args.case / (args.case + ".vcd"))
    root = "/tb_rtds_" + args.case + "/"
    selected = {}
    for name in args.signals:
        path = name if name.startswith("/") else root + name
        if path not in declarations:
            raise SystemExit("Signal absent from VCD: " + path)
        code, width = declarations[path]
        selected[name] = (events[code], width)
    start = round(args.start_ns * 1000)
    end = round(args.end_ns * 1000)
    if args.snapshot:
        for name, (series, width) in selected.items():
            times = [event[0] for event in series]
            index = bisect_right(times, start) - 1
            value = series[index][1] if index >= 0 else None
            print("{}ns {}={}".format(args.start_ns, name, decode(value, width)))
        return
    changes = []
    for name, (series, width) in selected.items():
        for timestamp, value in series:
            if start <= timestamp <= end:
                if args.rise_only and value != "1":
                    continue
                if args.fall_only and value != "0":
                    continue
                changes.append((timestamp, name, decode(value, width)))
    for timestamp, name, value in sorted(changes):
        print("{:>11.3f} ns  {:<36} {}".format(timestamp / 1000, name, value))


if __name__ == "__main__":
    main()
