# Questa command script. The UART template initializes UVM_HOME in its setup
# script; this file also accepts an existing environment variable.
if {![info exists ::env(UVM_HOME)]} {
    set ::env(UVM_HOME) "/ictc/other/tools/QuestaDVA/questasim/verilog_src/uvm-1.2"
}
set testname "metro_fallback_miss_test"
if {[info exists ::env(TESTNAME)]} { set testname $::env(TESTNAME) }
set seed "1"
if {[info exists ::env(SEED)]} { set seed $::env(SEED) }
set verbosity "UVM_LOW"
if {[info exists ::env(VERBOSITY)]} { set verbosity $::env(VERBOSITY) }
file mkdir logs
vlib work
vmap work work
vlog -timescale "1ns/1ps" +define+UVM_NO_DPI -mfcu -suppress 2181 +acc=rmb \
    +incdir+$::env(UVM_HOME)/src $::env(UVM_HOME)/src/uvm.sv
vlog -sv -timescale "1ns/1ps" -mfcu -f compile.f +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR
vsim -sv_seed $seed -voptargs=+acc -assertdebug -c testbench \
    +UVM_TESTNAME=$testname +UVM_VERBOSITY=$verbosity \
    -do "log -r /*; run -all; quit -f" -l logs/${testname}_${seed}.log
