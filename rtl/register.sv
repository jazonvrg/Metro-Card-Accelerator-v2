`timescale 1ns/1ps

// APB register bank.
// 0x00 ID_REG   : ID selected for program/query
// 0x04 CTRL_REG : bit 0 START pulse, bit 1 MODE (0=query, 1=Bloom program)
// 0x08 STAT_REG : bit 0 DONE, bit 1 MATCH, bit 2 FALLBACK_MATCH
// 0x10..        : exact-match fallback slots, each 32-bit aligned
module register #(
    parameter int unsigned ADDR = 8,
    parameter int unsigned DATA = 32
) (
    input  logic             PCLK,
    input  logic             PRESETN,
    input  logic             wr_en,
    input  logic             rd_en,
    input  logic [ADDR-1:0]  PADDR,
    input  logic [DATA-1:0]  PWDATA,
    output logic [DATA-1:0]  PRDATA,
    output logic [DATA-1:0]  id_data,
    output logic             start,
    output logic             mode,
    input  logic             match,
    input  logic             fallback_match,
    input  logic             done,
    input  logic [DATA-1:0]  fallback_rdata
);
    localparam logic [ADDR-1:0] ID_REG   = 'h00;
    localparam logic [ADDR-1:0] CTRL_REG = 'h04;
    localparam logic [ADDR-1:0] STAT_REG = 'h08;

    always_ff @(posedge PCLK or negedge PRESETN) begin
        if (!PRESETN) begin
            id_data <= '0;
            start   <= 1'b0;
            mode    <= 1'b0;
        end else begin
            // START is a one-cycle pulse. Status is sticky until reset so SW can
            // read it after the APB write that issued the operation.
            start <= 1'b0;
            if (wr_en) begin
                case (PADDR)
                    ID_REG: id_data <= PWDATA;
                    CTRL_REG: begin
                        start <= PWDATA[0];
                        mode  <= PWDATA[1];
                    end
                    default: ; // fallback slots are written by fallback_lookup
                endcase
            end
        end
    end

    always_comb begin
        PRDATA = '0;
        if (rd_en) begin
            case (PADDR)
                ID_REG:   PRDATA = id_data;
                CTRL_REG: PRDATA = {{(DATA-2){1'b0}}, mode, start};
                STAT_REG: PRDATA = {{(DATA-3){1'b0}}, fallback_match, match, done};
                default:  PRDATA = fallback_rdata;
            endcase
        end
    end
endmodule
