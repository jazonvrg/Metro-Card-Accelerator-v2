class metro_smoke_test extends metro_base_test;
    `uvm_component_utils(metro_smoke_test)
    function new(string name = "metro_smoke_test", uvm_component parent = null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        metro_hash_sequence hash_seq;
        metro_fallback_sequence fallback_seq;
        phase.raise_objection(this);
        wait_for_reset_release();
        // Keep the fallback false-negative test first while Bloom is empty;
        // then run the conventional Bloom insertion/query test.
        fallback_seq = metro_fallback_sequence::type_id::create("fallback_seq");
        fallback_seq.start(env.apb_agent.sequencer);
        hash_seq = metro_hash_sequence::type_id::create("hash_seq");
        hash_seq.start(env.apb_agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass
