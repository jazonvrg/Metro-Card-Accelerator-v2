`timescale 1ns/1ps

module testbench;
    import uvm_pkg::*;
    import metro_apb_pkg::*;
    import test_pkg::*;

    localparam int ADDR = 8;
    localparam int DATA = 32;
    localparam int BIT_COUNT = 4096;
    localparam int HASH = $clog2(BIT_COUNT);
    localparam int FALLBACK_DEPTH = METRO_FALLBACK_DEPTH;

    logic PCLK = 1'b0;
    always #5 PCLK = ~PCLK;
    metro_apb_if apb_if(PCLK);

    metro_card_top #(
        .ADDR				(ADDR),
	.DATA				(DATA),
	.HASH				(HASH),
	.BIT_COUNT			(BIT_COUNT),
        .FALLBACK_DEPTH		(FALLBACK_DEPTH),
	.FALLBACK_BASE_ADDR	(METRO_FALLBACK_BASE)
    ) dut (
        .PCLK				(PCLK),
	.PRESETN			(apb_if.PRESETN),
	.PSEL				(apb_if.PSEL),
        .PWRITE				(apb_if.PWRITE),
	.PENABLE			(apb_if.PENABLE),
        .PADDR				(apb_if.PADDR),
	.PWDATA				(apb_if.PWDATA),
        .PRDATA				(apb_if.PRDATA),
	.PREADY				(apb_if.PREADY)
    );

    initial begin
        apb_if.PRESETN = 1'b0;
        apb_if.PSEL = 1'b0;
        apb_if.PWRITE = 1'b0;
        apb_if.PENABLE = 1'b0;
        apb_if.PADDR = '0;
        apb_if.PWDATA = '0;
        #35 apb_if.PRESETN = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual metro_apb_if)::set(null, "uvm_test_top", "vif", apb_if);
        uvm_config_db#(int)::set(null, "uvm_test_top", "bit_count", BIT_COUNT);
        run_test();
    end
	
endmodule
