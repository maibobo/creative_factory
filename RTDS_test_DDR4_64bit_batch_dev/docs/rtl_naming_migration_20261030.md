# RTL naming migration: CONV_DMA -> ddr_axi_dma_bridge

Date: 2026-10-30
Repository: maibobo/creative_factory
Branch: codex/rtds-protocol-naming-20261030
Functional baseline: feature/aurora-format-debug-v2.02-20261029 / af3de6d076dc049307322bd1a28335a310d0eb0d

## Scope

Rename the generic AXI memory bridge previously named CONV_DMA to ddr_axi_dma_bridge, clarify its request-side port and state names, update the Vivado source-file reference, and provide a Tcl flow that recreates the Block Design module-reference cell.

This migration is naming/comment/reference work only. It does not change the wire protocol, packet format, AXI transaction rules, state transition conditions, CDC, FIFO behavior, ready/valid handshake conditions, or verification criteria.

## Verified RTL equivalence

The renamed RTL was compared against the baseline CONV_DMA.v after applying the 44-entry identifier mapping. After stripping line comments and normalizing whitespace, the HDL code was equivalent at the token-text level. The later edits in this branch are limited to four internal identifier cleanups and comments:

- s_axi_w_accept_event -> m_axi_w_handshake
- s_axi_r_accept_event -> m_axi_r_handshake
- calculate_write_next_st -> calculate_write_next_state
- calculate_read_next_st -> calculate_read_next_state

No simulation, synthesis, implementation, or bitstream generation was run in this session.

## Files

| Status | Path | Purpose |
|---|---|---|
| Renamed earlier in this branch | RTDS_test_DDR4_64bit.srcs/sources_1/new/CONV_DMA.v -> RTDS_test_DDR4_64bit.srcs/sources_1/new/ddr_axi_dma_bridge.v | Module/file and request-side identifier rename; behavior preserved |
| Updated | RTDS_test_DDR4_64bit.xpr | Source-file reference points to ddr_axi_dma_bridge.v |
| Added | scripts/migrations/conv_dma_to_ddr_axi_dma_bridge.mapping.json | Full identifier, port, BD-cell, and comment mapping |
| Added | scripts/migrations/apply_ddr_axi_dma_bridge_rename.py | Idempotent local source/XPR migration script; dry-run by default |
| Added | scripts/update_ddr_axi_dma_bridge_bd.tcl | Recreates BD module-ref cell and reconnects all mapped pins plus M_AXI |
| Updated | scripts/refresh_batch_bd.tcl | Backward-compatible entry point to the new Tcl |
| Added | docs/rtl_naming_migration_20261030.md | This file manifest and review record |

## Block Design update

design_1.bd is intentionally not edited as raw JSON. It still contains the old CONV_DMA_0 module-ref cell until the new Tcl is run in Vivado 2020.2. The Tcl:

1. Removes the old hand-written RTL source entry and adds ddr_axi_dma_bridge.v.
2. Captures the external net endpoints and the inferred M_AXI interface connection.
3. Replaces CONV_DMA_0 with ddr_axi_dma_bridge_0.
4. Reconnects the 19 request/clock/reset pins using the reviewed mapping.
5. Preserves the existing INFO_EXCH_0 configuration, status ports, and AXI address range.
6. Validates and saves the BD, regenerates BD targets, exports BD user files, and recreates the BD wrapper.

Run from the project root or any working directory:

    vivado.bat -mode batch -source .\scripts\update_ddr_axi_dma_bridge_bd.tcl

The Tcl is designed to be idempotent after the new cell has been created. It does not launch simulation, synthesis, implementation, or bitstream generation.

## External interface compatibility

- The PCIe adapter-facing BD ports retain their existing fdma_* names. This avoids changing the adapter and PCIe.v contract in this task.
- The bridge's internal request pins use generic wr_* / rd_* names.
- The M_AXI master interface and all M_AXI_* AXI signal names remain unchanged.
- The old fdma_wready input maps to wr_data_valid; the old fdma_wvalid output maps to wr_data_accept_event. Their directions and handshake meanings are preserved.
- The old fdma_rready input maps to rd_data_ready; the old fdma_rvalid output maps to rd_data_accept_event.

## Explicitly excluded

No changes were made to:
- regression/** testbenches, expected-format fixtures, or the five-run regression runner;
- historical backups, logs, waveforms, or simulation databases;
- vendor-generated IP source files;
- unrelated RTL, protocol definitions, or the seven V2.02 hand-imported handwritten sources.

## Current status and handoff

The GitHub branch contains the RTL rename, source reference update, mapping, application script, and BD regeneration Tcl. The checked-in design_1.bd and generated wrapper are not claimed to be regenerated yet; run the Tcl in the restored local Vivado 2020.2 environment before the next session performs expected-format and five-run regression verification.

## Preserved legacy references

The older regression/verify_rtds_integration.tcl still contains /CONV_DMA_0/M_AXI, but that script opens the legacy RTDS_test.xpr rather than the active RTDS_test_DDR4_64bit.xpr in this project. It was intentionally left untouched to avoid changing a legacy verification flow outside this migration scope.

The generated XPR file-set/run names that still contain design_1_CONV_DMA_0_0 are also left for Vivado to regenerate when the BD Tcl is run; they are not manually edited.
