`timescale 1ns/1ps
module multiplier_booth_wallace_1core (
    input  logic               i_clk,
    input  logic               i_rst_n,
    input  logic               i_en,

    input  logic signed [8:0]  i_x,
    input  logic        [8:0]  i_y,

    output logic signed [17:0] o_product,
    output logic               o_overflow
);

    logic signed [17:0] pp0;
    logic signed [17:0] pp1;
    logic signed [17:0] pp2;
    logic signed [17:0] pp3;
    logic signed [17:0] pp4;

    booth_shifted_product u_booth_shifted_product (
        .i_clk  (i_clk),
        .i_rst_n(i_rst_n),
        .i_en   (i_en),
        .i_x    (i_x),
        .i_y    (i_y),
        .o_pp0  (pp0),
        .o_pp1  (pp1),
        .o_pp2  (pp2),
        .o_pp3  (pp3),
        .o_pp4  (pp4)
    );

    wallace_tree u_wallace_tree (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_en      (i_en),
        .i_pp0     (pp0),
        .i_pp1     (pp1),
        .i_pp2     (pp2),
        .i_pp3     (pp3),
        .i_pp4     (pp4),
        .o_product (o_product),
        .o_overflow(o_overflow)
    );

endmodule


module multiplier_booth_wallace_9core (
    input  logic               i_clk,
    input  logic               i_rst_n,
    input  logic               i_en,

    input  logic signed [8:0]  i_r,
    input  logic signed [8:0]  i_g,
    input  logic signed [8:0]  i_b,

    input  logic        [8:0]  i_p,
    input  logic        [8:0]  i_q,
    input  logic        [8:0]  i_s,

    output logic signed [17:0] o_rp,
    output logic signed [17:0] o_rq,
    output logic signed [17:0] o_rs,
    output logic signed [17:0] o_gp,
    output logic signed [17:0] o_gq,
    output logic signed [17:0] o_gs,
    output logic signed [17:0] o_bp,
    output logic signed [17:0] o_bq,
    output logic signed [17:0] o_bs
);

    logic ov_rp, ov_rq, ov_rs;
    logic ov_gp, ov_gq, ov_gs;
    logic ov_bp, ov_bq, ov_bs;

    // RP
    multiplier_booth_wallace_1core u_core_rp (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_en      (i_en),
        .i_x       (i_r),
        .i_y       (i_p),
        .o_product (o_rp),
        .o_overflow(ov_rp)
    );

    // RQ
    multiplier_booth_wallace_1core u_core_rq (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_en      (i_en),
        .i_x       (i_r),
        .i_y       (i_q),
        .o_product (o_rq),
        .o_overflow(ov_rq)
    );

    // RS
    multiplier_booth_wallace_1core u_core_rs (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_en      (i_en),
        .i_x       (i_r),
        .i_y       (i_s),
        .o_product (o_rs),
        .o_overflow(ov_rs)
    );

    // GP
    multiplier_booth_wallace_1core u_core_gp (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_en      (i_en),
        .i_x       (i_g),
        .i_y       (i_p),
        .o_product (o_gp),
        .o_overflow(ov_gp)
    );

    // GQ
    multiplier_booth_wallace_1core u_core_gq (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_en      (i_en),
        .i_x       (i_g),
        .i_y       (i_q),
        .o_product (o_gq),
        .o_overflow(ov_gq)
    );

    // GS
    multiplier_booth_wallace_1core u_core_gs (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_en      (i_en),
        .i_x       (i_g),
        .i_y       (i_s),
        .o_product (o_gs),
        .o_overflow(ov_gs)
    );

    // BP
    multiplier_booth_wallace_1core u_core_bp (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_en      (i_en),
        .i_x       (i_b),
        .i_y       (i_p),
        .o_product (o_bp),
        .o_overflow(ov_bp)
    );

    // BQ
    multiplier_booth_wallace_1core u_core_bq (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_en      (i_en),
        .i_x       (i_b),
        .i_y       (i_q),
        .o_product (o_bq),
        .o_overflow(ov_bq)
    );

    // BS
    multiplier_booth_wallace_1core u_core_bs (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_en      (i_en),
        .i_x       (i_b),
        .i_y       (i_s),
        .o_product (o_bs),
        .o_overflow(ov_bs)
    );

endmodule
