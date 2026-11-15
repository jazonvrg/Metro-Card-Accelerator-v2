`ifndef METRO_SEQ_PKG_SV
`define METRO_SEQ_PKG_SV
package seq_pkg;
    import uvm_pkg::*;
    import metro_apb_pkg::*;
    
    `include "uvm_macros.svh"
    `include "metro_sequences.sv"
    `include "metro_fallback_auto_clear_sequence.sv"
    
endpackage
`endif
