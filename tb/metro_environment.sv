class metro_environment extends uvm_env;
    `uvm_component_utils(metro_environment)

    virtual metro_apb_if vif;
    int unsigned bit_count;
    metro_apb_agent apb_agent;
    metro_scoreboard scoreboard;

    function new(string name = "metro_environment", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual metro_apb_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Missing vif in config_db")
        if (!uvm_config_db#(int unsigned)::get(this, "", "bit_count", bit_count))
            `uvm_fatal(get_type_name(), "Missing bit_count in config_db")
        apb_agent = metro_apb_agent::type_id::create("apb_agent", this);
        scoreboard = metro_scoreboard::type_id::create("scoreboard", this);
        uvm_config_db#(virtual metro_apb_if)::set(this, "apb_agent", "vif", vif);
        uvm_config_db#(int unsigned)::set(this, "scoreboard", "bit_count", bit_count);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        apb_agent.monitor.ap.connect(scoreboard.apb_export);
    endfunction

endclass
