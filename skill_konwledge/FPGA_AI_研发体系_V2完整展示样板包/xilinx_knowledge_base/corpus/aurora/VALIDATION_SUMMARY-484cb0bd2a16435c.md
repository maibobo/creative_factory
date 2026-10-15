# VALIDATION_SUMMARY

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\reports\VALIDATION_SUMMARY.md`
- SHA-256: `484cb0bd2a16435cb75d2b26f83637564582858f72d00520a0e0a57bbaa310cd`
- Extractor: `text`
- Tags: `10.3125g, 64b66b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

# Aurora 64B/66B 10.3125G validation summary

Date: 2026-08-10
Tool: Vivado 2020.2
Project: `design/aurora_64b66b_10p3125g_design.xpr`

## Result

- Unified public interface audit: PASS.
- Full design compile/elaboration with the actual Aurora XCI: PASS.
- Single-point interface simplification simulation: PASS (`INTERFACE_SIM_PASS`).
- XCI configuration comparison after normalizing project-local `RUNTIME_PARAM.OUTPUTDIR`: PASS.
- Original XDC in `design/imports` and `verification/imports`: identical SHA-256.
- Synthesis, implementation, timing, DRC and bitstream: NOT RUN, by request.
- Full official dual-endpoint regression: NOT REPEATED; it was completed before this interface-only change.

## Interface change

Public status is now limited to `user_clk_out`, `system_reset_out`, `channel_up` and `rx_crc_error`. `reset` and `gt_reset` remain separate inputs; for 10G, `gt_reset` drives `PMA_INIT`. `lane_up`, `hard_err`, `soft_err` and the raw CRC pair remain internal to the design/example layer.

`rx_crc_error` is asserted only for `crc_valid_i && !crc_pass_fail_n_i`. RX has no ready input.

## Clock

`USER_CLK = 10.3125 GHz / 64 = 161.1328125 MHz`. The 156.25 MHz value is the 66-bit block rate/reference-clock value, not the 64-bit user-interface clock.

## Evidence

- `reports/10g_compile_elaboration.log`
- `reports/10g_compile_elaboration.txt`
- `reports/interface_simplification_simulation.log`
- `reports/interface_simplification_simulation.txt`
- `reports/unified_interface_audit.txt`
- `reports/current_configuration_audit.txt`
- `reports/XCI_XDC_HASHES.txt`
