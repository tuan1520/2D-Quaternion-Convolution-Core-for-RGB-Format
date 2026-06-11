`timescale 1ns/1ps
module cla_3b (
    input  logic [2:0] i_a,
    input  logic [2:0] i_b,
    input  logic       i_cin,
    output logic [2:0] o_sum,
    output logic       o_cout,
    output logic       o_p_group,
    output logic       o_g_group
);

    logic [2:0] p;
    logic [2:0] g;

    logic c1;
    logic c2;
    logic c3;

    assign p = i_a ^ i_b;
    assign g = i_a & i_b;

    assign c1 = g[0] | (p[0] & i_cin);

    assign c2 = g[1]
              | (p[1] & g[0])
              | (p[1] & p[0] & i_cin);

    assign c3 = g[2]
              | (p[2] & g[1])
              | (p[2] & p[1] & g[0])
              | (p[2] & p[1] & p[0] & i_cin);

    assign o_sum[0] = p[0] ^ i_cin;
    assign o_sum[1] = p[1] ^ c1;
    assign o_sum[2] = p[2] ^ c2;

    assign o_cout = c3;

    assign o_p_group = p[2] & p[1] & p[0];

    assign o_g_group = g[2]
                     | (p[2] & g[1])
                     | (p[2] & p[1] & g[0]);

endmodule