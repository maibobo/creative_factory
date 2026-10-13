#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
profile="${1:-top}"
goal="${2:-cdc/cdc_setup_check}"
case "$profile" in top|one_g) ;; *) exit 2;; esac
case "$goal" in lint/lint_rtl|cdc/cdc_setup_check|cdc/clock_reset_integrity|cdc/cdc_verify_struct) ;; *) exit 2;; esac
: "${SPYGLASS_HOME:?Source your existing Synopsys environment first}"
mkdir -p logs
spyglass -batch -project "projects/$profile.prj" -goals "$goal" 2>&1 | tee "logs/${profile}_${goal//\//_}.log"
