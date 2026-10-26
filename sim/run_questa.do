# Run from sim/: do run_questa.do
if {![info exists ::env(UVM_HOME)]} {
    puts "ERROR: Set UVM_HOME to an Accellera UVM source directory."
    quit -code 1
}
set testname "metro_fallback_miss_test"
if {[info exists ::env(TESTNAME)]} { set testname $::env(TESTNAME) }
file mkdir logs
vlib work
vlog -sv +incdir+$::env(UVM_HOME)/src $::env(UVM_HOME)/src/uvm_pkg.sv
vlog -sv -f compile.f
vsim -c testbench +UVM_TESTNAME=$testname -do "run -all; quit -f" -l logs/${testname}.log
