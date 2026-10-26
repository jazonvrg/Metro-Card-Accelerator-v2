class metro_fallback_miss_test extends metro_base_test;
    `uvm_component_utils(metro_fallback_miss_test)

    function new(string name = "metro_fallback_miss_test", uvm_component parent); 
	super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        metro_fallback_sequence seq;
        phase.raise_objection(this);
        wait_for_reset_release();
        seq = metro_fallback_sequence::type_id::create("seq");
        seq.start(env.apb_agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass
