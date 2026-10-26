`timescale 1ns/1ps

// Exact-match side table for blacklist IDs absent from the Bloom filter.
// APB addresses FALLBACK_BASE + 4*slot select one of DEPTH entries.
// Writing 0 clears/disables that entry; nonzero values are exact card IDs.
module fallback_lookup #(
    parameter int unsigned ADDR  = 8,
    parameter int unsigned DATA  = 32,
    parameter int unsigned DEPTH = 16,
    parameter logic [ADDR-1:0] BASE_ADDR = 8'h10
) (
    input  logic             PCLK,
    input  logic             PRESETN,
    input  logic             wr_en,
    input  logic             rd_en,
    input  logic [ADDR-1:0]  PADDR,
    input  logic [DATA-1:0]  PWDATA,
    input  logic [DATA-1:0]  id_data,
    output logic             hit,
    output logic [DATA-1:0]  read_data
);
    logic [DATA-1:0] entries [0:DEPTH-1];
    integer write_slot;
    integer read_slot;
    integer i;

    function automatic integer slot_from_addr(input logic [ADDR-1:0] addr);
        integer offset;
        begin
            slot_from_addr = -1;
            if (addr >= BASE_ADDR) begin
                offset = addr - BASE_ADDR;
                if (((offset % 4) == 0) && ((offset / 4) < DEPTH))
                    slot_from_addr = offset / 4;
            end
        end
    endfunction

    always_comb begin
        write_slot = slot_from_addr(PADDR);
        read_slot  = slot_from_addr(PADDR);
        hit        = 1'b0;
        for (int unsigned k = 0; k < DEPTH; k++) begin
            if ((id_data != '0) && (entries[k] == id_data))
                hit = 1'b1;
        end
        read_data = '0;
        if (rd_en && (read_slot >= 0))
            read_data = entries[read_slot];
    end

    always_ff @(posedge PCLK or negedge PRESETN) begin
        if (!PRESETN) begin
            for (i = 0; i < DEPTH; i = i + 1)
                entries[i] <= '0;
        end else if (wr_en && (write_slot >= 0)) begin
            entries[write_slot] <= PWDATA;
        end
    end
endmodule
