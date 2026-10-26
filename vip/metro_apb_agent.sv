class metro_apb_agent extends uvm_agent;
    `uvm_component_utils(metro_apb_agent)

    virtual metro_apb_if vif;
    metro_apb_sequencer sequencer;
    metro_apb_driver    driver;
    metro_apb_monitor   monitor;

    function new(string name = "metro_apb_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual metro_apb_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Could not get metro_apb_if via config_db")
        sequencer = metro_apb_sequencer::type_id::create("sequencer", this);
        driver    = metro_apb_driver::type_id::create("driver", this);
        monitor   = metro_apb_monitor::type_id::create("monitor", this);
        uvm_config_db#(virtual metro_apb_if)::set(this, "driver",  "vif", vif);
        uvm_config_db#(virtual metro_apb_if)::set(this, "monitor", "vif", vif);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass
