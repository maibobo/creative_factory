# Minimal CONV_DMA Integration Simulation

This directory adds the lightweight integration layer:

`LocalLink BFM <-> fdma_aurora_pcie_conv_dma_wrapper <-> CONV_DMA <-> AXI RAM model`

Run order:

1. Run the original bridge regression through `regression/setup_vivado_sim.tcl`.
2. Source `regression/setup_integration_sim.tcl`.
3. In Vivado/XSim run:

```tcl
launch_simulation -simset sim_1 -mode behavioral
run all
```

For direct command-line XSim 2020.2, run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "..\..\regression\run_integration_xsim.ps1"
```

Detailed design and verification notes are in
`fdma_aurora_pcie_conv_dma_integration_design_verification.md`.

The integration testbench checks:

- `fdma_rsize/fdma_wsize = 64` beats for each 512B frame.
- Raw bridge write size remains 512 bytes for legacy debug compatibility.
- AXI `AWLEN/ARLEN = 63`, `AWSIZE/ARSIZE = 3`, so each frame is 64 x 64-bit beats.
- RX LocalLink input writes frames into AXI RAM in order.
- TX reads AXI RAM data and emits LocalLink `SOF/EOF/REM/data`.
- 8KB address window wraps after 16 x 512B frames.
- AXI write/read stalls and TX `dst_rdy` stalls do not change data order.
- `rx_dst_rdy` stays asserted; RX FIFO pressure is reported through sticky status.
