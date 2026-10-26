# Invoke from the project root with: make -C sim all UVM_HOME=/path/to/uvm-1.2
UVM_HOME ?= $(QUESTA_HOME)/verilog_src/uvm-1.2
TEST     ?= metro_fallback_miss_test
SEED     ?= 1
VERBOSITY ?= UVM_LOW

.PHONY: all build run rtl-smoke clean help
all: build run

build:
	@test -n "$(UVM_HOME)" || (echo "Set UVM_HOME to your UVM source directory"; exit 1)
	@mkdir -p logs
	vlib work
	vlog -sv +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv
	vlog -sv -f compile.f

run:
	@mkdir -p logs
	vsim -c -sv_seed $(SEED) testbench +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -do "run -all; quit -f" -l logs/$(TEST)_$(SEED).log

rtl-smoke:
	@mkdir -p logs
	vlib work
	vlog -sv -f rtl_smoke.f
	vsim -c metro_rtl_smoke_tb -do "run -all; quit -f" -l logs/rtl_smoke.log

clean:
	rm -rf work transcript *.log *.wlf *.ucdb logs

help:
	@echo "make -C sim all UVM_HOME=/path/to/uvm-1.2 TEST=metro_fallback_miss_test"
	@echo "Available tests: metro_reset_test, metro_register_test, metro_hash_program_test, metro_fallback_miss_test, metro_fallback_table_test, metro_smoke_test"
	@echo "RTL-only smoke: make -C sim rtl-smoke"
