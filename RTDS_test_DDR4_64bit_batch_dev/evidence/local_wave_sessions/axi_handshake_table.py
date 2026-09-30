"""Derive AXI rising-edge handshakes from axi.vcd for review notes.

Values are sampled 1 ps before each rising edge, so the table represents
the values that the sequential logic sees at that edge, not post-edge NBA.
"""
from bisect import bisect_right
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / "scripts"))
from build_offline_wave_viewers import read_events  # noqa: E402


def main():
    declarations, events = read_events(HERE / "axi" / "axi.vcd")
    cache = {}

    def sample(name, timestamp):
        if name not in cache:
            code, _ = declarations["/tb_rtds_axi/bus/" + name]
            sequence = events[code]
            cache[name] = ([item[0] for item in sequence], [item[1] for item in sequence])
        times, values = cache[name]
        pos = bisect_right(times, timestamp) - 1
        if pos < 0 or any(ch in values[pos] for ch in "xz"):
            return None
        return int(values[pos], 2)

    clock_code, _ = declarations["/tb_rtds_axi/M_AXI_ACLK"]
    clock_rises = [t for t, v in events[clock_code] if v == "1"]
    records = {key: [] for key in ("AW", "W_LAST", "B", "AR", "R_LAST", "FDMA_DONE")}
    w_count = r_count = 0
    hold = {"AW": {"stall_cycles": 0, "violations": []},
            "W": {"stall_cycles": 0, "violations": []}}
    previous = {}
    for t in clock_rises:
        s = t - 1
        if sample("M_AXI_ARESETN", s) != 1:
            previous = {}
            continue
        ns = t / 1000
        for channel, fields in (("AW", ("M_AXI_AWADDR", "M_AXI_AWLEN")),
                                ("W", ("M_AXI_WDATA", "M_AXI_WSTRB", "M_AXI_WLAST"))):
            valid = sample("M_AXI_" + channel + "VALID", s)
            ready = sample("M_AXI_" + channel + "READY", s)
            payload = tuple(sample(name, s) for name in fields)
            if channel in previous and previous[channel][0]:
                if valid != 1 or payload != previous[channel][1]:
                    hold[channel]["violations"].append(ns)
            stalled = valid == 1 and ready == 0
            if stalled:
                hold[channel]["stall_cycles"] += 1
            previous[channel] = (stalled, payload)
        if sample("M_AXI_AWVALID", s) == sample("M_AXI_AWREADY", s) == 1:
            records["AW"].append((ns, sample("M_AXI_AWADDR", s), sample("M_AXI_AWLEN", s) + 1))
        if sample("M_AXI_WVALID", s) == sample("M_AXI_WREADY", s) == 1:
            w_count += 1
            if sample("M_AXI_WLAST", s) == 1:
                records["W_LAST"].append((ns, w_count, sample("M_AXI_WDATA", s)))
                w_count = 0
        if sample("M_AXI_BVALID", s) == sample("M_AXI_BREADY", s) == 1:
            records["B"].append((ns, sample("M_AXI_BRESP", s)))
        if sample("M_AXI_ARVALID", s) == sample("M_AXI_ARREADY", s) == 1:
            records["AR"].append((ns, sample("M_AXI_ARADDR", s), sample("M_AXI_ARLEN", s) + 1))
        if sample("M_AXI_RVALID", s) == sample("M_AXI_RREADY", s) == 1:
            r_count += 1
            if sample("M_AXI_RLAST", s) == 1:
                records["R_LAST"].append((ns, r_count, sample("M_AXI_RDATA", s)))
                r_count = 0
        if sample("fdma_wdone", s) == 1:
            records["FDMA_DONE"].append(ns)
    for kind, rows in records.items():
        print("\n{} count={}".format(kind, len(rows)))
        for index, row in enumerate(rows):
            if kind in ("AW", "AR"):
                print("{:2d} {:8.1f} ns addr=0x{:08X} beats={}".format(index, *row))
            elif kind in ("W_LAST", "R_LAST"):
                print("{:2d} {:8.1f} ns beats={} last_data=0x{:016X}".format(index, *row))
            elif kind == "B":
                print("{:2d} {:8.1f} ns BRESP={}".format(index, *row))
            else:
                print("{:2d} {:8.1f} ns".format(index, row))
    print("\nHOLD checks")
    for channel, info in hold.items():
        print("{} stalled rising edges={} hold violations={}".format(
            channel, info["stall_cycles"], info["violations"]))
    crossings = [(ns, address, beats) for ns, address, beats in records["AW"]
                 if (address & 0xfff) + beats * 8 > 4096]
    print("AW 4KiB crossings={}".format(crossings))


if __name__ == "__main__":
    main()
