`ifndef METRO_TEST_PKG_SV
`define METRO_TEST_PKG_SV
package test_pkg;
    import uvm_pkg::*;
    import metro_apb_pkg::*;
    import env_pkg::*;
    import seq_pkg::*;

    `include "uvm_macros.svh"
    `include "metro_base_test.sv"
    `include "metro_reset_test.sv"
    `include "metro_register_test.sv"
    `include "metro_hash_program_test.sv"
    `include "metro_fallback_miss_test.sv"
    `include "metro_fallback_table_test.sv"
    `include "metro_smoke_test.sv"
    `include "metro_metrics_test.sv"

endpackage
`endif
