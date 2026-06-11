`timescale 1ns/1ps
module window_24b (
    input  logic        i_clk,
    input  logic        i_rst_n,
    input  logic        i_win_en,
    input  logic        i_win_valid,
    input  logic [23:0] i_pixel_in,
    output logic [23:0] o_pixel_out
);

    logic [23:0] window_reg;

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            window_reg <= 24'd0;
        else if (i_win_en)
            window_reg <= i_pixel_in;
    end

    assign o_pixel_out = (i_win_valid) ? window_reg : 24'd0;

endmodule


module window_row (
    input  logic        i_clk,
    input  logic        i_rst_n,
    input  logic        i_win_en,
    input  logic        i_win_valid,
    input  logic [23:0] i_row_pixel_in,

    output logic [23:0] o_window_col_0,
    output logic [23:0] o_window_col_1,
    output logic [23:0] o_window_col_2
);

    logic [23:0] stage_0_out;
    logic [23:0] stage_1_out;
    logic [23:0] stage_2_out;

    window_24b window_0 (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_win_en   (i_win_en),
        .i_win_valid(i_win_valid),
        .i_pixel_in (i_row_pixel_in),
        .o_pixel_out(stage_0_out)
    );

    window_24b window_1 (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_win_en   (i_win_en),
        .i_win_valid(i_win_valid),
        .i_pixel_in (stage_0_out),
        .o_pixel_out(stage_1_out)
    );

    window_24b window_2 (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_win_en   (i_win_en),
        .i_win_valid(i_win_valid),
        .i_pixel_in (stage_1_out),
        .o_pixel_out(stage_2_out)
    );

    // map theo thu tu trai -> phai:
    // col_0 = pixel cu nhat, col_2 = pixel moi nhat
    assign o_window_col_0 = stage_2_out;
    assign o_window_col_1 = stage_1_out;
    assign o_window_col_2 = stage_0_out;

endmodule


module window_generator_3x3 (
    input  logic        i_clk,
    input  logic        i_rst_n,
    input  logic        i_win_en,
    input  logic        i_win_valid,

    input  logic [23:0] i_window_line_0,
    input  logic [23:0] i_window_line_1,
    input  logic [23:0] i_window_line_2,

    output logic [23:0] o_window_00,
    output logic [23:0] o_window_01,
    output logic [23:0] o_window_02,

    output logic [23:0] o_window_10,
    output logic [23:0] o_window_11,
    output logic [23:0] o_window_12,

    output logic [23:0] o_window_20,
    output logic [23:0] o_window_21,
    output logic [23:0] o_window_22
);

    // row 0: line buffer 2 / oldest line
    window_row window_row_0 (
        .i_clk         (i_clk),
        .i_rst_n       (i_rst_n),
        .i_win_en      (i_win_en),
        .i_win_valid   (i_win_valid),
        .i_row_pixel_in(i_window_line_0),
        .o_window_col_0(o_window_00),
        .o_window_col_1(o_window_01),
        .o_window_col_2(o_window_02)
    );

    // row 1: line buffer 1 / middle line
    window_row window_row_1 (
        .i_clk         (i_clk),
        .i_rst_n       (i_rst_n),
        .i_win_en      (i_win_en),
        .i_win_valid   (i_win_valid),
        .i_row_pixel_in(i_window_line_1),
        .o_window_col_0(o_window_10),
        .o_window_col_1(o_window_11),
        .o_window_col_2(o_window_12)
    );

    // row 2: current line
    window_row window_row_2 (
        .i_clk         (i_clk),
        .i_rst_n       (i_rst_n),
        .i_win_en      (i_win_en),
        .i_win_valid   (i_win_valid),
        .i_row_pixel_in(i_window_line_2),
        .o_window_col_0(o_window_20),
        .o_window_col_1(o_window_21),
        .o_window_col_2(o_window_22)
    );

endmodule
