# Simulation setup (Questa/ModelSim)

The simulation files are grouped in `sim/`, following the compile/run organization of the supplied UART template.

From the project root:

```bash
make -C sim all UVM_HOME=/path/to/questasim/verilog_src/uvm-1.2 TEST=metro_fallback_miss_test
```

Or open Questa, change working directory to `sim/`, set `UVM_HOME`, and run:

```tcl
do run_questa.do
```

Choose a test with the `TESTNAME` environment variable for the `.do` file, or `TEST=...` for Makefile. Compiled `work/`, logs and wave files are generated under/near `sim/` and are not source files.


RTL-only smoke (no UVM dependency, still requires Questa/ModelSim):

```bash
make -C sim rtl-smoke
```

It checks the fallback-only miss-recovery case, clearing a fallback entry, and a normal Bloom insertion/query.
