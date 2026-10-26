`timescale 1ns/1ps

module register #(
    parameter int ADDR = 8,
    parameter int DATA = 32
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

    parameter logic [ADDR-1:0] ID_REG = 'h00;
    parameter logic [ADDR-1:0] CTRL_REG = 'h04;
    parameter logic [ADDR-1:0] STAT_REG = 'h08;

    always_ff @(posedge PCLK or negedge PRESETN) begin
        if (!PRESETN) begin
            id_data <= '0;
            start <= 1'b0;
            mode <= 1'b0;
        end else begin
            start <= 1'b0;
            if (wr_en) begin
                case (PADDR)
                    ID_REG: id_data <= PWDATA;
                    CTRL_REG: begin
                        start <= PWDATA[0];
                        mode <= PWDATA[1];
                    end
                    default: ;
                endcase
            end
        end
    end

    always_comb begin
        PRDATA = '0;
        if (rd_en) begin
            case (PADDR)
                ID_REG: PRDATA = id_data;
                CTRL_REG: PRDATA = {{(DATA-2){1'b0}}, mode, start};
                STAT_REG: PRDATA = {{(DATA-3){1'b0}}, fallback_match, match, done};
                default: PRDATA = fallback_rdata;
            endcase
        end
    end

endmodule
