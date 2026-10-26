class metro_apb_sequencer extends uvm_sequencer #(metro_apb_transaction);
    `uvm_component_utils(metro_apb_sequencer)
    function new(string name = "metro_apb_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
