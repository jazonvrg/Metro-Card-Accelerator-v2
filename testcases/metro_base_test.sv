class metro_base_test extends uvm_test;
    `uvm_component_utils(metro_base_test)

    virtual metro_apb_if vif;
    int unsigned bit_count;
    metro_environment env;

    function new(string name = "metro_base_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual metro_apb_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Missing vif in config_db")
        if (!uvm_config_db#(int unsigned)::get(this, "", "bit_count", bit_count))
            `uvm_fatal(get_type_name(), "Missing bit_count in config_db")
        env = metro_environment::type_id::create("env", this);
        uvm_config_db#(virtual metro_apb_if)::set(this, "env", "vif", vif);
        uvm_config_db#(int unsigned)::set(this, "env", "bit_count", bit_count);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    virtual function void final_phase(uvm_phase phase);
        uvm_report_server svr;
        super.final_phase(phase);
        svr = uvm_report_server::get_server();
        if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) > 0) begin
            $display("#### TEST FAILED ####");
        end else begin
            $display("#### TEST PASSED ####");
        end
    endfunction: final_phase

    task wait_for_reset_release();
        wait (vif.PRESETN === 1'b1);
        repeat (2) @(posedge vif.PCLK);
    endtask

endclass
