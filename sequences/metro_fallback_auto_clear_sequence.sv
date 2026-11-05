class metro_fallback_auto_clear_sequence extends metro_base_sequence;
    `uvm_object_utils(metro_fallback_auto_clear_sequence)
  
    function new(string name = "metro_fallback_auto_clear_sequence");
      super.new(name);
    endfunction
  
    virtual task body();
        logic [31:0] committed_id;
        logic [31:0] pending_id;
        logic [31:0] readback;
        logic [7:0] committed_addr0;
        logic [7:0] pending_addr1;
        logic [7:0] committed_addr2;
        committed_id = 32'hC1EA_0001;
        pending_id = 32'h51DE_0002;
        committed_addr0 = METRO_FALLBACK_BASE;
        pending_addr1 = METRO_FALLBACK_BASE + 8'h04;
        committed_addr2 = METRO_FALLBACK_BASE + 8'h08;
        `uvm_info(get_type_name(), "AUTO-CLEAR: insert committed ID twice and keep a different pending ID", UVM_LOW)
        apb_write(committed_addr0, committed_id);
        apb_write(pending_addr1, pending_id);
        apb_write(committed_addr2, committed_id);
        apb_read(committed_addr0, readback);
        if (readback !== committed_id) `uvm_error(get_type_name(), $sformatf("AUTO-CLEAR setup failed at slot 0: expected=0x%08h got=0x%08h", committed_id, readback))
        apb_read(pending_addr1, readback);
        if (readback !== pending_id) `uvm_error(get_type_name(), $sformatf("AUTO-CLEAR setup failed at slot 1: expected=0x%08h got=0x%08h", pending_id, readback))
        apb_read(committed_addr2, readback);
        if (readback !== committed_id) `uvm_error(get_type_name(), $sformatf("AUTO-CLEAR setup failed at slot 2: expected=0x%08h got=0x%08h", committed_id, readback))
        query_card(committed_id, 1'b1, 1'b1);
        query_card(pending_id, 1'b1, 1'b1);
        `uvm_info(get_type_name(), $sformatf("AUTO-CLEAR: program ID=0x%08h into Bloom", committed_id), UVM_LOW)
        program_bloom(committed_id);
        apb_read(committed_addr0, readback);
        if (readback !== 32'h0000_0000) `uvm_error(get_type_name(), $sformatf("AUTO-CLEAR failed at slot 0: expected=0 got=0x%08h", readback))
        apb_read(committed_addr2, readback);
        if (readback !== 32'h0000_0000) `uvm_error(get_type_name(), $sformatf("AUTO-CLEAR failed at slot 2: expected=0 got=0x%08h", readback))
        apb_read(pending_addr1, readback);
        if (readback !== pending_id) `uvm_error(get_type_name(), $sformatf("AUTO-CLEAR removed an unrelated entry: expected=0x%08h got=0x%08h", pending_id, readback))
        query_card(committed_id, 1'b1, 1'b0);
        query_card(pending_id, 1'b1, 1'b1);
        `uvm_info(get_type_name(), "AUTO-CLEAR TEST COMPLETED", UVM_LOW)
    endtask
  
endclass
