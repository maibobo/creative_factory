# VALIDATION_SUMMARY

- Category: `aurora`
- Source: `R:\aurora_8b10b_1p25g_2020_2_verified\reports\VALIDATION_SUMMARY.md`
- SHA-256: `65bf26fd8e23fdedd3271f214d506c9666afc03f32fbf677359f3e221e2383e0`
- Extractor: `text`
- Tags: `1.25g, 8b10b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

# Aurora 8B/10B 1.25G validation summary

Date: 2026-08-10
Tool: Vivado 2020.2
Project: `design/aurora_8b10b_1p25g_design.xpr`

## Result

- Unified public interface audit: PASS.
- Full design compile/elaboration with the actual Aurora XCI: PASS.
- Single-point interface simplification simulation: PASS (`INTERFACE_SIM_PASS`).
- XCI configuration comparison after normalizing project-local `RUNTIME_PARAM.OUTPUTDIR`: PASS.
- The authoritative XDC and its design/verification copies have identical SHA-256.
- Both design and verification XPRs contain the authoritative XDC copy. It is active for the official verification exdes top and retained as a disabled board-level reference in the reusable design project because their top-level clock port shapes differ.
- Synthesis, implementation, timing, DRC and bitstream: NOT RUN, by request.
- Full official dual-endpoint regression: NOT REPEATED; it was completed before this interface-only change.

## Interface change

Public status is now limited to `user_clk_out`, `system_reset_out`, `channel_up` and `rx_crc_error`. `reset` and `gt_reset` remain separate inputs. `loopback` and `power_down` are fixed internally to `3'b000` and `1'b0`. Lane, raw error/CRC and GT startup diagnostics are no longer public ports; the official verification project still contains the native status signals, including the 8B/10B-only `frame_err`.

`rx_crc_error` is asserted only for `crc_valid_i && !crc_pass_fail_n_i`. RX has no ready input.

## Why USER_CLK is 31.25 MHz

The 32-bit interface carries four 8-bit characters per cycle. 8B/10B encoding transmits ten serial bits per character, so each user cycle corresponds to 40 line bits:

`USER_CLK = 1.25 GHz / (4 x 10) = 31.25 MHz`

The effective user data rate is `32 x 31.25 MHz = 1.0 Gb/s`. The 125 MHz clock is the GT reference clock.

## Evidence

- `reports/1g_compile_elaboration.log`
- `reports/1g_compile_elaboration.txt`
- `reports/interface_simplification_simulation.txt`
- `reports/unified_interface_audit.txt`
- `reports/current_configuration_audit.txt`
- `reports/1g_xdc_import.txt`
- `reports/XCI_XDC_HASHES.txt`
