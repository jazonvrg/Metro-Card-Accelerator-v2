`timescale 1ns/1ps

module metro_card_top #(
    parameter int unsigned ADDR = 8,
    parameter int unsigned DATA = 32,
    parameter int unsigned HASH = 24,
    parameter int unsigned BIT_COUNT = 9_600_000,
    parameter int unsigned FALLBACK_DEPTH = 16,
    parameter logic [ADDR-1:0] FALLBACK_BASE_ADDR = 8'h10
) (
    input  logic             PCLK,
    input  logic             PRESETN,
    input  logic             PSEL,
    input  logic             PWRITE,
    input  logic             PENABLE,
    input  logic [ADDR-1:0]  PADDR,
    input  logic [DATA-1:0]  PWDATA,
    output logic [DATA-1:0]  PRDATA,
    output logic             PREADY
);
    logic [DATA-1:0] id_data;
    logic start, mode, match, fallback_hit, fallback_match, done;
    logic [DATA-1:0] fallback_rdata;
    logic [HASH-1:0] index1, index2, index3, index4;
    logic wr_en, rd_en;

    apb_slave apb_dut (
        .PSEL			(PSEL),
		.PWRITE			(PWRITE),
		.PENABLE		(PENABLE),
		.PREADY			(PREADY),
        .wr_en			(wr_en),
		.rd_en			(rd_en)
    );

    hash_engine #(
		.DATA			(DATA),
		.HASH			(HASH),
		.BIT_COUNT		(BIT_COUNT)
	) hash_engine_dut (
        .id_data		(id_data),
		.index1			(index1),
		.index2			(index2),
        .index3			(index3),
		.index4			(index4)
    );

    fallback_lookup #(
        .ADDR			(ADDR),
		.DATA			(DATA),
		.DEPTH			(FALLBACK_DEPTH),
		.BASE_ADDR		(FALLBACK_BASE_ADDR)
    ) fallback_lookup_dut (
        .PCLK			(PCLK),
		.PRESETN		(PRESETN),
		.wr_en			(wr_en),
		.rd_en			(rd_en),
        .PADDR			(PADDR),
		.PWDATA			(PWDATA),
		.id_data		(id_data),
        .hit			(fallback_hit),
		.read_data		(fallback_rdata)
    );

    register #(
		.ADDR			(ADDR),
		.DATA			(DATA)
	) reg_dut (
        .PCLK			(PCLK),
		.PRESETN		(PRESETN),
		.wr_en			(wr_en),
		.rd_en			(rd_en),
        .PADDR			(PADDR),
		.PWDATA			(PWDATA),
		.PRDATA			(PRDATA),
		.id_data		(id_data),
        .start			(start),
		.mode			(mode),
		.match			(match),
		.fallback_match	(fallback_match),
        .done			(done),
		.fallback_rdata	(fallback_rdata)
    );

    sram #(
		.DATA			(DATA),
		.HASH			(HASH),
		.BIT_COUNT		(BIT_COUNT)
	) sram_dut (
        .PCLK			(PCLK),
		.PRESETN		(PRESETN),
		.start			(start),
		.mode			(mode),
        .id_data		(id_data),
		.index1			(index1),
		.index2			(index2),
        .index3			(index3),
		.index4			(index4),
		.fallback_hit	(fallback_hit),
        .match			(match),
		.fallback_match	(fallback_match),
		.done			(done)
    );
	
endmodule
