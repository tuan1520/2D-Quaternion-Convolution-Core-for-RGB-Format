`timescale 1ns/1ps
module pure_quat_conv2d_3x3_core #(
    parameter int IMG_W = 64,
    parameter int IMG_H = 64,
    parameter int LINE_LENGTH = 64,
    parameter int TOTAL_PIPE_LAT = 7
)(
    input  logic                           i_clk,
    input  logic                           i_rst_n,

    input  logic                           i_start,
    input  logic                           i_next_frame,

    // pixel stream from testbench
    input  logic                           i_tb_pixel_valid,
    input  logic [23:0]                    i_tb_pixel,
    output logic                           o_tb_pixel_ready,

    // kernel config from testbench
    input  logic                           i_ker_cfg_valid,
    input  logic [3:0]                     i_ker_cfg_idx,
    input  logic [23:0]                    i_ker_input,
    output logic                           o_ker_done,
    output logic                           o_frame_done,

    // final output
    output logic signed [23:0]             o_out_s,
    output logic signed [23:0]             o_out_i,
    output logic signed [23:0]             o_out_j,
    output logic signed [23:0]             o_out_k,

    output logic                           o_out_valid,
    output logic                           o_out_latch,
    output logic                           o_out_empty
);

    localparam int X_W = $clog2(IMG_W);
    localparam int Y_W = $clog2(IMG_H);

    // ---------------------------------------------------------
    // controller signals
    // ---------------------------------------------------------
    logic ctrl_busy;
    logic ctrl_frame_done;
    logic ctrl_ker_load_en;
    logic ctrl_lb_en;
    logic ctrl_win_en;
    logic ctrl_win_valid;
    logic ctrl_pipe_shift_en;
    logic ctrl_tap_load_valid;

    // ---------------------------------------------------------
    // rgb stream
    // ---------------------------------------------------------
    logic                    stream_pixel_valid;
    logic [23:0]             stream_pixel_data;
    logic                    stream_start_frame;
    logic                    stream_end_line;
    logic                    stream_end_frame;
    logic [X_W-1:0]          stream_x;
    logic [Y_W-1:0]          stream_y;

    // ---------------------------------------------------------
    // line buffer
    // ---------------------------------------------------------
    logic [23:0]             line_0;
    logic [23:0]             line_1;
    logic [23:0]             line_2;

    // ---------------------------------------------------------
    // window generator
    // ---------------------------------------------------------
    logic [23:0]             w00, w01, w02;
    logic [23:0]             w10, w11, w12;
    logic [23:0]             w20, w21, w22;

    // ---------------------------------------------------------
    // kernel bank
    // ---------------------------------------------------------
    logic [23:0]             k00, k01, k02;
    logic [23:0]             k10, k11, k12;
    logic [23:0]             k20, k21, k22;

    // ---------------------------------------------------------
    // piped window/kernel to tap block
    // ---------------------------------------------------------
    logic [23:0]             pw00, pw01, pw02;
    logic [23:0]             pw10, pw11, pw12;
    logic [23:0]             pw20, pw21, pw22;

    logic signed [23:0]      pk00, pk01, pk02;
    logic signed [23:0]      pk10, pk11, pk12;
    logic signed [23:0]      pk20, pk21, pk22;

    // ---------------------------------------------------------
    // tap outputs (tap-major)
    // ---------------------------------------------------------
    logic signed [17:0]      ty00, ty01, ty02, ty03;
    logic signed [17:0]      ty10, ty11, ty12, ty13;
    logic signed [17:0]      ty20, ty21, ty22, ty23;
    logic signed [17:0]      ty30, ty31, ty32, ty33;
    logic signed [17:0]      ty40, ty41, ty42, ty43;
    logic signed [17:0]      ty50, ty51, ty52, ty53;
    logic signed [17:0]      ty60, ty61, ty62, ty63;
    logic signed [17:0]      ty70, ty71, ty72, ty73;
    logic signed [17:0]      ty80, ty81, ty82, ty83;

    // ---------------------------------------------------------
    // controller
    // ---------------------------------------------------------
    pure_quat_conv2d_3x3_controller #(
        .IMG_W          (IMG_W),
        .IMG_H          (IMG_H),
        .TOTAL_PIPE_LAT (TOTAL_PIPE_LAT)
    ) u_controller (
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n),
        .i_start        (i_start),
        .i_next_frame   (i_next_frame),
        .i_ker_done     (o_ker_done),
        .i_pixel_valid  (stream_pixel_valid),
        .i_end_frame    (stream_end_frame),
        .i_x            (stream_x),
        .i_y            (stream_y),
        .o_busy         (ctrl_busy),
        .o_frame_done   (ctrl_frame_done),
        .o_ker_load_en  (ctrl_ker_load_en),
        .o_lb_en        (ctrl_lb_en),
        .o_win_en       (ctrl_win_en),
        .o_win_valid    (ctrl_win_valid),
        .o_pipe_shift_en(ctrl_pipe_shift_en),
        .o_tap_load_valid(ctrl_tap_load_valid),
        .o_out_valid    (o_out_valid),
        .o_out_latch    (o_out_latch),
        .o_out_empty    (o_out_empty)
    );


    assign o_frame_done = ctrl_frame_done;

    // ---------------------------------------------------------
    // rgb stream in
    // ---------------------------------------------------------
    rgb_stream_in #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H)
    ) u_rgb_stream_in (
        .i_clk         (i_clk),
        .i_rst_n       (i_rst_n),
        .i_tb_valid    (i_tb_pixel_valid),
        .i_tb_pixel    (i_tb_pixel),
        .o_tb_ready    (o_tb_pixel_ready),
        .i_busy        (ctrl_busy),
        .i_frame_done  (ctrl_frame_done),
        .o_pixel_valid (stream_pixel_valid),
        .o_pixel_data  (stream_pixel_data),
        .o_start_frame (stream_start_frame),
        .o_end_line    (stream_end_line),
        .o_end_frame   (stream_end_frame),
        .o_x           (stream_x),
        .o_y           (stream_y)
    );

    // ---------------------------------------------------------
    // line buffer
    // ---------------------------------------------------------
    two_line_buffer #(
        .LINE_LENGTH(LINE_LENGTH)
    ) u_two_line_buffer (
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n),
        .i_lb_en        (ctrl_lb_en),
        .i_pixel_data   (stream_pixel_data),
        .o_window_line_0(line_0),
        .o_window_line_1(line_1),
        .o_window_line_2(line_2)
    );

    // ---------------------------------------------------------
    // window generator
    // ---------------------------------------------------------
    window_generator_3x3 u_window_generator_3x3 (
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n),
        .i_win_en       (ctrl_win_en),
        .i_win_valid    (ctrl_win_valid),
        .i_window_line_0(line_0),
        .i_window_line_1(line_1),
        .i_window_line_2(line_2),
        .o_window_00    (w00),
        .o_window_01    (w01),
        .o_window_02    (w02),
        .o_window_10    (w10),
        .o_window_11    (w11),
        .o_window_12    (w12),
        .o_window_20    (w20),
        .o_window_21    (w21),
        .o_window_22    (w22)
    );

    // ---------------------------------------------------------
    // kernel bank
    // ---------------------------------------------------------
    kernel u_kernel (
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n),
        .i_ker_cfg_valid(i_ker_cfg_valid & ctrl_ker_load_en),
        .i_ker_cfg_idx  (i_ker_cfg_idx),
        .i_ker_input    (i_ker_input),
        .o_ker_done     (o_ker_done),
        .o_k00          (k00),
        .o_k01          (k01),
        .o_k02          (k02),
        .o_k10          (k10),
        .o_k11          (k11),
        .o_k12          (k12),
        .o_k20          (k20),
        .o_k21          (k21),
        .o_k22          (k22)
    );

    // ---------------------------------------------------------
    // input pipeline before tap block
    // ---------------------------------------------------------
    tap_input_pipe_3x3 u_tap_input_pipe_3x3 (
        .i_clk       (i_clk),
        .i_rst_n     (i_rst_n),
        .i_shift_en  (ctrl_pipe_shift_en),
        .i_load_valid(ctrl_tap_load_valid),

        .i_w00(w00), .i_w01(w01), .i_w02(w02),
        .i_w10(w10), .i_w11(w11), .i_w12(w12),
        .i_w20(w20), .i_w21(w21), .i_w22(w22),

        .i_k00(k00), .i_k01(k01), .i_k02(k02),
        .i_k10(k10), .i_k11(k11), .i_k12(k12),
        .i_k20(k20), .i_k21(k21), .i_k22(k22),

        .o_w00(pw00), .o_w01(pw01), .o_w02(pw02),
        .o_w10(pw10), .o_w11(pw11), .o_w12(pw12),
        .o_w20(pw20), .o_w21(pw21), .o_w22(pw22),

        .o_k00(pk00), .o_k01(pk01), .o_k02(pk02),
        .o_k10(pk10), .o_k11(pk11), .o_k12(pk12),
        .o_k20(pk20), .o_k21(pk21), .o_k22(pk22)
    );

    // ---------------------------------------------------------
    // tap block
    // ---------------------------------------------------------
    tap_3x3_4lane u_tap_3x3_4lane (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (ctrl_pipe_shift_en),

        .i_w00 (pw00), .i_w01(pw01), .i_w02(pw02),
        .i_w10 (pw10), .i_w11(pw11), .i_w12(pw12),
        .i_w20 (pw20), .i_w21(pw21), .i_w22(pw22),

        .i_k00 (pk00), .i_k01(pk01), .i_k02(pk02),
        .i_k10 (pk10), .i_k11(pk11), .i_k12(pk12),
        .i_k20 (pk20), .i_k21(pk21), .i_k22(pk22),

        .o_y00 (ty00), .o_y01(ty01), .o_y02(ty02), .o_y03(ty03),
        .o_y10 (ty10), .o_y11(ty11), .o_y12(ty12), .o_y13(ty13),
        .o_y20 (ty20), .o_y21(ty21), .o_y22(ty22), .o_y23(ty23),
        .o_y30 (ty30), .o_y31(ty31), .o_y32(ty32), .o_y33(ty33),
        .o_y40 (ty40), .o_y41(ty41), .o_y42(ty42), .o_y43(ty43),
        .o_y50 (ty50), .o_y51(ty51), .o_y52(ty52), .o_y53(ty53),
        .o_y60 (ty60), .o_y61(ty61), .o_y62(ty62), .o_y63(ty63),
        .o_y70 (ty70), .o_y71(ty71), .o_y72(ty72), .o_y73(ty73),
        .o_y80 (ty80), .o_y81(ty81), .o_y82(ty82), .o_y83(ty83)
    );

    // ---------------------------------------------------------
    // accumulator
    // remap tap-major -> lane-major
    // ---------------------------------------------------------
    accumulator_9tap_4lane u_accumulator_9tap_4lane (
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n),
        .i_pipe_shift_en(ctrl_pipe_shift_en),

        // lane s
        .i_y00(ty00), .i_y01(ty10), .i_y02(ty20), .i_y03(ty30), .i_y04(ty40),
        .i_y05(ty50), .i_y06(ty60), .i_y07(ty70), .i_y08(ty80),

        // lane i
        .i_y10(ty01), .i_y11(ty11), .i_y12(ty21), .i_y13(ty31), .i_y14(ty41),
        .i_y15(ty51), .i_y16(ty61), .i_y17(ty71), .i_y18(ty81),

        // lane j
        .i_y20(ty02), .i_y21(ty12), .i_y22(ty22), .i_y23(ty32), .i_y24(ty42),
        .i_y25(ty52), .i_y26(ty62), .i_y27(ty72), .i_y28(ty82),

        // lane k
        .i_y30(ty03), .i_y31(ty13), .i_y32(ty23), .i_y33(ty33), .i_y34(ty43),
        .i_y35(ty53), .i_y36(ty63), .i_y37(ty73), .i_y38(ty83),

        .o_out_s(o_out_s),
        .o_out_i(o_out_i),
        .o_out_j(o_out_j),
        .o_out_k(o_out_k)
    );

endmodule
