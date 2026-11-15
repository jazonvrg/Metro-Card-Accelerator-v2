#!/bin/bash -f
# Project environment setup for Cadence Xcelium (xrun / imc / simvision)

if command -v xrun >/dev/null 2>&1; then
    echo "INFO: Cadence Xcelium (xrun) detected in PATH: $(command -v xrun)"
elif command -v setup_xcelium >/dev/null 2>&1; then
    setup_xcelium
elif command -v setup_dva >/dev/null 2>&1; then
    setup_dva
else
    echo "INFO: Using current shell environment (ensure xrun, imc, and simvision are in PATH)."
fi

# Default to Xcelium's built-in UVM 1.2 library (CDNS-1.2); caller may override UVM_HOME.
export UVM_HOME="${UVM_HOME:-CDNS-1.2}"
export METRO_CARD_IP_VERIF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export METRO_CARD_RTL_ROOT="${METRO_CARD_IP_VERIF_PATH}/rtl"
export METRO_CARD_VIP_ROOT="${METRO_CARD_IP_VERIF_PATH}/vip"
export METRO_CARD_TB_ROOT="${METRO_CARD_IP_VERIF_PATH}/tb"
export METRO_CARD_SEQ_ROOT="${METRO_CARD_IP_VERIF_PATH}/sequences"
export METRO_CARD_TEST_ROOT="${METRO_CARD_IP_VERIF_PATH}/testcases"

printf 'UVM_HOME=%s\n' "$UVM_HOME"
printf 'METRO_CARD_IP_VERIF_PATH=%s\n' "$METRO_CARD_IP_VERIF_PATH"
