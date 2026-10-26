## ------------------------------------------------------------------
# Basic run:
#   make all TESTNAME=metro_fallback_miss_test SEED=1
#
# Enable RTL code coverage + SystemVerilog functional coverage:
#   make clean
#   make all COV=ON TESTNAME=metro_metrics_test SEED=1
#
# Run regression with coverage enabled (regress.cfg controls COV):
#   ./regress.pl
#   make cov_merge
## ------------------------------------------------------------------

TB_NAME   ?= testbench
TESTNAME  ?= metro_fallback_miss_test
VERBOSITY ?= UVM_LOW
RUNARG    ?=
SEED      ?= 1
COV       ?= OFF
UVM_HOME  ?= /ictc/other/tools/QuestaDVA/questasim/verilog_src/uvm-1.2

ifeq ($(strip $(SEED)),random)
  SEED := $(shell date +%s)
endif

# Instrument the RTL only for code coverage, to keep UVM/VIP overhead out of
# RTL statement/branch/toggle statistics. Functional covergroups are in the
# APB monitor and are saved with -cvg when COV=ON.
ifeq ($(COV),ON)
  RTL_COV_OPT  = -cover bcesft -coveropt 3
  SIM_COV_OPT  = -coverage -coveranalysis -cvgperinstance
  SIM_COV_SAVE = coverage save -codeAll -cvg -onexit $(TESTNAME)_$(SEED).ucdb;
else
  RTL_COV_OPT  =
  SIM_COV_OPT  =
  SIM_COV_SAVE =
endif

VLOG_COMMON = vlog \
       -timescale "1ns/1ps" \
       +define+UVM_NO_DPI \
       -mfcu \
       -suppress 2181 \
       +acc=rmb \
       +incdir+$(UVM_HOME)/src

VSIM = vsim -sv_seed $(SEED) $(SIM_COV_OPT) \
       -voptargs=+acc -assertdebug -c $(TB_NAME) \
       +UVM_TESTNAME=$(TESTNAME) \
       +UVM_VERBOSITY=$(VERBOSITY) $(RUNARG) \
       -do "$(SIM_COV_SAVE) log -r /*; run -all; quit -f" \
       -l $(TESTNAME)_$(SEED).log

.PHONY: all build run vlib wave cov_gui cov_merge cov_report clean help regress metrics
all: build run

build: vlib
	@test -f "$(UVM_HOME)/src/uvm.sv" || { \
	  echo "ERROR: UVM source not found: $(UVM_HOME)/src/uvm.sv"; \
	  echo "Source project_env.bash first, or override UVM_HOME=..."; exit 1; }
	$(VLOG_COMMON) $(UVM_HOME)/src/uvm.sv
	$(VLOG_COMMON) $(RTL_COV_OPT) -f rtl.f
	$(VLOG_COMMON) -f tb.f +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR

run:
	@mkdir -p log
	@$(VSIM); status=$$?; \
	  if [ -f "$(TESTNAME)_$(SEED).log" ]; then mv -f "$(TESTNAME)_$(SEED).log" log/; fi; \
	  if [ -f "$(TESTNAME)_$(SEED).ucdb" ]; then \
	    mv -f "$(TESTNAME)_$(SEED).ucdb" log/; \
	    if command -v vcover >/dev/null 2>&1; then \
	      vcover report -details -codeAll -cvg "log/$(TESTNAME)_$(SEED).ucdb" > "log/$(TESTNAME)_$(SEED)_coverage.txt" 2>&1 || \
	        echo "WARNING: UCDB saved, but vcover report failed; inspect the UCDB with cov_gui."; \
	    fi; \
	  fi; \
	  if [ -f vsim.wlf ]; then cp -f vsim.wlf "log/$(TESTNAME)_$(SEED).wlf"; fi; \
	  ln -sfn "$(TESTNAME)_$(SEED).log" log/run.log; \
	  exit $$status

vlib:
	@mkdir -p log
	vlib work
	vmap work work

wave:
	vsim -i -view log/$(TESTNAME)_$(SEED).wlf

cov_gui:
	@test -f "log/$(TESTNAME)_$(SEED).ucdb" || { echo "No UCDB: log/$(TESTNAME)_$(SEED).ucdb. Run with COV=ON."; exit 1; }
	vsim -i -viewcov log/$(TESTNAME)_$(SEED).ucdb

cov_report:
	@test -f "log/$(TESTNAME)_$(SEED).ucdb" || { echo "No UCDB: log/$(TESTNAME)_$(SEED).ucdb. Run with COV=ON."; exit 1; }
	vcover report -details -codeAll -cvg log/$(TESTNAME)_$(SEED).ucdb > log/$(TESTNAME)_$(SEED)_coverage.txt
	@echo "Coverage report: log/$(TESTNAME)_$(SEED)_coverage.txt"

cov_merge:
	@set -e; \
	  files=$$(find log -maxdepth 1 -type f -name '*.ucdb' ! -name 'IP_MERGE_*.ucdb' -print); \
	  test -n "$$files" || { echo "No UCDB files found under log/. Run tests with COV=ON first."; exit 1; }; \
	  vcover merge log/IP_MERGE_$(SEED).ucdb $$files; \
	  vcover report -details -codeAll -cvg log/IP_MERGE_$(SEED).ucdb > log/IP_MERGE_$(SEED)_coverage.txt; \
	  echo "Merged coverage report: log/IP_MERGE_$(SEED)_coverage.txt"

clean:
	rm -rf work log *.ini *.log *.trace *.wlf *.ucdb transcript vsim.dbg tmp_report

help:
	@echo "make build   : compile RTL + UVM testbench"
	@echo "make run     : run current TESTNAME"
	@echo "make all     : compile and run"
	@echo "make all COV=ON TESTNAME=... : collect RTL code + functional coverage"
	@echo "make cov_report TESTNAME=... : generate text coverage report from UCDB"
	@echo "make cov_gui TESTNAME=...    : open UCDB in Questa Coverage GUI"
	@echo "make cov_merge              : merge all log/*.ucdb and report combined coverage"
	@echo "make metrics                : compute metrics from last metro_metrics_test run"
	@echo "make clean                  : remove generated simulation data"

regress:
	./regress.pl

metrics:
	python3 ../metrics/ai_metrics.py log/metro_metrics_results.csv
