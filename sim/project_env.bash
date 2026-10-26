#!/bin/bash -f
# Project environment setup adapted from CODE UART (ICTC) template.
if command -v setup_dva >/dev/null 2>&1; then
    setup_dva
else
    echo "INFO: setup_dva was not found in PATH; keeping the current shell environment."
fi

# Same default UVM source location as the UART template; caller may override it.
export UVM_HOME="${UVM_HOME:-/ictc/other/tools/QuestaDVA/questasim/verilog_src/uvm-1.2}"
export METRO_CARD_IP_VERIF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export METRO_CARD_RTL_ROOT="${METRO_CARD_IP_VERIF_PATH}/rtl"
export METRO_CARD_VIP_ROOT="${METRO_CARD_IP_VERIF_PATH}/vip"
export METRO_CARD_TB_ROOT="${METRO_CARD_IP_VERIF_PATH}/tb"
export METRO_CARD_TEST_ROOT="${METRO_CARD_IP_VERIF_PATH}/testcases"

printf 'UVM_HOME=%s\n' "$UVM_HOME"
printf 'METRO_CARD_IP_VERIF_PATH=%s\n' "$METRO_CARD_IP_VERIF_PATH"
if [ ! -f "$UVM_HOME/src/uvm.sv" ]; then
    echo "WARNING: $UVM_HOME/src/uvm.sv not found. Check UVM_HOME."
fi
