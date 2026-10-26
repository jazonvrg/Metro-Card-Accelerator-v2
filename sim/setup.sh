#!/bin/bash
# Optional environment setup matching the supplied CODE UART template.
# Run from the sim directory: source ./setup.sh
if command -v setup_dva >/dev/null 2>&1; then
    setup_dva
fi
export UVM_HOME="${UVM_HOME:-/ictc/other/tools/QuestaDVA/questasim/verilog_src/uvm-1.2}"
export METRO_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export METRO_SIM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "UVM_HOME=$UVM_HOME"
echo "METRO_PROJECT_ROOT=$METRO_PROJECT_ROOT"
if [ ! -f "$UVM_HOME/src/uvm.sv" ]; then
    echo "WARNING: $UVM_HOME/src/uvm.sv not found. Check the path used by your UART project."
fi
