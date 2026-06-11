`timescale 1ns/1ps
module wallace_5to2_18b (
    input  logic [17:0] i_pp0,
    input  logic [17:0] i_pp1,
    input  logic [17:0] i_pp2,
    input  logic [17:0] i_pp3,
    input  logic [17:0] i_pp4,

    output logic [17:0] o_sum_row,
    output logic [17:0] o_carry_row
);

    logic [17:0] sum_stage1;
    logic [17:0] carry_stage1;
    logic [17:0] carry_stage1_shifted;
	 logic [17:0] carry_row_unshifted;

    logic [17:0] sum_stage2;
    logic [17:0] carry_stage2;
    logic [17:0] carry_stage2_shifted;

    genvar k;

    // stage 1: pp0, pp1, pp2 -> sum_stage1, carry_stage1
    generate
        for (k = 0; k < 18; k = k + 1) begin : gen_stage1
            full_adder_1b u_fa_stage1 (
                .i_a   (i_pp0[k]),
                .i_b   (i_pp1[k]),
                .i_cin (i_pp2[k]),
                .o_sum (sum_stage1[k]),
                .o_cout(carry_stage1[k])
            );
        end
    endgenerate

    assign carry_stage1_shifted = {carry_stage1[16:0], 1'b0};

    // stage 2: pp3, pp4, carry_stage1_shifted -> sum_stage2, carry_stage2
    generate
        for (k = 0; k < 18; k = k + 1) begin : gen_stage2
            full_adder_1b u_fa_stage2 (
                .i_a   (i_pp3[k]),
                .i_b   (i_pp4[k]),
                .i_cin (carry_stage1_shifted[k]),
                .o_sum (sum_stage2[k]),
                .o_cout(carry_stage2[k])
            );
        end
    endgenerate

    assign carry_stage2_shifted = {carry_stage2[16:0], 1'b0};

    // stage 3: sum_stage1, sum_stage2, carry_stage2_shifted -> final 2 rows
    generate
        for (k = 0; k < 18; k = k + 1) begin : gen_stage3
            full_adder_1b u_fa_stage3 (
                .i_a   (sum_stage1[k]),
                .i_b   (sum_stage2[k]),
                .i_cin (carry_stage2_shifted[k]),
                .o_sum (o_sum_row[k]),
                .o_cout(carry_row_unshifted[k])
            );
        end
    endgenerate
	 
	 assign o_carry_row = {carry_row_unshifted[16:0], 1'b0};

endmodule

module wallace_tree (
    input  logic               i_clk,
    input  logic               i_rst_n,
    input  logic               i_en,

    input  logic [17:0] i_pp0,
    input  logic [17:0] i_pp1,
    input  logic [17:0] i_pp2,
    input  logic [17:0] i_pp3,
    input  logic [17:0] i_pp4,

    output logic signed [17:0] o_product,
    output logic               o_overflow
);

    logic [17:0] sum_row;
    logic [17:0] carry_row;

    logic signed [17:0] product_comb;
    logic               overflow_comb;

    wallace_5to2_18b u_wallace_5to2_18b (
        .i_pp0      (i_pp0),
        .i_pp1      (i_pp1),
        .i_pp2      (i_pp2),
        .i_pp3      (i_pp3),
        .i_pp4      (i_pp4),
        .o_sum_row  (sum_row),
        .o_carry_row(carry_row)
    );

    adder_signed_18b u_adder_signed_18b (
        .i_a        (sum_row),
        .i_b        (carry_row),
        .i_cin      (1'b0),
        .o_sum      (product_comb),
        .o_overflow (overflow_comb)
    );

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_product  <= 18'sd0;
            o_overflow <= 1'b0;
        end
        else if (i_en) begin
            o_product  <= product_comb;
            o_overflow <= overflow_comb;
        end
    end

endmodule
