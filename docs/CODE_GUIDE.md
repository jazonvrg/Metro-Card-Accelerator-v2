# Code Guide and How to Capture Questa Results

## 1. Run a single UVM testcase

From the extracted project root:

```bash
cd sim
source ./project_env.bash
make clean
make all TESTNAME=metro_fallback_miss_test SEED=1
```

The environment script calls `setup_dva` when available and sets `UVM_HOME` to the ICTC Questa UVM 1.2 source directory by default. If your installation uses another location, override it, for example:

```bash
export UVM_HOME=/actual/path/to/uvm-1.2
make all TESTNAME=metro_fallback_miss_test SEED=1
```

`make all` means compile then simulate. `make build` only compiles, and `make run TESTNAME=... SEED=...` runs after a successful build. Available tests are `metro_reset_test`, `metro_register_test`, `metro_hash_program_test`, `metro_fallback_miss_test`, `metro_fallback_table_test`, and `metro_smoke_test`.

To run all tests in `regress.cfg`:

```bash
./regress.pl
cat regress.rpt
```

To rebuild the report from existing logs without rerunning simulations:

```bash
./regress.pl -r
```

The Makefile puts simulator logs under `sim/log/`; a run log is named `log/<TESTNAME>_<SEED>.log`, and the waveform is copied to `log/<TESTNAME>_<SEED>.wlf` if Questa generated `vsim.wlf`. `regress.rpt` is a summary, not proof of passing unless its logs contain the configured `TEST PASSED` markers.

## 2. What to screenshot

For a single test, capture the terminal showing:

1. `vlog` finished without compile errors;
2. `vsim` ran the selected test;
3. `#### TEST PASSED ####` and UVM summary with zero errors/fatals;
4. the scoreboard's `operations`, `status_checks`, and `fallback_hits` summary.

You can inspect the saved log after the run:

```bash
tail -n 80 log/metro_fallback_miss_test_1.log
```

For regression evidence, capture the terminal after `./regress.pl` and open `regress.rpt`. Do not present a compile-only log as a passing simulation result. If `make run` exits nonzero or the log says `TEST FAILED`, preserve the error lines and investigate instead of claiming PASS.

## 3. Folder/file explanation

### `rtl/` — synthesizable/behavioral DUT

- `apb_slave.sv`: derives APB write/read enables and makes `PREADY` always high (zero wait states).
- `hash_engine.sv`: deterministically maps each 32-bit card ID to four Bloom-filter bit indexes. The default array size is 9,600,000 bits; the testbench overrides it to 4096 to make simulation practical.
- `sram.sv`: behavioral Bloom-filter bit array. Program mode sets the four selected bits; query mode ANDs those four bits and ORs the result with the exact fallback hit. `done` is asserted when an operation starts. Its `initial` loop is a simulation initialization model, not a realistic ASIC SRAM reset implementation.
- `fallback_lookup.sv`: 16-entry exact-match table, addressed at `0x10 + 4*slot`. Writing zero clears a slot. This catches known blacklist IDs not inserted in Bloom.
- `register.sv`: implements `ID_REG` (`0x00`), `CTRL_REG` (`0x04`), `STAT_REG` (`0x08`) and readback muxing. CTRL bit 0 starts an operation; bit 1 selects Bloom programming vs query.
- `metro_card_top.sv`: top-level wiring among APB, registers, hash engine, Bloom memory and fallback table.

### `vip/` — reusable APB UVM VIP

- `metro_apb_if.sv`: SystemVerilog interface carrying APB signals and clock/reset.
- `metro_apb_transaction.sv`: one APB read/write transaction object (address, write flag, write data, read data).
- `metro_apb_sequencer.sv`: UVM sequencer that arbitrates transaction items from sequences to the driver.
- `metro_apb_driver.sv`: drives APB setup/access phases and returns read data/response to the sequence.
- `metro_apb_monitor.sv`: passively samples completed APB transfers and publishes transaction objects through an analysis port.
- `metro_apb_agent.sv`: bundles sequencer, driver and monitor; the driver/sequencer are active, monitor observes the bus.
- `metro_apb_pkg.sv`: declares APB register/address constants and includes the VIP class files in dependency order.

### `sequences/` — reusable stimulus

- `metro_sequences.sv`: base APB read/write helpers plus reusable sequences for register access, reset status, Bloom insertion/query, fallback miss and fallback table corner cases.
- `seq_pkg.sv`: imports UVM/VIP packages and includes the sequence definitions.

### `tb/` — UVM environment and top

- `env_pkg.sv`: imports dependencies and includes environment and scoreboard definitions.
- `metro_environment.sv`: creates APB agent and scoreboard, passes virtual interface/configuration, and connects monitor analysis output to scoreboard.
- `metro_scoreboard.sv`: maintains a reference Bloom bit array and fallback table model; predicts expected status bits and reports mismatches as UVM errors.
- `testbench.sv`: simulation top. Generates clock/reset, instantiates interface and DUT, sets UVM config DB values and calls `run_test()`. It uses `BIT_COUNT=4096` for simulation speed.

### `testcases/` — one class per scenario

- `metro_base_test.sv`: common setup, environment creation, reset wait, UVM topology print and final PASS/FAIL marker.
- `metro_reset_test.sv`: checks reset status.
- `metro_register_test.sv`: checks ID and control register readback.
- `metro_hash_program_test.sv`: inserts known IDs into Bloom then queries them.
- `metro_fallback_miss_test.sv`: inserts an ID only into fallback, checks it is matched, reads it back, clears it and checks it no longer matches.
- `metro_fallback_table_test.sv`: checks fallback slots 0, 1 and 15, readback, overwrite, clear and lookup.
- `metro_smoke_test.sv`: short sanity flow combining Bloom and fallback scenarios inside UVM (not a separate RTL-only testbench).
- `test_pkg.sv`: imports packages and includes all test classes so `+UVM_TESTNAME=...` can select them.

### `sim/` — Questa build/run/regression

- `Makefile`: compile/run targets, seed and testcase selection, optional coverage flags, waveform viewing and cleanup.
- `project_env.bash`: sources ICTC `setup_dva` if available and sets project-root variables plus `UVM_HOME`.
- `rtl.f`: ordered RTL filelist.
- `tb.f`: include paths and ordered UVM/VIP/environment/sequence/testbench filelist.
- `regress.cfg`: testcase list and pass/fail markers used by regression.
- `regress.pl`: Perl script that reads `regress.cfg`, compiles once, runs configured tests with random seeds, and summarizes logs in `regress.rpt`.
- `regress.rpt`: initial placeholder report; it becomes meaningful after regression is run.

### `metrics/` and `docs/`

- `metrics/ai_metrics.py`: reads labelled binary predictions and calculates TP/FP/TN/FN, Accuracy, Precision, Recall, F1, Specificity, FPR and FNR. It evaluates predictions; it does not train an AI model.
- `metrics/example_labels.csv`: tiny illustrative input only, not real benchmark data.
- `metrics/README.md`: CSV format and usage notes.
- `docs/TESTPLAN.md`: verification scenarios, expected outcomes and coverage goals.
- `docs/VALIDATION.md`: records validation scope and limitations.
- `README.md`: project overview, register map and quick-start commands.

## 4. Result interpretation

For the fallback-miss test, the key expected evidence is a query where `bloom=0`, `fallback=1`, and combined `match=1`, followed by a cleared-entry query with `fallback=0` and `match=0`. This demonstrates the fallback path in this simulation; it does not prove silicon timing, capacity, or full-scale 9.6-million-bit implementation. The 4096-bit testbench configuration is a simulation shortcut.

The metrics script expects a labelled CSV with `true_label,predicted_label` where `1=blacklisted` and `0=clean`. Its example CSV is illustrative only. Do not describe these numbers as AI model results unless predictions were actually generated by a trained AI model.


## Collecting actual classification metrics

`metro_metrics_test.sv` starts `metro_metrics_sequence`. It loads 240 blacklist IDs into Bloom, loads 16 different blacklist IDs into fallback only, then queries those 256 blacklist IDs plus 1024 unregistered clean IDs. The sequence records the truth label defined by that test dataset and the actual prediction read from `STAT_REG[1]` into `sim/log/metro_metrics_results.csv`.

Run from `sim/`:

```bash
source ./project_env.bash
make clean
make all TESTNAME=metro_metrics_test SEED=1
make metrics
```

The 1280-row CSV is generated by Questa, not pre-filled by the Python script. The dataset is synthetic and uses `BIT_COUNT=4096` from the testbench, so it evaluates this controlled simulation only. It is not a representative real-card dataset and should not be described as AI-model performance.
