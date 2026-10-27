// Additional stimulus intended to close the documented coverage holes without
// modifying the VIP or reusable sequence library.
class metro_coverage_closure_sequence extends metro_base_sequence;
    `uvm_object_utils(metro_coverage_closure_sequence)

    function new(string name = "metro_coverage_closure_sequence");
        super.new(name);
    endfunction

    virtual task body();
        logic [31:0] rdata;
        logic [31:0] id;
        logic [31:0] onehot;
        logic [7:0] slot_addr;

        // 1) Exercise fallback decoder's lower-bound, misaligned and out-of-range cases.
        // 0x0C is below the fallback region. 0x50 is aligned but slot 16 is out of range.
        // 0x51 is misaligned. 0x80/0xFF toggle the top address bit and remain unmapped.
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

        // 2) Walking-one / walking-zero IDs: exercise all ID register and hash input bits.
        for (int unsigned b = 0; b < 32; b++) begin
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

        // 3) Every fallback slot receives all-ones then zero. This hits both
        // write/clear cross bins for first, middle and last slot classes, and
        // toggles every stored data bit and readback data bit in every entry.
        for (int unsigned slot = 0; slot < METRO_FALLBACK_DEPTH; slot++) begin
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

        // 4) Hit the missing scoreboard path: the same ID must match in Bloom
        // and exact fallback independently, then Bloom must continue matching
        // after the fallback entry is cleared.
        id = 32'hA5C3_7E19;
        slot_addr = METRO_FALLBACK_BASE + (8 * 4); // slot 8 (middle)
        program_bloom(id);
        apb_write(slot_addr, id);
        query_card(id, 1'b1, 1'b1); // expected_path 2'b11 -> bloom_and_fallback
        apb_write(slot_addr, 32'h0);
        query_card(id, 1'b1, 1'b0); // expected_path 2'b01 -> bloom_only
    endtask
endclass

class metro_coverage_closure_test extends metro_base_test;
    `uvm_component_utils(metro_coverage_closure_test)

    function new(string name = "metro_coverage_closure_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        metro_coverage_closure_sequence seq;
        phase.raise_objection(this);
        wait_for_reset_release();
        seq = metro_coverage_closure_sequence::type_id::create("coverage_closure_seq");
        seq.start(env.apb_agent.sequencer);

        // Pulse reset after all transactions so sticky DONE/MATCH flags toggle
        // back to zero and reset/toggle coverage sees both transition directions.
        @(negedge vif.PCLK);
        vif.PRESETN = 1'b0;
        repeat (2) @(negedge vif.PCLK);
        vif.PRESETN = 1'b1;
        repeat (2) @(posedge vif.PCLK);

        phase.drop_objection(this);
    endtask
endclass
