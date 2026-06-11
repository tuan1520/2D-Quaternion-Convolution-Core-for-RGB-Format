`timescale 1ns/1ps
module adder3_signed_24b (
    input  logic signed [23:0] i_a,
    input  logic signed [23:0] i_b,
    input  logic signed [23:0] i_c,
    output logic signed [23:0] o_sum
);

    logic signed [23:0] sum_ab;
    logic               overflow_ab_unused; // use only for instance
    logic               overflow_abc_unused; // use only for instance

    adder_signed_24b u_add_ab (
        .i_a        (i_a),
        .i_b        (i_b),
        .i_cin      (1'b0),
        .o_sum      (sum_ab),
        .o_overflow (overflow_ab_unused)
    );

    adder_signed_24b u_add_abc (
        .i_a        (sum_ab),
        .i_b        (i_c),
        .i_cin      (1'b0),
        .o_sum      (o_sum),
        .o_overflow (overflow_abc_unused)
    );

endmodule
