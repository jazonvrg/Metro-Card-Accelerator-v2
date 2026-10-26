`ifndef METRO_APB_PKG_SV
`define METRO_APB_PKG_SV
package metro_apb_pkg;
    import uvm_pkg::*;

    `include "uvm_macros.svh"

    parameter logic [7:0] METRO_ID_REG          = 8'h00;
    parameter logic [7:0] METRO_CTRL_REG        = 8'h04;
    parameter logic [7:0] METRO_STAT_REG        = 8'h08;
    parameter logic [7:0] METRO_FALLBACK_BASE   = 8'h10;
    parameter int METRO_FALLBACK_DEPTH = 16;

    `include "metro_apb_transaction.sv"
    `include "metro_apb_sequencer.sv"
    `include "metro_apb_driver.sv"
    `include "metro_apb_monitor.sv"
    `include "metro_apb_agent.sv"

endpackage
`endif
