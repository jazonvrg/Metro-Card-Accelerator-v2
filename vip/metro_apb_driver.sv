class metro_apb_driver extends uvm_driver #(metro_apb_transaction);
    `uvm_component_utils(metro_apb_driver)
    virtual metro_apb_if vif;

    function new(string name = "metro_apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual metro_apb_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Could not get metro_apb_if via config_db")
    endfunction

    task run_phase(uvm_phase phase);
        metro_apb_transaction req;
        metro_apb_transaction rsp;
        drive_idle();
        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            rsp = metro_apb_transaction::type_id::create("rsp");
            rsp.copy(req);
            rsp.set_id_info(req);
            seq_item_port.item_done(rsp);
        end
    endtask

    task drive_idle();
        vif.PSEL    <= 1'b0;
        vif.PWRITE  <= 1'b0;
        vif.PENABLE <= 1'b0;
        vif.PADDR   <= '0;
        vif.PWDATA  <= '0;
    endtask

    task drive_transfer(metro_apb_transaction tr);
        // Drive on falling edges; DUT and monitor sample on rising edges.
        @(negedge vif.PCLK);
        vif.PSEL    <= 1'b1;
        vif.PWRITE  <= tr.is_write;
        vif.PENABLE <= 1'b0;
        vif.PADDR   <= tr.addr;
        vif.PWDATA  <= tr.data;

        @(negedge vif.PCLK);
        vif.PENABLE <= 1'b1;
        do begin
            @(posedge vif.PCLK);
        end while (vif.PREADY !== 1'b1);

        if (!tr.is_write)
            tr.rdata = vif.PRDATA;

        @(negedge vif.PCLK);
        drive_idle();
    endtask
endclass
