`timescale 1ns/1ps
module adder_signed_18b (
    input  logic signed [17:0] i_a,
    input  logic signed [17:0] i_b,
    input  logic               i_cin,
    output logic signed [17:0] o_sum,
    output logic               o_overflow
);

    logic [3:0] p_blk;
    logic [3:0] g_blk;

    logic c4;
    logic c8;
    logic c12;
    logic c16;
    logic c18;

    logic [17:0] sum_int;

    logic p16;
    logic g16;
    logic p17;
    logic g17;
    logic c17;

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

    assign p16 = i_a[16] ^ i_b[16];

    assign g16 = i_a[16] & i_b[16];

    assign sum_int[16] = p16 ^ c16;


    assign c17 = g16 | (p16 & c16);

    assign p17 = i_a[17] ^ i_b[17];

    assign g17 = i_a[17] & i_b[17];

    assign sum_int[17] = p17 ^ c17;


    assign c18 = g17 | (p17 & c17);

    assign o_sum = sum_int;

    assign o_overflow = (~(i_a[17] ^ i_b[17])) & (o_sum[17] ^ i_a[17]);

endmodule
