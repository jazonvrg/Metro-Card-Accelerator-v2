class metro_base_sequence extends uvm_sequence #(metro_apb_transaction);
    `uvm_object_utils(metro_base_sequence)
    function new(string name = "metro_base_sequence"); super.new(name); endfunction

    task apb_write(input logic [7:0] addr, input logic [31:0] data);
        metro_apb_transaction tr, rsp;
        tr = metro_apb_transaction::type_id::create("write_item");
        start_item(tr);
        tr.is_write = 1'b1; tr.addr = addr; tr.data = data; tr.rdata = '0;
        finish_item(tr);
        get_response(rsp);
    endtask

    task apb_read(input logic [7:0] addr, output logic [31:0] data);
        metro_apb_transaction tr, rsp;
        tr = metro_apb_transaction::type_id::create("read_item");
        start_item(tr);
        tr.is_write = 1'b0; tr.addr = addr; tr.data = '0; tr.rdata = '0;
        finish_item(tr);
        get_response(rsp);
        data = rsp.rdata;
    endtask

    task set_card_id(input logic [31:0] id);
        apb_write(METRO_ID_REG, id);
    endtask

    task program_bloom(input logic [31:0] id);
        logic [31:0] status;
        set_card_id(id);
        apb_write(METRO_CTRL_REG, 32'h0000_0003); // START=1, MODE=program
        apb_read(METRO_STAT_REG, status);
        if (status[0] !== 1'b1 || status[1] !== 1'b0 || status[2] !== 1'b0)
            `uvm_error(get_type_name(), $sformatf("Program status mismatch ID=0x%08h status=0x%08h", id, status))
    endtask

    task query_card(input logic [31:0] id, input bit expected_match, input bit expected_fallback = 1'b0);
        logic [31:0] status;
        set_card_id(id);
        apb_write(METRO_CTRL_REG, 32'h0000_0001); // START=1, MODE=query
        apb_read(METRO_STAT_REG, status);
        if (status[0] !== 1'b1 || status[1] !== expected_match || status[2] !== expected_fallback)
            `uvm_error(get_type_name(),
                       $sformatf("Query mismatch ID=0x%08h exp_match=%0b exp_fallback=%0b status=0x%08h",
                                 id, expected_match, expected_fallback, status))
        else
            `uvm_info(get_type_name(), $sformatf("QUERY PASS ID=0x%08h status=0x%08h", id, status), UVM_LOW)
    endtask
endclass

class metro_hash_sequence extends metro_base_sequence;
    `uvm_object_utils(metro_hash_sequence)
    function new(string name = "metro_hash_sequence"); super.new(name); endfunction
    virtual task body();
        logic [31:0] ids [0:3];
        ids[0] = 32'h1000_0001;
        ids[1] = 32'h1000_0002;
        ids[2] = 32'h2000_0001;
        ids[3] = 32'hDEAD_BEEF;
        foreach (ids[i]) program_bloom(ids[i]);
        foreach (ids[i]) query_card(ids[i], 1'b1, 1'b0);
    endtask
endclass

class metro_fallback_sequence extends metro_base_sequence;
    `uvm_object_utils(metro_fallback_sequence)
    function new(string name = "metro_fallback_sequence"); super.new(name); endfunction
    virtual task body();
        logic [31:0] fallback_only_id;
        fallback_only_id = 32'hD00D_CAFE;
        // Deliberately do NOT program fallback_only_id into the Bloom filter.
        // It is inserted only into the exact-match side table, exercising the miss recovery path.
        apb_write(METRO_FALLBACK_BASE, fallback_only_id);
        query_card(fallback_only_id, 1'b1, 1'b1);
        // Readback confirms the list entry is accessible through APB.
        begin
            logic [31:0] readback;
            apb_read(METRO_FALLBACK_BASE, readback);
            if (readback !== fallback_only_id)
                `uvm_error(get_type_name(), $sformatf("Fallback slot readback mismatch expected=0x%08h got=0x%08h", fallback_only_id, readback))
        end
        // Writing zero invalidates the entry. It was never inserted into Bloom,
        // so after clearing the exact table it must no longer be matched.
        apb_write(METRO_FALLBACK_BASE, 32'h0000_0000);
        query_card(fallback_only_id, 1'b0, 1'b0);
        query_card(32'hCAFE_BABE, 1'b0, 1'b0);
    endtask
endclass

class metro_register_sequence extends metro_base_sequence;
    `uvm_object_utils(metro_register_sequence)
    function new(string name = "metro_register_sequence"); super.new(name); endfunction
    virtual task body();
        logic [31:0] rdata;
        apb_write(METRO_ID_REG, 32'h1357_2468);
        apb_read(METRO_ID_REG, rdata);
        if (rdata !== 32'h1357_2468)
            `uvm_error(get_type_name(), $sformatf("ID register readback failed: 0x%08h", rdata))
        apb_write(METRO_CTRL_REG, 32'h0000_0002);
        apb_read(METRO_CTRL_REG, rdata);
        if (rdata[1:0] !== 2'b10)
            `uvm_error(get_type_name(), $sformatf("CTRL register readback failed: 0x%08h", rdata))
    endtask
endclass

class metro_reset_sequence extends metro_base_sequence;
    `uvm_object_utils(metro_reset_sequence)
    function new(string name = "metro_reset_sequence"); super.new(name); endfunction
    virtual task body();
        logic [31:0] rdata;
        apb_read(METRO_STAT_REG, rdata);
        if (rdata !== 32'h0)
            `uvm_error(get_type_name(), $sformatf("Status register should be zero after reset: 0x%08h", rdata))
    endtask
endclass


class metro_fallback_table_sequence extends metro_base_sequence;
    `uvm_object_utils(metro_fallback_table_sequence)
    function new(string name = "metro_fallback_table_sequence"); super.new(name); endfunction
    virtual task body();
        logic [31:0] rdata;
        logic [31:0] ids [0:2];
        logic [7:0] addrs [0:2];
        ids[0] = 32'hABCD_0001; addrs[0] = METRO_FALLBACK_BASE;
        ids[1] = 32'hABCD_0002; addrs[1] = METRO_FALLBACK_BASE + 8'h04;
        ids[2] = 32'hABCD_0010; addrs[2] = METRO_FALLBACK_BASE + 8'h3C; // slot 15
        foreach (ids[i]) apb_write(addrs[i], ids[i]);
        foreach (ids[i]) begin
            apb_read(addrs[i], rdata);
            if (rdata !== ids[i])
                `uvm_error(get_type_name(), $sformatf("Fallback slot readback mismatch addr=0x%02h exp=0x%08h got=0x%08h", addrs[i], ids[i], rdata))
        end
        // Overwrite slot 1 and confirm only the replacement ID is found there.
        apb_write(addrs[1], 32'hABCD_00F2);
        apb_read(addrs[1], rdata);
        if (rdata !== 32'hABCD_00F2)
            `uvm_error(get_type_name(), $sformatf("Fallback overwrite failed got=0x%08h", rdata))
        // Clear slot 0; its ID was never inserted into Bloom, so it must now miss.
        apb_write(addrs[0], 32'h0);
        query_card(ids[0], 1'b0, 1'b0);
        query_card(32'hABCD_00F2, 1'b1, 1'b1);
        query_card(ids[2], 1'b1, 1'b1);
    endtask
endclass
