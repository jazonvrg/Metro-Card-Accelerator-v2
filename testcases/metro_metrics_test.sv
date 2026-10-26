class metro_metrics_test extends metro_base_test;
    `uvm_component_utils(metro_metrics_test)

    function new(string name = "metro_metrics_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        metro_metrics_sequence seq;
        phase.raise_objection(this);
        wait_for_reset_release();

        seq = metro_metrics_sequence::type_id::create("metrics_seq");
        seq.num_bloom_black = 240;
        seq.num_fallback_black = METRO_FALLBACK_DEPTH;
        seq.num_clean = 1024;
        seq.bloom_base = 32'h1000_0000;
        seq.fallback_card_base = 32'hD000_0100;
        seq.clean_base = 32'h7000_0000;
        seq.start(env.apb_agent.sequencer);

        phase.drop_objection(this);
    endtask

endclass
