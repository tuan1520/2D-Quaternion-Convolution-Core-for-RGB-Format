`timescale 1ns/1ps
module accumulator_9tap_4lane (
    input  logic               i_clk,
    input  logic               i_rst_n,
    input  logic               i_pipe_shift_en,

    // lane s: y00..y08
    input  logic signed [17:0] i_y00,
    input  logic signed [17:0] i_y01,
    input  logic signed [17:0] i_y02,
    input  logic signed [17:0] i_y03,
    input  logic signed [17:0] i_y04,
    input  logic signed [17:0] i_y05,
    input  logic signed [17:0] i_y06,
    input  logic signed [17:0] i_y07,
    input  logic signed [17:0] i_y08,

    // lane i: y10..y18
    input  logic signed [17:0] i_y10,
    input  logic signed [17:0] i_y11,
    input  logic signed [17:0] i_y12,
    input  logic signed [17:0] i_y13,
    input  logic signed [17:0] i_y14,
    input  logic signed [17:0] i_y15,
    input  logic signed [17:0] i_y16,
    input  logic signed [17:0] i_y17,
    input  logic signed [17:0] i_y18,

    // lane j: y20..y28
    input  logic signed [17:0] i_y20,
    input  logic signed [17:0] i_y21,
    input  logic signed [17:0] i_y22,
    input  logic signed [17:0] i_y23,
    input  logic signed [17:0] i_y24,
    input  logic signed [17:0] i_y25,
    input  logic signed [17:0] i_y26,
    input  logic signed [17:0] i_y27,
    input  logic signed [17:0] i_y28,

    // lane k: y30..y38
    input  logic signed [17:0] i_y30,
    input  logic signed [17:0] i_y31,
    input  logic signed [17:0] i_y32,
    input  logic signed [17:0] i_y33,
    input  logic signed [17:0] i_y34,
    input  logic signed [17:0] i_y35,
    input  logic signed [17:0] i_y36,
    input  logic signed [17:0] i_y37,
    input  logic signed [17:0] i_y38,

    output logic signed [23:0] o_out_s,
    output logic signed [23:0] o_out_i,
    output logic signed [23:0] o_out_j,
    output logic signed [23:0] o_out_k
);

    // =========================================================
    // sign-extend input 18b -> 24b
    // lane 0 = s, lane 1 = i, lane 2 = j, lane 3 = k
    // =========================================================
    logic signed [23:0] lane_in [0:3][0:8];

    assign lane_in[0][0] = {{6{i_y00[17]}}, i_y00};
    assign lane_in[0][1] = {{6{i_y01[17]}}, i_y01};
    assign lane_in[0][2] = {{6{i_y02[17]}}, i_y02};
    assign lane_in[0][3] = {{6{i_y03[17]}}, i_y03};
    assign lane_in[0][4] = {{6{i_y04[17]}}, i_y04};
    assign lane_in[0][5] = {{6{i_y05[17]}}, i_y05};
    assign lane_in[0][6] = {{6{i_y06[17]}}, i_y06};
    assign lane_in[0][7] = {{6{i_y07[17]}}, i_y07};
    assign lane_in[0][8] = {{6{i_y08[17]}}, i_y08};

    assign lane_in[1][0] = {{6{i_y10[17]}}, i_y10};
    assign lane_in[1][1] = {{6{i_y11[17]}}, i_y11};
    assign lane_in[1][2] = {{6{i_y12[17]}}, i_y12};
    assign lane_in[1][3] = {{6{i_y13[17]}}, i_y13};
    assign lane_in[1][4] = {{6{i_y14[17]}}, i_y14};
    assign lane_in[1][5] = {{6{i_y15[17]}}, i_y15};
    assign lane_in[1][6] = {{6{i_y16[17]}}, i_y16};
    assign lane_in[1][7] = {{6{i_y17[17]}}, i_y17};
    assign lane_in[1][8] = {{6{i_y18[17]}}, i_y18};

    assign lane_in[2][0] = {{6{i_y20[17]}}, i_y20};
    assign lane_in[2][1] = {{6{i_y21[17]}}, i_y21};
    assign lane_in[2][2] = {{6{i_y22[17]}}, i_y22};
    assign lane_in[2][3] = {{6{i_y23[17]}}, i_y23};
    assign lane_in[2][4] = {{6{i_y24[17]}}, i_y24};
    assign lane_in[2][5] = {{6{i_y25[17]}}, i_y25};
    assign lane_in[2][6] = {{6{i_y26[17]}}, i_y26};
    assign lane_in[2][7] = {{6{i_y27[17]}}, i_y27};
    assign lane_in[2][8] = {{6{i_y28[17]}}, i_y28};

    assign lane_in[3][0] = {{6{i_y30[17]}}, i_y30};
    assign lane_in[3][1] = {{6{i_y31[17]}}, i_y31};
    assign lane_in[3][2] = {{6{i_y32[17]}}, i_y32};
    assign lane_in[3][3] = {{6{i_y33[17]}}, i_y33};
    assign lane_in[3][4] = {{6{i_y34[17]}}, i_y34};
    assign lane_in[3][5] = {{6{i_y35[17]}}, i_y35};
    assign lane_in[3][6] = {{6{i_y36[17]}}, i_y36};
    assign lane_in[3][7] = {{6{i_y37[17]}}, i_y37};
    assign lane_in[3][8] = {{6{i_y38[17]}}, i_y38};

    // =========================================================
    // stage 1: 9 -> 5
    // =========================================================
    logic signed [23:0] s1_comb [0:3][0:4];
    logic signed [23:0] s1_reg  [0:3][0:4];
    logic               ov_s1   [0:3][0:3];

    genvar l1;
    generate
        for (l1 = 0; l1 < 4; l1 = l1 + 1) begin : gen_stage1
            adder_signed_24b u_s1_add_0 (
                .i_a        (lane_in[l1][0]),
                .i_b        (lane_in[l1][1]),
                .i_cin      (1'b0),
                .o_sum      (s1_comb[l1][0]),
                .o_overflow (ov_s1[l1][0])
            );

            adder_signed_24b u_s1_add_1 (
                .i_a        (lane_in[l1][2]),
                .i_b        (lane_in[l1][3]),
                .i_cin      (1'b0),
                .o_sum      (s1_comb[l1][1]),
                .o_overflow (ov_s1[l1][1])
            );

            adder_signed_24b u_s1_add_2 (
                .i_a        (lane_in[l1][4]),
                .i_b        (lane_in[l1][5]),
                .i_cin      (1'b0),
                .o_sum      (s1_comb[l1][2]),
                .o_overflow (ov_s1[l1][2])
            );

            adder_signed_24b u_s1_add_3 (
                .i_a        (lane_in[l1][6]),
                .i_b        (lane_in[l1][7]),
                .i_cin      (1'b0),
                .o_sum      (s1_comb[l1][3]),
                .o_overflow (ov_s1[l1][3])
            );

            assign s1_comb[l1][4] = lane_in[l1][8];
        end
    endgenerate

    integer i1, j1;

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (i1 = 0; i1 < 4; i1 = i1 + 1)
                for (j1 = 0; j1 < 5; j1 = j1 + 1)
                    s1_reg[i1][j1] <= 24'sd0;
        end
        else if (i_pipe_shift_en) begin
            for (i1 = 0; i1 < 4; i1 = i1 + 1)
                for (j1 = 0; j1 < 5; j1 = j1 + 1)
                    s1_reg[i1][j1] <= s1_comb[i1][j1];
        end
    end

    // =========================================================
    // stage 2: 5 -> 3
    // =========================================================
    logic signed [23:0] s2_comb [0:3][0:2];
    logic signed [23:0] s2_reg  [0:3][0:2];
    logic               ov_s2   [0:3][0:1];

    genvar l2;
    generate
        for (l2 = 0; l2 < 4; l2 = l2 + 1) begin : gen_stage2
            adder_signed_24b u_s2_add_0 (
                .i_a        (s1_reg[l2][0]),
                .i_b        (s1_reg[l2][1]),
                .i_cin      (1'b0),
                .o_sum      (s2_comb[l2][0]),
                .o_overflow (ov_s2[l2][0])
            );

            adder_signed_24b u_s2_add_1 (
                .i_a        (s1_reg[l2][2]),
                .i_b        (s1_reg[l2][3]),
                .i_cin      (1'b0),
                .o_sum      (s2_comb[l2][1]),
                .o_overflow (ov_s2[l2][1])
            );

            assign s2_comb[l2][2] = s1_reg[l2][4];
        end
    endgenerate

    integer i2, j2;
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (i2 = 0; i2 < 4; i2 = i2 + 1)
                for (j2 = 0; j2 < 3; j2 = j2 + 1)
                    s2_reg[i2][j2] <= 24'sd0;
        end
        else if (i_pipe_shift_en) begin
            for (i2 = 0; i2 < 4; i2 = i2 + 1)
                for (j2 = 0; j2 < 3; j2 = j2 + 1)
                    s2_reg[i2][j2] <= s2_comb[i2][j2];
        end
    end

    // =========================================================
    // stage 3: 3 -> 2
    // =========================================================
    logic signed [23:0] s3_comb [0:3][0:1];
    logic signed [23:0] s3_reg  [0:3][0:1];
    logic               ov_s3   [0:3];

    genvar l3;
    generate
        for (l3 = 0; l3 < 4; l3 = l3 + 1) begin : gen_stage3
            adder_signed_24b u_s3_add_0 (
                .i_a        (s2_reg[l3][0]),
                .i_b        (s2_reg[l3][1]),
                .i_cin      (1'b0),
                .o_sum      (s3_comb[l3][0]),
                .o_overflow (ov_s3[l3])
            );

            assign s3_comb[l3][1] = s2_reg[l3][2];
        end
    endgenerate

    integer i3, j3;
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (i3 = 0; i3 < 4; i3 = i3 + 1)
                for (j3 = 0; j3 < 2; j3 = j3 + 1)
                    s3_reg[i3][j3] <= 24'sd0;
        end
        else if (i_pipe_shift_en) begin
            for (i3 = 0; i3 < 4; i3 = i3 + 1)
                for (j3 = 0; j3 < 2; j3 = j3 + 1)
                    s3_reg[i3][j3] <= s3_comb[i3][j3];
        end
    end

    // =========================================================
    // stage 4: 2 -> 1
    // =========================================================
    logic signed [23:0] s4_comb [0:3];
    logic signed [23:0] s4_reg  [0:3];
    logic               ov_s4   [0:3];

    genvar l4;
    generate
        for (l4 = 0; l4 < 4; l4 = l4 + 1) begin : gen_stage4
            adder_signed_24b u_s4_add_0 (
                .i_a        (s3_reg[l4][0]),
                .i_b        (s3_reg[l4][1]),
                .i_cin      (1'b0),
                .o_sum      (s4_comb[l4]),
                .o_overflow (ov_s4[l4])
            );
        end
    endgenerate
    
    integer i4;
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (i4 = 0; i4 < 4; i4 = i4 + 1)
                s4_reg[i4] <= 24'sd0;
        end
        else if (i_pipe_shift_en) begin
            for (i4 = 0; i4 < 4; i4 = i4 + 1)
                s4_reg[i4] <= s4_comb[i4];
        end
    end

    assign o_out_s = s4_reg[0];
    assign o_out_i = s4_reg[1];
    assign o_out_j = s4_reg[2];
    assign o_out_k = s4_reg[3];

endmodule
