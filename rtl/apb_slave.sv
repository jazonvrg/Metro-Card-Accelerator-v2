`timescale 1ns/1ps

module apb_slave (
    input  logic PSEL,
    input  logic PWRITE,
    input  logic PENABLE,
    output logic PREADY,
    output logic wr_en,
    output logic rd_en
);

    always_comb begin
        PREADY = PSEL && PENABLE;
        wr_en = PSEL && PENABLE && PWRITE;
        rd_en = PSEL && PENABLE && !PWRITE;
    end
    
endmodule
