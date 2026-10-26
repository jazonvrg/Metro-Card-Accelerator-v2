`timescale 1ns/1ps

module hash_engine #(
    parameter int DATA      = 32,
    parameter int HASH      = 24,
    parameter int BIT_COUNT = 9_600_000
) (
    input  logic [DATA-1:0] id_data,
    output logic [HASH-1:0] index1,
    output logic [HASH-1:0] index2,
    output logic [HASH-1:0] index3,
    output logic [HASH-1:0] index4
);

    logic [31:0] mix;
    logic [31:0] hash1, hash2, hash3, hash4;

    always_comb begin
        mix = id_data ^ (id_data >> 16);
        hash1 = (mix + (mix << 3) + (mix >> 5) + 32'h1234_5678) % BIT_COUNT;
        hash2 = (mix ^ (mix << 7) ^ ((mix >> 2) + 32'h8765_4321)) % BIT_COUNT;
        hash3 = ((mix + (mix << 4)) ^ ((mix >> 9) + 32'h9E37_79B9)) % BIT_COUNT;
        hash4 = (mix ^ ((mix << 5) + (mix >> 3) + 32'hDEAD_BEEF)) % BIT_COUNT;
    end

    assign index1 = hash1[HASH-1:0];
    assign index2 = hash2[HASH-1:0];
    assign index3 = hash3[HASH-1:0];
    assign index4 = hash4[HASH-1:0];

endmodule
