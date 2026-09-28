from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "evidence" / "v201_quick_wave_draft" / "raw"

for case_dir in sorted(p for p in ROOT.iterdir() if p.is_dir()):
    vcd = next(case_dir.glob("*_full.vcd"))
    scopes = []
    signals = []
    max_time = 0
    with vcd.open("r", encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            line = raw.strip()
            if line.startswith("$scope "):
                scopes.append(line.split()[2])
            elif line.startswith("$upscope"):
                if scopes:
                    scopes.pop()
            elif line.startswith("$var "):
                parts = line.split()
                signals.append((int(parts[2]), "/" + "/".join(scopes + [parts[4]])))
            elif line.startswith("#"):
                max_time = max(max_time, int(line[1:]))
    print(f"[{case_dir.name}] max_ps={max_time} signals={len(signals)}")
    for width, name in signals:
        if len(name.split("/")) <= 4:
            print(f"  {width:3d} {name}")
