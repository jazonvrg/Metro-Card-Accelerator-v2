## -------------------------------------------------------------
# Metro Card Accelerator - ICTC UART-template-style simulation Makefile
# Usage: make TESTNAME=metro_fallback_miss_test
#        make all TESTNAME=metro_fallback_miss_test SEED=1
## -------------------------------------------------------------

TB_NAME   ?= testbench
TESTNAME  ?= metro_fallback_miss_test
VERBOSITY ?= UVM_LOW
RUNARG    ?=
SEED      ?= 1
COV       ?= OFF
UVM_HOME  ?= /ictc/other/tools/QuestaDVA/questasim/verilog_src/uvm-1.2

ifeq ($(COV),ON)
  CMP_COV_OPT  = -coveropt 3 +cover=bcestf
  SIM1_COV_OPT = -coverage -coveranalysis
  SIM2_COV_OPT = coverage save -codeAll -cvg -onexit $(TESTNAME)_$(SEED).ucdb;
endif

ifeq ($(strip $(SEED)),random)
  SEED := $(shell date +%s)
endif

VLOG = vlog $(CMP_COV_OPT) \
       -timescale "1ns/1ps" \
       +define+UVM_NO_DPI \
       -mfcu \
       -suppress 2181 \
       +acc=rmb \
       +incdir+$(UVM_HOME)/src \
       $(UVM_HOME)/src/uvm.sv

VSIM = vsim -sv_seed $(SEED) $(SIM1_COV_OPT) \
       -voptargs=+acc -assertdebug -c $(TB_NAME) \
       +UVM_TESTNAME=$(TESTNAME) \
       +UVM_VERBOSITY=$(VERBOSITY) $(RUNARG) \
       -do "$(SIM2_COV_OPT) log -r /*; run -all; quit -f" \
       -l $(TESTNAME)_$(SEED).log

.PHONY: all build run vlib wave cov_gui cov_merge clean help regress
all: build run

build: vlib
	@test -f "$(UVM_HOME)/src/uvm.sv" || { \
	  echo "ERROR: UVM source not found: $(UVM_HOME)/src/uvm.sv"; \
	  echo "Source project_env.bash first, or override UVM_HOME=..."; exit 1; }
	$(VLOG) -f rtl.f -f tb.f +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR

run:
	@mkdir -p log
	@$(VSIM); status=$$?; \
	  if [ -f "$(TESTNAME)_$(SEED).log" ]; then mv -f "$(TESTNAME)_$(SEED).log" log/; fi; \
	  if [ -f "$(TESTNAME)_$(SEED).ucdb" ]; then mv -f "$(TESTNAME)_$(SEED).ucdb" log/; fi; \
	  if [ -f vsim.wlf ]; then cp -f vsim.wlf "log/$(TESTNAME)_$(SEED).wlf"; fi; \
	  ln -sfn "$(TESTNAME)_$(SEED).log" log/run.log; \
	  exit $$status

vlib:
	@mkdir -p log
	vlib work
	vmap work work

wave:
	vsim -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*;" &

cov_gui:
	vsim -i -viewcov log/$(TESTNAME)_$(SEED).ucdb &

cov_merge:
	vcover merge log/IP_MERGE_$(SEED).ucdb log/*.ucdb

clean:
	rm -rf work log *.ini *.log *.trace *.wlf *.ucdb transcript vsim.dbg tmp_report

help:
	@echo "****************************************"
	@echo "make build   : compile RTL + UVM testbench"
	@echo "make run     : run current TESTNAME"
	@echo "make all     : compile and run"
	@echo "make wave    : open waveform"
	@echo "make clean   : remove generated simulation data"
	@echo "make regress : run regress.pl using regress.cfg"
	@echo "****************************************"

regress:
	./regress.pl
