`timescale 1ns/1ps
module subtractor_signed_24b (
    input  logic signed [23:0] i_a,
    input  logic signed [23:0] i_b,
    output logic signed [23:0] o_diff
);

    logic signed [23:0] b_inv;
    logic               overflow_unused; // use only for instance

    assign b_inv = ~i_b;

    adder_signed_24b u_sub (
        .i_a        (i_a),
        .i_b        (b_inv),
        .i_cin      (1'b1),
        .o_sum      (o_diff),
        .o_overflow (overflow_unused)
    );

endmodule
