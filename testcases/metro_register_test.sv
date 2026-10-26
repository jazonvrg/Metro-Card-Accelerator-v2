class metro_register_test extends metro_base_test;
    `uvm_component_utils(metro_register_test)
    function new(string name = "metro_register_test", uvm_component parent = null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        metro_register_sequence seq;
        phase.raise_objection(this);
        wait_for_reset_release();
        seq = metro_register_sequence::type_id::create("seq");
        seq.start(env.apb_agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass
