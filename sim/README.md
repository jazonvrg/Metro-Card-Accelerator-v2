# Metro Card Accelerator - sim folder

This folder follows the simulation organization and commands used in the supplied `CODE UART` template:

- `Makefile`: `build`, `run`, `all`, `wave`, `cov_gui`, `cov_merge`, `clean`, `help` targets.
- `setup.sh`: optional `setup_dva` initialization and the same default `UVM_HOME` path as the UART template.
- `rtl.f`: RTL file list.
- `tb.f`: VIP, environment, sequence, testcase package and testbench list.
- `compile.f`: includes `rtl.f` and `tb.f`, as in the UART template.
- `run_questa.do`: equivalent standalone Questa compile/run flow.
- `rtl_smoke.f`: RTL-only compile list, independent of UVM.

## Run like the UART template

From the `sim/` directory:

```bash
source ./setup.sh
make clean
make all TESTNAME=metro_fallback_miss_test SEED=1
```

Run another testcase:

```bash
make all TESTNAME=metro_fallback_table_test SEED=2
```

If the UART project already exports `UVM_HOME`, the existing value is preserved. Otherwise this folder defaults to the UVM source path used in the provided UART template:

`/ictc/other/tools/QuestaDVA/questasim/verilog_src/uvm-1.2`

If your lab image uses a different path, set it explicitly:

```bash
make all UVM_HOME=/actual/path/to/uvm-1.2 TESTNAME=metro_fallback_miss_test
```

Alternatively, from the Questa transcript, after setting environment variables, run:

```tcl
do run_questa.do
```

`run_questa.do` reads `TESTNAME`, `SEED`, `VERBOSITY`, and `UVM_HOME` from the shell environment when available.

## RTL-only smoke test

```bash
make rtl-smoke
```

This test does not compile the UVM library.
