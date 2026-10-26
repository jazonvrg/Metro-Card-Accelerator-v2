# Validation status

- Directory/layout checks: performed. `tb/` contains only environment, testbench, scoreboard and environment package. APB interface and transaction live under `vip/`; scenario classes live under `testcases/`.
- `sim/` now follows the ICTC UART-template file layout: `Makefile`, `compile.f`, `project_env.bash`, `regress.cfg`, `regress.pl`, `regress.rpt`, `sim_results.tar.gz`, `rtl.f`, and `tb.f`.
- Added exact-match fallback table and APB slots at `0x10 + 4*n` to catch known blacklist IDs absent from the Bloom bit array. The fallback table cannot infer IDs missing from both sources.
- Added directed UVM tests, a VPLAN and a binary-classification metrics script.
- Perl regression-runner syntax, environment-shell syntax, archive integrity, filelists and Makefile dry-run were checked in the build environment. Questa/ModelSim simulation itself was not run here. The initial `regress.rpt` and `sim_results.tar.gz` do not claim any test has passed; run `cd sim && source ./project_env.bash && ./regress.pl` on the ICTC machine to produce genuine results.
