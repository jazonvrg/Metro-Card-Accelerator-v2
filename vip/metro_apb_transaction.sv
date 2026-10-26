class metro_apb_transaction extends uvm_sequence_item;

    rand logic is_write;
    rand logic [7:0]  addr;
    rand logic [31:0] data;
    logic [31:0] rdata;

    `uvm_object_utils_begin(metro_apb_transaction)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(addr,     UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(data,     UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(rdata,    UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "metro_apb_transaction");
        super.new(name);
        rdata = '0;
    endfunction

endclass
