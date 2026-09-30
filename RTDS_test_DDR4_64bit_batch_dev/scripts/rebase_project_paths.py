from pathlib import Path

root = Path(r"C:\project\RTDS\DDR\RTDS_test_DDR4_64bit")
xpr = root / "RTDS_test.xpr"
text = xpr.read_text(encoding="utf-8")
old = text
text = text.replace('Path="E:/PCIE-CPU/RTDS_test-1ch/RTDS_test.xpr"',
                    'Path="C:/project/RTDS/DDR/RTDS_test_DDR4_64bit/RTDS_test.xpr"')
text = text.replace('$PPRDIR/../fdma_aurora_brg',
                    '$PPRDIR/external_snapshot/fdma_aurora_brg')
if text == old:
    raise SystemExit("No XPR path replacements applied")
if 'E:/PCIE-CPU' in text or '$PPRDIR/../fdma_aurora_brg' in text:
    raise SystemExit("External baseline reference remains")
xpr.write_text(text, encoding="utf-8", newline="\n")
print("REBASED", xpr)