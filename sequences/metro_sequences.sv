class metro_base_sequence extends uvm_sequence #(metro_apb_transaction);
    `uvm_object_utils(metro_base_sequence)
	
    function new(string name = "metro_base_sequence");
		super.new(name);
	endfunction

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
        apb_write(METRO_CTRL_REG, 32'h0000_0003);
        apb_read(METRO_STAT_REG, status);
        if (status[0] !== 1'b1 || status[1] !== 1'b0 || status[2] !== 1'b0)
            `uvm_error(get_type_name(), $sformatf("Program status mismatch ID=0x%08h status=0x%08h", id, status))
    endtask

    task query_card(input logic [31:0] id, input logic expected_match, input logic expected_fallback = 1'b0);
        logic [31:0] status;
        set_card_id(id);
        apb_write(METRO_CTRL_REG, 32'h0000_0001);
        apb_read(METRO_STAT_REG, status);
        if (status[0] !== 1'b1 || status[1] !== expected_match || status[2] !== expected_fallback)
            `uvm_error(get_type_name(), $sformatf("Query mismatch ID=0x%08h exp_match=%0b exp_fallback=%0b status=0x%08h", id, expected_match, expected_fallback, status))
        else
            `uvm_info(get_type_name(), $sformatf("QUERY PASS ID=0x%08h status=0x%08h", id, status), UVM_LOW)
    endtask
    task query_card_capture(input logic [31:0] id, output logic [31:0] status);
        set_card_id(id);
        apb_write(METRO_CTRL_REG, 32'h0000_0001);
        apb_read(METRO_STAT_REG, status);
    endtask
	
endclass

class metro_hash_sequence extends metro_base_sequence;
    `uvm_object_utils(metro_hash_sequence)
	
    function new(string name = "metro_hash_sequence");
		super.new(name);
	endfunction
	
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
	
    function new(string name = "metro_fallback_sequence");
		super.new(name);
	endfunction
	
    virtual task body();
        logic [31:0] fallback_only_id;
        fallback_only_id = 32'hD00D_CAFE;
        apb_write(METRO_FALLBACK_BASE, fallback_only_id);
        query_card(fallback_only_id, 1'b1, 1'b1);
        begin
            logic [31:0] readback;
            apb_read(METRO_FALLBACK_BASE, readback);
            if (readback !== fallback_only_id)
                `uvm_error(get_type_name(), $sformatf("Fallback slot readback mismatch expected=0x%08h got=0x%08h", fallback_only_id, readback))
        end
        apb_write(METRO_FALLBACK_BASE, 32'h0000_0000);
        query_card(fallback_only_id, 1'b0, 1'b0);
        query_card(32'hCAFE_BABE, 1'b0, 1'b0);
    endtask
			
endclass

class metro_register_sequence extends metro_base_sequence;
    `uvm_object_utils(metro_register_sequence)
	
    function new(string name = "metro_register_sequence");
		super.new(name);
	endfunction

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
	
    function new(string name = "metro_reset_sequence");
		super.new(name);
	endfunction
	
    virtual task body();
        logic [31:0] rdata;
        apb_read(METRO_STAT_REG, rdata);
        if (rdata !== 32'h0)
            `uvm_error(get_type_name(), $sformatf("Status register should be zero after reset: 0x%08h", rdata))
    endtask
			
endclass

class metro_fallback_table_sequence extends metro_base_sequence;
    `uvm_object_utils(metro_fallback_table_sequence)
	
    function new(string name = "metro_fallback_table_sequence");
		super.new(name);
	endfunction
	
    virtual task body();
        logic [31:0] rdata;
        logic [31:0] ids [0:2];
        logic [7:0] addrs [0:2];
        ids[0] = 32'hABCD_0001; addrs[0] = METRO_FALLBACK_BASE;
        ids[1] = 32'hABCD_0002; addrs[1] = METRO_FALLBACK_BASE + 8'h04;
        ids[2] = 32'hABCD_0010; addrs[2] = METRO_FALLBACK_BASE + 8'h3C;
        foreach (ids[i]) apb_write(addrs[i], ids[i]);
        foreach (ids[i]) begin
            apb_read(addrs[i], rdata);
            if (rdata !== ids[i])
                `uvm_error(get_type_name(), $sformatf("Fallback slot readback mismatch addr=0x%02h exp=0x%08h got=0x%08h", addrs[i], ids[i], rdata))
        end
        apb_write(addrs[1], 32'hABCD_00F2);
        apb_read(addrs[1], rdata);
        if (rdata !== 32'hABCD_00F2)
            `uvm_error(get_type_name(), $sformatf("Fallback overwrite failed got=0x%08h", rdata))
        apb_write(addrs[0], 32'h0);
        query_card(ids[0], 1'b0, 1'b0);
        query_card(32'hABCD_00F2, 1'b1, 1'b1);
        query_card(ids[2], 1'b1, 1'b1);
        apb_write(addrs[1], 32'h0);
        query_card(32'hABCD_00F2, 1'b0, 1'b0);
        apb_write(addrs[2], 32'h0);
        query_card(ids[2], 1'b0, 1'b0);
    endtask
			
endclass

class metro_metrics_sequence extends metro_base_sequence;
    `uvm_object_utils(metro_metrics_sequence)

    int num_bloom_black;
    int num_fallback_black;
    int num_clean;
    logic [31:0] bloom_base;
    logic [31:0] fallback_card_base;
    logic [31:0] clean_base;
    integer metrics_fd;
    int  samples_written;
    int  predicted_black_count;

    function new(string name = "metro_metrics_sequence");
        super.new(name);
        num_bloom_black = 240;
        num_fallback_black = METRO_FALLBACK_DEPTH;
        num_clean = 1024;
        bloom_base = 32'h1000_0000;
        fallback_card_base = 32'hD000_0100;
        clean_base = 32'h7000_0000;
        metrics_fd = 0;
        samples_written = 0;
        predicted_black_count = 0;
    endfunction

    task collect_sample(input logic [31:0] id,
                        input logic true_label,
                        input string source_name,
                        input logic check_expected = 1'b0,
                        input logic expected_match = 1'b0,
                        input logic expected_fallback = 1'b0);
        logic [31:0] status;
        logic predicted_label;
        query_card_capture(id, status);
        if (status[0] !== 1'b1)
            `uvm_error(get_type_name(), $sformatf("Metric sample ID=0x%08h has DONE=%b; status=0x%08h", id, status[0], status))
        if ((status[1] !== 1'b0) && (status[1] !== 1'b1)) begin
            `uvm_error(get_type_name(), $sformatf("Metric sample ID=0x%08h has unknown MATCH bit; status=0x%08h", id, status))
            predicted_label = 1'b0; 
        end else begin
            predicted_label = status[1];
        end
        if (check_expected &&
            ((status[1] !== expected_match) || (status[2] !== expected_fallback))) begin
            `uvm_error(get_type_name(), $sformatf("Directed metric case mismatch ID=0x%08h expected MATCH=%0b FALLBACK=%0b got status=0x%08h", id, expected_match, expected_fallback, status))
        end
		$fdisplay(metrics_fd, "%08h,%0d,%0d,%0d,%08h,%s", id, true_label, predicted_label, status[2], status, source_name);
        samples_written++;
        if (predicted_label) predicted_black_count++;
    endtask

    virtual task body();
        logic [31:0] id;
        logic [7:0] slot_addr;
        metrics_fd = $fopen("log/metro_metrics_results.csv", "w");
        if (metrics_fd == 0)
            `uvm_fatal(get_type_name(), "Cannot create log/metro_metrics_results.csv; run from sim/ with log/ directory present")
        $fdisplay(metrics_fd, "card_id,true_label,predicted_label,fallback_match,status_word,source");
        samples_written = 0;
        predicted_black_count = 0;
        `uvm_info(get_type_name(), $sformatf("Preparing labelled metric dataset: bloom_black=%0d fallback_black=%0d clean=%0d", num_bloom_black, num_fallback_black, num_clean), UVM_LOW)
        for (int i = 0; i < num_bloom_black; i++) begin
            id = bloom_base + i;
            program_bloom(id);
        end
        if (num_fallback_black > METRO_FALLBACK_DEPTH)
            `uvm_fatal(get_type_name(), "num_fallback_black exceeds fallback table depth")
        for (int i = 0; i < num_fallback_black; i++) begin
            id = fallback_card_base + i;
            slot_addr = METRO_FALLBACK_BASE + (i * 4);
            apb_write(slot_addr, id);
        end
        for (int i = 0; i < num_bloom_black; i++) begin
            id = bloom_base + i;
            collect_sample(id, 1'b1, "bloom_black");
        end
        for (int i = 0; i < num_fallback_black; i++) begin
            id = fallback_card_base + i;
            collect_sample(id, 1'b1, "fallback_black");
        end
        if (num_clean < 3)
            `uvm_fatal(get_type_name(), "num_clean must be >= 3 for directed collision cases")
        id = 32'h36C0_C591;
        collect_sample(id, 1'b0, "clean_hash_collision", 1'b1, 1'b1, 1'b0);
        id = 32'h821A_34F5;
        collect_sample(id, 1'b0, "clean_hash_collision", 1'b1, 1'b1, 1'b0);
        id = 32'h8019_30D1;
        collect_sample(id, 1'b0, "clean_hash_collision", 1'b1, 1'b1, 1'b0);
        for (int i = 0; i < (num_clean - 3); i++) begin
            id = clean_base + i;
            collect_sample(id, 1'b0, "clean");
        end
        $fflush(metrics_fd);
        $fclose(metrics_fd);
        metrics_fd = 0;
		`uvm_info(get_type_name(), $sformatf("Wrote %0d observed samples to log/metro_metrics_results.csv; predicted_black=%0d", samples_written, predicted_black_count), UVM_LOW)
    endtask
	
endclass
