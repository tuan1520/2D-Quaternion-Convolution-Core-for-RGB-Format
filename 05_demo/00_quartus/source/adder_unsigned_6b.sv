`timescale 1ns/1ps
module adder_unsigned_6b (
    input  logic [5:0] i_a,
    input  logic [5:0] i_b,
    output logic [6:0] o_sum
);

    logic p_blk_0;
    logic p_blk_1;
    logic g_blk_0;
    logic g_blk_1;

    logic c3;
    logic c6;

    cla_3b u_cla_0 (
        .i_a      (i_a[2:0]),
        .i_b      (i_b[2:0]),
        .i_cin    (1'b0),
        .o_sum    (o_sum[2:0]),
        .o_cout   (),
        .o_p_group(p_blk_0),
        .o_g_group(g_blk_0)
    );

    assign c3 = g_blk_0;

    cla_3b u_cla_1 (
        .i_a      (i_a[5:3]),
        .i_b      (i_b[5:3]),
        .i_cin    (c3),
        .o_sum    (o_sum[5:3]),
        .o_cout   (),
        .o_p_group(p_blk_1),
        .o_g_group(g_blk_1)
    );

    assign c6 = g_blk_1 | (p_blk_1 & g_blk_0);

    assign o_sum[6] = c6;

endmodule
