class metro_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(metro_scoreboard)

    uvm_analysis_imp #(metro_apb_transaction, metro_scoreboard) apb_export;

    int bit_count;
    logic model_bits[];
    logic [31:0] current_id;
    logic [31:0] fallback_ids [0:METRO_FALLBACK_DEPTH-1];
    logic pending_valid;
    logic expected_match;
    logic expected_fallback_match;
    logic expected_bloom_match;
    logic last_operation_program;
    logic operation_count;
    logic status_checks;
    logic fallback_queries;

    covergroup operation_mode_cg with function sample(logic sample_is_program);
        option.per_instance = 1;
        cp_operation_mode: coverpoint sample_is_program {
            bins query_mode = {1'b0};
            bins program_mode = {1'b1};
        }
    endgroup

    covergroup fallback_slot_action_cg with function sample(
        int sample_slot,
        bit [1:0] sample_action
    );
        option.per_instance = 1;
        cp_slot: coverpoint sample_slot {
            bins first_slot = {0};
            bins middle_slot = {[1:14]};
            bins last_slot = {15};
        }
        cp_action: coverpoint sample_action {
            bins insert_new = {2'd0};
            bins overwrite = {2'd1};
            bins clear = {2'd2};
        }
        cp_clear_vs_write: coverpoint (sample_action == 2'd2) {
            bins write_or_overwrite = {1'b0};
            bins clear_slot = {1'b1};
        }
        slot_x_action: cross cp_slot, cp_clear_vs_write;
    endgroup
    
    covergroup query_result_cg with function sample(
        logic [1:0] sample_expected_path,
        logic sample_actual_match,
        logic sample_actual_fallback,
        logic sample_done,
        logic sample_match_agrees,
        logic sample_fallback_agrees
    );
        option.per_instance = 1;
        cp_expected_path: coverpoint sample_expected_path {
            bins no_match = {2'b00};
            bins bloom_only = {2'b01};
            bins fallback_only = {2'b10};
            bins bloom_and_fallback = {2'b11};
        }
        cp_actual_match: coverpoint sample_actual_match {
            bins allowed = {1'b0};
            bins blocked = {1'b1};
        }
        cp_actual_fallback: coverpoint sample_actual_fallback {
            bins fallback_miss = {1'b0};
            bins fallback_hit  = {1'b1};
        }
        cp_done: coverpoint sample_done {
            bins done = {1'b1};
            ignore_bins not_done = {1'b0};
        }
        cp_match_agreement: coverpoint sample_match_agrees {
            bins agrees = {1'b1};
            ignore_bins disagrees = {1'b0};
        }
        cp_fallback_agreement: coverpoint sample_fallback_agrees {
            bins agrees = {1'b1};
            ignore_bins disagrees = {1'b0};
        }
    endgroup

    covergroup idle_status_cg with function sample(logic sample_is_zero);
        option.per_instance = 1;
        cp_idle_status: coverpoint sample_is_zero {
            bins zero_status = {1'b1};
            ignore_bins nonzero_status = {1'b0};
        }
    endgroup

    function new(string name = "metro_scoreboard", uvm_component parent);
        super.new(name, parent);
        apb_export = new("apb_export", this);
        operation_mode_cg = new();
        fallback_slot_action_cg = new();
        query_result_cg = new();
        idle_status_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(int)::get(this, "", "bit_count", bit_count))
            `uvm_fatal(get_type_name(), "Missing bit_count in config_db")
        if (bit_count == 0)
            `uvm_fatal(get_type_name(), "bit_count must be greater than zero")
        model_bits = new[bit_count];
        foreach (model_bits[i]) model_bits[i] = 1'b0;
        foreach (fallback_ids[i]) fallback_ids[i] = '0;
        current_id = '0;
        pending_valid = 1'b0;
        expected_match = 1'b0;
        expected_fallback_match = 1'b0;
        expected_bloom_match = 1'b0;
        last_operation_program = 1'b0;
        operation_count = 0;
        status_checks = 0;
        fallback_queries = 0;
    endfunction

    function automatic void calc_indices(
        input logic [31:0] id,
        output int i1,
        output int i2,
        output int i3,
        output int i4
    );
        logic [31:0] mix;
        logic [31:0] h1, h2, h3, h4;
        mix = id ^ (id >> 16);
        h1 = mix + (mix << 3) + (mix >> 5) + 32'h1234_5678;
        h2 = mix ^ (mix << 7) ^ ((mix >> 2) + 32'h8765_4321);
        h3 = (mix + (mix << 4)) ^ ((mix >> 9) + 32'h9E37_79B9);
        h4 = mix ^ ((mix << 5) + (mix >> 3) + 32'hDEAD_BEEF);
        i1 = h1 % bit_count;
        i2 = h2 % bit_count;
        i3 = h3 % bit_count;
        i4 = h4 % bit_count;
    endfunction

    function automatic integer fallback_slot(input logic [7:0] addr);
        integer offset;
        begin
            fallback_slot = -1;
            if (addr >= METRO_FALLBACK_BASE) begin
                offset = addr - METRO_FALLBACK_BASE;
                if (((offset % 4) == 0) && ((offset / 4) < METRO_FALLBACK_DEPTH))
                    fallback_slot = offset / 4;
            end
        end
    endfunction

    function automatic bit model_fallback_hit(input logic [31:0] id);
        logic found;
        found = 1'b0;
        if (id != '0) begin
            foreach (fallback_ids[i])
                if (fallback_ids[i] == id) found = 1'b1;
        end
        return found;
    endfunction

    function void write(metro_apb_transaction tr);
        int i1, i2, i3, i4;
        integer slot;
        logic previous_entry_valid;
        logic [1:0] fallback_action;
        logic [1:0] expected_path;

        if (tr.is_write) begin
            slot = fallback_slot(tr.addr);
            if (slot >= 0) begin
                previous_entry_valid = (fallback_ids[slot] != '0);
                if (tr.data == 32'h0)
                    fallback_action = 2'd2;
                else if (previous_entry_valid)
                    fallback_action = 2'd1;
                else
                    fallback_action = 2'd0;
                fallback_slot_action_cg.sample(slot, fallback_action);
                fallback_ids[slot] = tr.data;
                `uvm_info(get_type_name(), $sformatf("MODEL FALLBACK slot=%0d value=0x%08h", slot, tr.data), UVM_MEDIUM)
            end else begin
                case (tr.addr)
                    METRO_ID_REG: current_id = tr.data;
                    METRO_CTRL_REG: begin
                        if (tr.data[0]) begin
                            last_operation_program = tr.data[1];
                            operation_mode_cg.sample(last_operation_program);
                            calc_indices(current_id, i1, i2, i3, i4);
                            operation_count++;
                            pending_valid = 1'b1;
                            expected_fallback_match = 1'b0;
                            if (tr.data[1]) begin
                                model_bits[i1] = 1'b1;
                                model_bits[i2] = 1'b1;
                                model_bits[i3] = 1'b1;
                                model_bits[i4] = 1'b1;
                                expected_bloom_match = 1'b0;
                                expected_match = 1'b0;
                                `uvm_info(get_type_name(), $sformatf("MODEL PROGRAM id=0x%08h indexes={%0d,%0d,%0d,%0d}", current_id, i1, i2, i3, i4), UVM_MEDIUM)
                            end else begin
                                expected_bloom_match = model_bits[i1] & model_bits[i2] & model_bits[i3] & model_bits[i4];
                                expected_fallback_match = model_fallback_hit(current_id);
                                expected_match = expected_bloom_match | expected_fallback_match;
                                if (expected_fallback_match) fallback_queries++;
                                `uvm_info(get_type_name(), $sformatf("MODEL QUERY id=0x%08h bloom=%0b fallback=%0b combined=%0b", current_id, expected_bloom_match, expected_fallback_match, expected_match), UVM_MEDIUM)
                            end
                        end
                    end
                    default: ;
                endcase
            end
        end else if ((tr.addr == METRO_STAT_REG) && pending_valid) begin
            status_checks++;
            if (tr.rdata[0] !== 1'b1)
                `uvm_error(get_type_name(), $sformatf("STATUS done expected 1, got %0b: 0x%08h", tr.rdata[0], tr.rdata))
            if (tr.rdata[1] !== expected_match)
                `uvm_error(get_type_name(), $sformatf("MATCH mismatch ID=0x%08h exp=%0b got=%0b status=0x%08h", current_id, expected_match, tr.rdata[1], tr.rdata))
            if (tr.rdata[2] !== expected_fallback_match)
                `uvm_error(get_type_name(), $sformatf("FALLBACK_MATCH mismatch ID=0x%08h exp=%0b got=%0b status=0x%08h", current_id, expected_fallback_match, tr.rdata[2], tr.rdata))
            if (!last_operation_program) begin
                expected_path = {expected_fallback_match, expected_bloom_match};
                query_result_cg.sample(expected_path, tr.rdata[1], tr.rdata[2], tr.rdata[0], (tr.rdata[1] === expected_match), (tr.rdata[2] === expected_fallback_match));
            end
            if ((tr.rdata[0] === 1'b1) && (tr.rdata[1] === expected_match) &&
                (tr.rdata[2] === expected_fallback_match))
                `uvm_info(get_type_name(), $sformatf("PASS ID=0x%08h bloom=%0b fallback=%0b match=%0b status=0x%08h", current_id, expected_bloom_match, expected_fallback_match, expected_match, tr.rdata), UVM_LOW)
            pending_valid = 1'b0;
        end else if ((tr.addr == METRO_STAT_REG) && !tr.is_write) begin
            idle_status_cg.sample(tr.rdata == 32'h0);
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Scoreboard: operations=%0d status_checks=%0d fallback_hits=%0d BIT_COUNT=%0d", operation_count, status_checks, fallback_queries, bit_count), UVM_LOW)
        `uvm_info("SCOREBOARD_FUNC_COV", $sformatf("Scoreboard functional coverage: operation_mode=%0.2f%% fallback_slot_action=%0.2f%% query_result=%0.2f%% idle_status=%0.2f%%", operation_mode_cg.get_coverage(), fallback_slot_action_cg.get_coverage(), query_result_cg.get_coverage(), idle_status_cg.get_coverage()), UVM_LOW)
    endfunction

endclass
