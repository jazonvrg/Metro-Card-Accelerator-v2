class metro_apb_monitor extends uvm_monitor;
    `uvm_component_utils(metro_apb_monitor)

    virtual metro_apb_if vif;
    uvm_analysis_port #(metro_apb_transaction) ap;

    function new(string name = "metro_apb_monitor", uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual metro_apb_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Could not get metro_apb_if via config_db")
    endfunction

    task run_phase(uvm_phase phase);
        metro_apb_transaction tr;
        forever begin
            @(posedge vif.PCLK);
            if (vif.PRESETN && vif.PSEL && vif.PENABLE && vif.PREADY) begin
                tr = metro_apb_transaction::type_id::create("observed_transfer", this);
                tr.is_write = vif.PWRITE;
                tr.addr = vif.PADDR;
                tr.data = vif.PWDATA;
                tr.rdata = vif.PWRITE ? '0 : vif.PRDATA;
                ap.write(tr);
                `uvm_info(get_type_name(), $sformatf("APB %s addr=0x%02h wdata=0x%08h rdata=0x%08h", tr.is_write ? "WRITE" : "READ", tr.addr, tr.data, tr.rdata), UVM_HIGH)
            end
        end
    endtask

endclass
