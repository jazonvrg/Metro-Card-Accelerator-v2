`timescale 1ns/1ps

interface metro_apb_if(input logic PCLK);

    logic        PRESETN;
    logic        PSEL;
    logic        PWRITE;
    logic        PENABLE;
    logic [7:0]  PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;

endinterface
