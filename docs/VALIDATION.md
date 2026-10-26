# Validation status

- Directory/layout checks: performed. `tb/` contains only environment, testbench, scoreboard and environment package. APB interface and transaction live under `vip/`; scenario classes live under `testcases/`.
- Added exact-match fallback table and APB slots at `0x10 + 4*n` to catch known blacklist IDs absent from the Bloom bit array. The fallback table is not able to infer IDs missing from both sources.
- Added directed UVM tests and a VPLAN.
- Added `metrics/ai_metrics.py`, tested against its included sample CSV.
- RTL/UVM simulation could not be run in this build environment because Questa/ModelSim and Icarus Verilog are not installed. Run `make -C sim all UVM_HOME=/path/to/uvm-1.2 TEST=metro_fallback_miss_test` and then repeat with `TEST=metro_fallback_table_test` in a simulator-equipped environment.
