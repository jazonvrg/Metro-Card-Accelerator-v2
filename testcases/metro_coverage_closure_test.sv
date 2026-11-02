class metro_coverage_closure_sequence extends metro_base_sequence;
    `uvm_object_utils(metro_coverage_closure_sequence)

    int total_bit_count;

    function new(string name = "metro_coverage_closure_sequence");
        super.new(name);
        total_bit_count = 4096;
    endfunction

    function automatic void calc_bank_indices(
        input logic [31:0] id,
        input int bank_bits,
        output int i0,
        output int i1,
        output int i2,
        output int i3
    );
        logic [31:0] mix;
        logic [31:0] h0, h1, h2, h3;
        mix = id ^ (id >> 16);
        h0 = mix + (mix << 3) + (mix >> 5) + 32'h1234_5678;
        h1 = mix ^ (mix << 7) ^ ((mix >> 2) + 32'h8765_4321);
        h2 = (mix + (mix << 4)) ^ ((mix >> 9) + 32'h9E37_79B9);
        h3 = mix ^ ((mix << 5) + (mix >> 3) + 32'hDEAD_BEEF);
        i0 = h0 % bank_bits;
        i1 = h1 % bank_bits;
        i2 = h2 % bank_bits;
        i3 = h3 % bank_bits;
    endfunction

    task exercise_bank3_zero_expression();
        int program_count;
        logic [31:0] program_base;
        logic [31:0] query_base;
        int  bank_bits;
        logic seen0[];
        logic seen1[];
        logic seen2[];
        logic seen3[];
        int  i0, i1, i2, i3;
        logic [31:0] id;
        logic [31:0] candidate;
        logic found;
        program_count = 240;
        program_base = 32'h1000_0000;
        query_base = 32'h7000_0000;
        if ((total_bit_count == 0) || ((total_bit_count % 4) != 0)) begin
            `uvm_fatal(get_type_name(), $sformatf("Invalid BIT_COUNT=%0d for 4-bank coverage test", total_bit_count))
        end
        bank_bits = total_bit_count / 4;
        seen0 = new[bank_bits];
        seen1 = new[bank_bits];
        seen2 = new[bank_bits];
        seen3 = new[bank_bits];
        foreach (seen0[k]) begin
            seen0[k] = 1'b0;
            seen1[k] = 1'b0;
            seen2[k] = 1'b0;
            seen3[k] = 1'b0;
        end
        for (int n = 0; n < program_count; n++) begin
            id = program_base + n;
            calc_bank_indices(id, bank_bits, i0, i1, i2, i3);
            program_bloom(id);
            seen0[i0] = 1'b1;
            seen1[i1] = 1'b1;
            seen2[i2] = 1'b1;
            seen3[i3] = 1'b1;
        end
        found = 1'b0;
        candidate = '0;
        for (int n = 0; (n < 1_000_000) && !found; n++) begin
            id = query_base + n;
            calc_bank_indices(id, bank_bits, i0, i1, i2, i3);
            if (seen0[i0] && seen1[i1] && seen2[i2] && !seen3[i3]) begin
                candidate = id;
                found = 1'b1;
            end
        end
        if (!found) begin
            `uvm_fatal(get_type_name(), $sformatf("Cannot find bank3-zero directed query for BANK_BITS=%0d", bank_bits))
        end else begin
            calc_bank_indices(candidate, bank_bits, i0, i1, i2, i3);
            `uvm_info(get_type_name(), $sformatf("BANK3_ZERO_TARGET id=0x%08h indexes={%0d,%0d,%0d,%0d}; expected bank bits={1,1,1,0}", candidate, i0, i1, i2, i3), UVM_LOW)
            query_card(candidate, 1'b0, 1'b0);
        end
    endtask

    virtual task body();
        logic [31:0] rdata;
        logic [31:0] id;
        logic [31:0] onehot;
        logic [7:0] slot_addr;
        apb_write(8'h0C, 32'hFFFF_FFFF);
        apb_read (8'h0C, rdata);
        if (rdata !== 32'h0)
            `uvm_error(get_type_name(), $sformatf("Unmapped read 0x0C should return zero, got 0x%08h", rdata))
        apb_write(8'h50, 32'hFFFF_FFFF);
        apb_read (8'h50, rdata);
        if (rdata !== 32'h0)
            `uvm_error(get_type_name(), $sformatf("Out-of-range fallback read 0x50 should return zero, got 0x%08h", rdata))
        apb_write(8'h51, 32'h1234_5678);
        apb_read (8'h51, rdata);
        if (rdata !== 32'h0)
            `uvm_error(get_type_name(), $sformatf("Misaligned fallback read 0x51 should return zero, got 0x%08h", rdata))
        apb_write(8'h80, 32'hFFFF_FFFF);
        apb_read (8'h80, rdata);
        if (rdata !== 32'h0)
            `uvm_error(get_type_name(), $sformatf("Unmapped read 0x80 should return zero, got 0x%08h", rdata))
        apb_write(8'hFF, 32'h0);
        apb_read (8'hFF, rdata);
        if (rdata !== 32'h0)
            `uvm_error(get_type_name(), $sformatf("Unmapped read 0xFF should return zero, got 0x%08h", rdata))
        for (int b = 0; b < 32; b++) begin
            onehot = (32'h1 << b);
            apb_write(METRO_ID_REG, onehot);
            apb_read(METRO_ID_REG, rdata);
            if (rdata !== onehot)
                `uvm_error(get_type_name(), $sformatf("Walking-one ID readback failed bit=%0d got=0x%08h", b, rdata))
            id = ~onehot;
            apb_write(METRO_ID_REG, id);
            apb_read(METRO_ID_REG, rdata);
            if (rdata !== id)
                `uvm_error(get_type_name(), $sformatf("Walking-zero ID readback failed bit=%0d got=0x%08h", b, rdata))
        end
        for (int slot = 0; slot < METRO_FALLBACK_DEPTH; slot++) begin
            slot_addr = METRO_FALLBACK_BASE + (slot * 4);
            apb_write(slot_addr, 32'hFFFF_FFFF);
            apb_read(slot_addr, rdata);
            if (rdata !== 32'hFFFF_FFFF)
                `uvm_error(get_type_name(), $sformatf("Fallback all-ones readback failed slot=%0d got=0x%08h", slot, rdata))
            apb_write(slot_addr, 32'h0);
            apb_read(slot_addr, rdata);
            if (rdata !== 32'h0)
                `uvm_error(get_type_name(), $sformatf("Fallback clear readback failed slot=%0d got=0x%08h", slot, rdata))
        end
        exercise_bank3_zero_expression();
        id = 32'hA5C3_7E19;
        slot_addr = METRO_FALLBACK_BASE + (8 * 4);
        program_bloom(id);
        apb_write(slot_addr, id);
        query_card(id, 1'b1, 1'b1);
        apb_write(slot_addr, 32'h0);
        query_card(id, 1'b1, 1'b0);
    endtask
            
endclass

class metro_coverage_closure_test extends metro_base_test;
    `uvm_component_utils(metro_coverage_closure_test)

    function new(string name = "metro_coverage_closure_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        metro_coverage_closure_sequence seq;
        phase.raise_objection(this);
        wait_for_reset_release();
        seq = metro_coverage_closure_sequence::type_id::create("coverage_closure_seq");
        seq.total_bit_count = bit_count;
        seq.start(env.apb_agent.sequencer);

        @(negedge vif.PCLK);
        vif.PRESETN = 1'b0;
        repeat (2) @(negedge vif.PCLK);
        vif.PRESETN = 1'b1;
        repeat (2) @(posedge vif.PCLK);

        phase.drop_objection(this);
    endtask
    
endclass
