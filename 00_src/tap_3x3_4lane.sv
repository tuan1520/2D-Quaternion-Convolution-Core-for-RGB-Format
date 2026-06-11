`timescale 1ns/1ps
module subtractor_signed_18b (
    input  logic signed [17:0] i_a,
    input  logic signed [17:0] i_b,
    output logic signed [17:0] o_diff
);

    logic signed [17:0] b_inv;
    logic               overflow_unused;

    assign b_inv = ~i_b;

    adder_signed_18b u_sub (
        .i_a        (i_a),
        .i_b        (b_inv),
        .i_cin      (1'b1),
        .o_sum      (o_diff),
        .o_overflow (overflow_unused)
    );

endmodule


module adder3_signed_18b (
    input  logic signed [17:0] i_a,
    input  logic signed [17:0] i_b,
    input  logic signed [17:0] i_c,
    output logic signed [17:0] o_sum
);

    logic signed [17:0] sum_ab;
    logic               overflow_ab_unused;
    logic               overflow_abc_unused;

    adder_signed_18b u_add_ab (
        .i_a        (i_a),
        .i_b        (i_b),
        .i_cin      (1'b0),
        .o_sum      (sum_ab),
        .o_overflow (overflow_ab_unused)
    );

    adder_signed_18b u_add_abc (
        .i_a        (sum_ab),
        .i_b        (i_c),
        .i_cin      (1'b0),
        .o_sum      (o_sum),
        .o_overflow (overflow_abc_unused)
    );

endmodule


module negate_signed_18b (
    input  logic signed [17:0] i_a,
    output logic signed [17:0] o_neg
);

    logic               overflow_unused;

    adder_signed_18b u_neg (
        .i_a        (~i_a),
        .i_b        (18'sd0),
        .i_cin      (1'b1),
        .o_sum      (o_neg),
        .o_overflow (overflow_unused)
    );

endmodule

module tap_input_pipe_3x3 (
    input  logic               i_clk,
    input  logic               i_rst_n,
    input  logic               i_shift_en,
    input  logic               i_load_valid,

    input  logic [23:0]        i_w00,
    input  logic [23:0]        i_w01,
    input  logic [23:0]        i_w02,
    input  logic [23:0]        i_w10,
    input  logic [23:0]        i_w11,
    input  logic [23:0]        i_w12,
    input  logic [23:0]        i_w20,
    input  logic [23:0]        i_w21,
    input  logic [23:0]        i_w22,

    input  logic signed [23:0] i_k00,
    input  logic signed [23:0] i_k01,
    input  logic signed [23:0] i_k02,
    input  logic signed [23:0] i_k10,
    input  logic signed [23:0] i_k11,
    input  logic signed [23:0] i_k12,
    input  logic signed [23:0] i_k20,
    input  logic signed [23:0] i_k21,
    input  logic signed [23:0] i_k22,

    output logic [23:0]        o_w00,
    output logic [23:0]        o_w01,
    output logic [23:0]        o_w02,
    output logic [23:0]        o_w10,
    output logic [23:0]        o_w11,
    output logic [23:0]        o_w12,
    output logic [23:0]        o_w20,
    output logic [23:0]        o_w21,
    output logic [23:0]        o_w22,

    output logic signed [23:0] o_k00,
    output logic signed [23:0] o_k01,
    output logic signed [23:0] o_k02,
    output logic signed [23:0] o_k10,
    output logic signed [23:0] o_k11,
    output logic signed [23:0] o_k12,
    output logic signed [23:0] o_k20,
    output logic signed [23:0] o_k21,
    output logic signed [23:0] o_k22
);

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_w00 <= 24'd0; o_w01 <= 24'd0; o_w02 <= 24'd0;
            o_w10 <= 24'd0; o_w11 <= 24'd0; o_w12 <= 24'd0;
            o_w20 <= 24'd0; o_w21 <= 24'd0; o_w22 <= 24'd0;

            o_k00 <= 24'sd0; o_k01 <= 24'sd0; o_k02 <= 24'sd0;
            o_k10 <= 24'sd0; o_k11 <= 24'sd0; o_k12 <= 24'sd0;
            o_k20 <= 24'sd0; o_k21 <= 24'sd0; o_k22 <= 24'sd0;
        end
        else if (i_shift_en) begin
            if (i_load_valid) begin
                o_w00 <= i_w00; o_w01 <= i_w01; o_w02 <= i_w02;
                o_w10 <= i_w10; o_w11 <= i_w11; o_w12 <= i_w12;
                o_w20 <= i_w20; o_w21 <= i_w21; o_w22 <= i_w22;

                o_k00 <= i_k00; o_k01 <= i_k01; o_k02 <= i_k02;
                o_k10 <= i_k10; o_k11 <= i_k11; o_k12 <= i_k12;
                o_k20 <= i_k20; o_k21 <= i_k21; o_k22 <= i_k22;
            end
            else begin
                o_w00 <= 24'd0; o_w01 <= 24'd0; o_w02 <= 24'd0;
                o_w10 <= 24'd0; o_w11 <= 24'd0; o_w12 <= 24'd0;
                o_w20 <= 24'd0; o_w21 <= 24'd0; o_w22 <= 24'd0;

                o_k00 <= 24'sd0; o_k01 <= 24'sd0; o_k02 <= 24'sd0;
                o_k10 <= 24'sd0; o_k11 <= 24'sd0; o_k12 <= 24'sd0;
                o_k20 <= 24'sd0; o_k21 <= 24'sd0; o_k22 <= 24'sd0;
            end
        end
    end

endmodule

module tap_4lane (
    input  logic               i_clk,
    input  logic               i_rst_n,
    input  logic               i_en,

    input  logic        [23:0] i_pixel_data,
    input  logic signed [23:0] i_kernel_data,

    output logic signed [17:0] o_y0,
    output logic signed [17:0] o_y1,
    output logic signed [17:0] o_y2,
    output logic signed [17:0] o_y3
);

    logic signed [8:0]  r_ext;
    logic signed [8:0]  g_ext;
    logic signed [8:0]  b_ext;

    logic signed [7:0]  kernel_p_8b;
    logic signed [7:0]  kernel_q_8b;
    logic signed [7:0]  kernel_s_8b;

    logic signed [8:0]  p_ext;
    logic signed [8:0]  q_ext;
    logic signed [8:0]  s_ext;

    logic signed [17:0] rp;
    logic signed [17:0] rq;
    logic signed [17:0] rs;
    logic signed [17:0] gp;
    logic signed [17:0] gq;
    logic signed [17:0] gs;
    logic signed [17:0] bp;
    logic signed [17:0] bq;
    logic signed [17:0] bs;

    logic signed [17:0] y0_sum;
    logic signed [17:0] y0_comb;
    logic signed [17:0] y1_comb;
    logic signed [17:0] y2_comb;
    logic signed [17:0] y3_comb;

    assign r_ext = {1'b0, i_pixel_data[23:16]};
    assign g_ext = {1'b0, i_pixel_data[15:8]};
    assign b_ext = {1'b0, i_pixel_data[7:0]};

    assign kernel_p_8b = i_kernel_data[23:16];
    assign kernel_q_8b = i_kernel_data[15:8];
    assign kernel_s_8b = i_kernel_data[7:0];

    assign p_ext = {kernel_p_8b[7], kernel_p_8b};
    assign q_ext = {kernel_q_8b[7], kernel_q_8b};
    assign s_ext = {kernel_s_8b[7], kernel_s_8b};

    multiplier_booth_wallace_9core u_multiplier_booth_wallace_9core (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (i_en),

        .i_r   (r_ext),
        .i_g   (g_ext),
        .i_b   (b_ext),

        .i_p   (p_ext),
        .i_q   (q_ext),
        .i_s   (s_ext),

        .o_rp  (rp),
        .o_rq  (rq),
        .o_rs  (rs),
        .o_gp  (gp),
        .o_gq  (gq),
        .o_gs  (gs),
        .o_bp  (bp),
        .o_bq  (bq),
        .o_bs  (bs)
    );

    // y0 = -(RP + GQ + BS)
    adder3_signed_18b u_add3_y0 (
        .i_a  (rp),
        .i_b  (gq),
        .i_c  (bs),
        .o_sum(y0_sum)
    );

    negate_signed_18b u_neg_y0 (
        .i_a  (y0_sum),
        .o_neg(y0_comb)
    );

    // y1 = GS - BQ
    subtractor_signed_18b u_sub_y1 (
        .i_a   (gs),
        .i_b   (bq),
        .o_diff(y1_comb)
    );

    // y2 = BP - RS
    subtractor_signed_18b u_sub_y2 (
        .i_a   (bp),
        .i_b   (rs),
        .o_diff(y2_comb)
    );

    // y3 = RQ - GP
    subtractor_signed_18b u_sub_y3 (
        .i_a   (rq),
        .i_b   (gp),
        .o_diff(y3_comb)
    );

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_y0 <= 18'sd0;
            o_y1 <= 18'sd0;
            o_y2 <= 18'sd0;
            o_y3 <= 18'sd0;
        end
        else if (i_en) begin
            o_y0 <= y0_comb;
            o_y1 <= y1_comb;
            o_y2 <= y2_comb;
            o_y3 <= y3_comb;
        end
    end

endmodule


module tap_3x3_4lane (
    input  logic               i_clk,
    input  logic               i_rst_n,
    input  logic               i_en,

    input  logic [23:0] i_w00,
    input  logic [23:0] i_w01,
    input  logic [23:0] i_w02,
    input  logic [23:0] i_w10,
    input  logic [23:0] i_w11,
    input  logic [23:0] i_w12,
    input  logic [23:0] i_w20,
    input  logic [23:0] i_w21,
    input  logic [23:0] i_w22,

    input  logic signed [23:0] i_k00,
    input  logic signed [23:0] i_k01,
    input  logic signed [23:0] i_k02,
    input  logic signed [23:0] i_k10,
    input  logic signed [23:0] i_k11,
    input  logic signed [23:0] i_k12,
    input  logic signed [23:0] i_k20,
    input  logic signed [23:0] i_k21,
    input  logic signed [23:0] i_k22,

    output logic signed [17:0] o_y00,
    output logic signed [17:0] o_y01,
    output logic signed [17:0] o_y02,
    output logic signed [17:0] o_y03,

    output logic signed [17:0] o_y10,
    output logic signed [17:0] o_y11,
    output logic signed [17:0] o_y12,
    output logic signed [17:0] o_y13,

    output logic signed [17:0] o_y20,
    output logic signed [17:0] o_y21,
    output logic signed [17:0] o_y22,
    output logic signed [17:0] o_y23,

    output logic signed [17:0] o_y30,
    output logic signed [17:0] o_y31,
    output logic signed [17:0] o_y32,
    output logic signed [17:0] o_y33,

    output logic signed [17:0] o_y40,
    output logic signed [17:0] o_y41,
    output logic signed [17:0] o_y42,
    output logic signed [17:0] o_y43,

    output logic signed [17:0] o_y50,
    output logic signed [17:0] o_y51,
    output logic signed [17:0] o_y52,
    output logic signed [17:0] o_y53,

    output logic signed [17:0] o_y60,
    output logic signed [17:0] o_y61,
    output logic signed [17:0] o_y62,
    output logic signed [17:0] o_y63,

    output logic signed [17:0] o_y70,
    output logic signed [17:0] o_y71,
    output logic signed [17:0] o_y72,
    output logic signed [17:0] o_y73,

    output logic signed [17:0] o_y80,
    output logic signed [17:0] o_y81,
    output logic signed [17:0] o_y82,
    output logic signed [17:0] o_y83
);

    tap_4lane u_tap_0 (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .i_en         (i_en),
        .i_pixel_data (i_w00),
        .i_kernel_data(i_k00),
        .o_y0         (o_y00),
        .o_y1         (o_y01),
        .o_y2         (o_y02),
        .o_y3         (o_y03)
    );

    tap_4lane u_tap_1 (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .i_en         (i_en),
        .i_pixel_data (i_w01),
        .i_kernel_data(i_k01),
        .o_y0         (o_y10),
        .o_y1         (o_y11),
        .o_y2         (o_y12),
        .o_y3         (o_y13)
    );

    tap_4lane u_tap_2 (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .i_en         (i_en),
        .i_pixel_data (i_w02),
        .i_kernel_data(i_k02),
        .o_y0         (o_y20),
        .o_y1         (o_y21),
        .o_y2         (o_y22),
        .o_y3         (o_y23)
    );

    tap_4lane u_tap_3 (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .i_en         (i_en),
        .i_pixel_data (i_w10),
        .i_kernel_data(i_k10),
        .o_y0         (o_y30),
        .o_y1         (o_y31),
        .o_y2         (o_y32),
        .o_y3         (o_y33)
    );

    tap_4lane u_tap_4 (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .i_en         (i_en),
        .i_pixel_data (i_w11),
        .i_kernel_data(i_k11),
        .o_y0         (o_y40),
        .o_y1         (o_y41),
        .o_y2         (o_y42),
        .o_y3         (o_y43)
    );

    tap_4lane u_tap_5 (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .i_en         (i_en),
        .i_pixel_data (i_w12),
        .i_kernel_data(i_k12),
        .o_y0         (o_y50),
        .o_y1         (o_y51),
        .o_y2         (o_y52),
        .o_y3         (o_y53)
    );

    tap_4lane u_tap_6 (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .i_en         (i_en),
        .i_pixel_data (i_w20),
        .i_kernel_data(i_k20),
        .o_y0         (o_y60),
        .o_y1         (o_y61),
        .o_y2         (o_y62),
        .o_y3         (o_y63)
    );

    tap_4lane u_tap_7 (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .i_en         (i_en),
        .i_pixel_data (i_w21),
        .i_kernel_data(i_k21),
        .o_y0         (o_y70),
        .o_y1         (o_y71),
        .o_y2         (o_y72),
        .o_y3         (o_y73)
    );

    tap_4lane u_tap_8 (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .i_en         (i_en),
        .i_pixel_data (i_w22),
        .i_kernel_data(i_k22),
        .o_y0         (o_y80),
        .o_y1         (o_y81),
        .o_y2         (o_y82),
        .o_y3         (o_y83)
    );
endmodule
