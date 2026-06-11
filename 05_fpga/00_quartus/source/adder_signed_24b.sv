`timescale 1ns/1ps
module adder_signed_24b (
    input  logic signed [23:0] i_a,
    input  logic signed [23:0] i_b,
    input  logic               i_cin,
    output logic signed [23:0] o_sum,
    output logic               o_overflow
);

    logic [5:0] p_blk;
    logic [5:0] g_blk;

    logic c4;
    logic c8;
    logic c12;
    logic c16;
    logic c20;
    logic c24;

    logic [23:0] sum_int;

    cla_4b u_cla_0 (
        .i_a      (i_a[3:0]),
        .i_b      (i_b[3:0]),
        .i_cin    (i_cin),
        .o_sum    (sum_int[3:0]),
        .o_cout   (),
        .o_p_group(p_blk[0]),
        .o_g_group(g_blk[0])
    );

    assign c4 = g_blk[0]
              | (p_blk[0] & i_cin);

    cla_4b u_cla_1 (
        .i_a      (i_a[7:4]),
        .i_b      (i_b[7:4]),
        .i_cin    (c4),
        .o_sum    (sum_int[7:4]),
        .o_cout   (),
        .o_p_group(p_blk[1]),
        .o_g_group(g_blk[1])
    );

    assign c8 = g_blk[1]
              | (p_blk[1] & g_blk[0])
              | (p_blk[1] & p_blk[0] & i_cin);

    cla_4b u_cla_2 (
        .i_a      (i_a[11:8]),
        .i_b      (i_b[11:8]),
        .i_cin    (c8),
        .o_sum    (sum_int[11:8]),
        .o_cout   (),
        .o_p_group(p_blk[2]),
        .o_g_group(g_blk[2])
    );

    assign c12 = g_blk[2]
               | (p_blk[2] & g_blk[1])
               | (p_blk[2] & p_blk[1] & g_blk[0])
               | (p_blk[2] & p_blk[1] & p_blk[0] & i_cin);

    cla_4b u_cla_3 (
        .i_a      (i_a[15:12]),
        .i_b      (i_b[15:12]),
        .i_cin    (c12),
        .o_sum    (sum_int[15:12]),
        .o_cout   (),
        .o_p_group(p_blk[3]),
        .o_g_group(g_blk[3])
    );

    assign c16 = g_blk[3]
               | (p_blk[3] & g_blk[2])
               | (p_blk[3] & p_blk[2] & g_blk[1])
               | (p_blk[3] & p_blk[2] & p_blk[1] & g_blk[0])
               | (p_blk[3] & p_blk[2] & p_blk[1] & p_blk[0] & i_cin);

    cla_4b u_cla_4 (
        .i_a      (i_a[19:16]),
        .i_b      (i_b[19:16]),
        .i_cin    (c16),
        .o_sum    (sum_int[19:16]),
        .o_cout   (),
        .o_p_group(p_blk[4]),
        .o_g_group(g_blk[4])
    );

    assign c20 = g_blk[4]
               | (p_blk[4] & g_blk[3])
               | (p_blk[4] & p_blk[3] & g_blk[2])
               | (p_blk[4] & p_blk[3] & p_blk[2] & g_blk[1])
               | (p_blk[4] & p_blk[3] & p_blk[2] & p_blk[1] & g_blk[0])
               | (p_blk[4] & p_blk[3] & p_blk[2] & p_blk[1] & p_blk[0] & i_cin);

    cla_4b u_cla_5 (
        .i_a      (i_a[23:20]),
        .i_b      (i_b[23:20]),
        .i_cin    (c20),
        .o_sum    (sum_int[23:20]),
        .o_cout   (),
        .o_p_group(p_blk[5]),
        .o_g_group(g_blk[5])
    );

    assign c24 = g_blk[5]
               | (p_blk[5] & g_blk[4])
               | (p_blk[5] & p_blk[4] & g_blk[3])
               | (p_blk[5] & p_blk[4] & p_blk[3] & g_blk[2])
               | (p_blk[5] & p_blk[4] & p_blk[3] & p_blk[2] & g_blk[1])
               | (p_blk[5] & p_blk[4] & p_blk[3] & p_blk[2] & p_blk[1] & g_blk[0])
               | (p_blk[5] & p_blk[4] & p_blk[3] & p_blk[2] & p_blk[1] & p_blk[0] & i_cin);

    assign o_sum = sum_int;

    // signed overflow flag for adder reuse in accumulation path
    assign o_overflow = (~(i_a[23] ^ i_b[23])) & (o_sum[23] ^ i_a[23]);

endmodule
