# Metro Card Accelerator simulation Makefile
# Follows the supplied UART template: setup_dva environment, UVM source via
# $(UVM_HOME)/src/uvm.sv, separate rtl.f/tb.f, and build/run/wave/clean targets.

# Same default UVM installation path used by CODE UART template.
UVM_HOME ?= /ictc/other/tools/QuestaDVA/questasim/verilog_src/uvm-1.2
TESTNAME ?= metro_fallback_miss_test
SEED     ?= 1
VERBOSITY ?= UVM_LOW
TB_NAME  ?= testbench
COV      ?= OFF

ifeq ($(COV),ON)
  CMP_COV_OPT  = -coveropt 3 +cover=bcestf
  SIM_COV_OPT  = -coverage -coveranalysis
  SAVE_COV_CMD = coverage save -codeAll -cvg -onexit logs/$(TESTNAME)_$(SEED).ucdb;
else
  CMP_COV_OPT  =
  SIM_COV_OPT  =
  SAVE_COV_CMD =
endif

VLOG = vlog $(CMP_COV_OPT) \
       -timescale "1ns/1ps" \
       +define+UVM_NO_DPI \
       -mfcu \
       -suppress 2181 \
       +acc=rmb \
       +incdir+$(UVM_HOME)/src \
       $(UVM_HOME)/src/uvm.sv

VSIM = vsim -sv_seed $(SEED) $(SIM_COV_OPT) -voptargs=+acc -assertdebug -c $(TB_NAME) \
       +UVM_TESTNAME=$(TESTNAME) +UVM_VERBOSITY=$(VERBOSITY) \
       -do "$(SAVE_COV_CMD) log -r /*; run -all; quit -f" \
       -l logs/$(TESTNAME)_$(SEED).log

.PHONY: all build run vlib wave cov_gui cov_merge rtl-smoke clean help
all: build run

build: vlib
	@test -f "$(UVM_HOME)/src/uvm.sv" || { \
	  echo "ERROR: UVM source not found: $(UVM_HOME)/src/uvm.sv"; \
	  echo "Use the same UVM_HOME path as the UART project or override UVM_HOME=..."; exit 1; }
	$(VLOG) -f compile.f +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR

run:
	@mkdir -p logs
	$(VSIM)
	@ln -sf $(TESTNAME)_$(SEED).log logs/run.log 2>/dev/null || true

vlib:
	@mkdir -p logs
	vlib work
	vmap work work

wave:
	vsim -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*;" &

cov_gui:
	vsim -i -viewcov logs/$(TESTNAME)_$(SEED).ucdb &

cov_merge:
	vcover merge logs/IP_MERGE_$(SEED).ucdb logs/*.ucdb

# RTL-only smoke test. Does not compile UVM; uses the separate smoke top.
rtl-smoke: vlib
	vlog -sv -timescale "1ns/1ps" -f rtl_smoke.f
	vsim -c metro_rtl_smoke_tb -do "run -all; quit -f" -l logs/rtl_smoke.log

clean:
	rm -rf work transcript logs *.ini *.log *.trace *.wlf *.ucdb vsim.dbg tmp_report

help:
	@echo "make all      : compile and run UVM test (default TESTNAME=metro_fallback_miss_test)"
	@echo "make build    : compile RTL, VIP, environment, sequences and testcases"
	@echo "make run TESTNAME=metro_fallback_table_test SEED=2"
	@echo "make wave     : open vsim.wlf"
	@echo "make rtl-smoke: run RTL-only smoke test (no UVM)"
	@echo "make clean    : remove compiled data and logs"
	@echo "Available tests: metro_reset_test metro_register_test metro_hash_program_test metro_fallback_miss_test metro_fallback_table_test metro_smoke_test"
