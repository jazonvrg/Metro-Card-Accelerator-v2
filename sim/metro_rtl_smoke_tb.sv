`timescale 1ns/1ps
module metro_rtl_smoke_tb;
    logic PCLK = 0;
    always #5 PCLK = ~PCLK;
    logic PRESETN, PSEL, PWRITE, PENABLE;
    logic [7:0] PADDR;
    logic [31:0] PWDATA, PRDATA;
    logic PREADY;
    int errors = 0;

    metro_card_top #(.BIT_COUNT(4096), .FALLBACK_DEPTH(16)) dut (
        .PCLK(PCLK), .PRESETN(PRESETN), .PSEL(PSEL), .PWRITE(PWRITE),
        .PENABLE(PENABLE), .PADDR(PADDR), .PWDATA(PWDATA),
        .PRDATA(PRDATA), .PREADY(PREADY)
    );

    task automatic apb_write(input logic [7:0] addr, input logic [31:0] data);
        @(negedge PCLK); PSEL=1; PWRITE=1; PENABLE=0; PADDR=addr; PWDATA=data;
        @(negedge PCLK); PENABLE=1;
        do @(posedge PCLK); while (PREADY !== 1'b1);
        @(negedge PCLK); PSEL=0; PWRITE=0; PENABLE=0; PADDR=0; PWDATA=0;
    endtask

    task automatic apb_read(input logic [7:0] addr, output logic [31:0] data);
        @(negedge PCLK); PSEL=1; PWRITE=0; PENABLE=0; PADDR=addr; PWDATA=0;
        @(negedge PCLK); PENABLE=1;
        do @(posedge PCLK); while (PREADY !== 1'b1);
        data = PRDATA;
        @(negedge PCLK); PSEL=0; PENABLE=0; PADDR=0;
    endtask

    task automatic check_status(input logic [31:0] expected, input string label_text);
        logic [31:0] status;
        apb_read(8'h08, status);
        if (status[2:0] !== expected[2:0]) begin
            $error("%s: expected STAT[2:0]=%03b got %03b", label_text, expected[2:0], status[2:0]);
            errors++;
        end else $display("PASS %-34s STAT=0x%08h", label_text, status);
    endtask

    initial begin
        PRESETN=0; PSEL=0; PWRITE=0; PENABLE=0; PADDR=0; PWDATA=0;
        repeat (4) @(negedge PCLK); PRESETN=1;
        repeat (2) @(posedge PCLK);

        // Blacklist ID exists only in the exact fallback table, not in Bloom.
        apb_write(8'h10, 32'hD00D_CAFE);
        apb_write(8'h00, 32'hD00D_CAFE);
        apb_write(8'h04, 32'h1); // query
        check_status(32'h7, "fallback-only blacklist ID caught");

        // Clear fallback slot; the same ID must no longer match while Bloom is empty.
        apb_write(8'h10, 32'h0);
        apb_write(8'h00, 32'hD00D_CAFE);
        apb_write(8'h04, 32'h1);
        check_status(32'h1, "cleared fallback ID no longer matches");

        // Conventional Bloom insert followed by query.
        apb_write(8'h00, 32'h1234_ABCD);
        apb_write(8'h04, 32'h3); // START=1, MODE=program
        apb_write(8'h00, 32'h1234_ABCD);
        apb_write(8'h04, 32'h1); // query
        check_status(32'h3, "Bloom-inserted ID matches");

        if (errors == 0) $display("RTL SMOKE TEST PASSED");
        else $fatal(1, "RTL SMOKE TEST FAILED with %0d error(s)", errors);
        $finish;
    end
endmodule
