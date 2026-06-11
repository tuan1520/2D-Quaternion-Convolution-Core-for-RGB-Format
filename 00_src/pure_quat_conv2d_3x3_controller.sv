`timescale 1ns/1ps

module ge2_unsigned #(
    parameter int W = 6
)(
    input  logic [W-1:0] i_val,
    output logic         o_ge_2
);
    generate
        if (W == 1) begin : gen_w1
            assign o_ge_2 = 1'b0;
        end
        else begin : gen_wgt1
            assign o_ge_2 = |i_val[W-1:1];
        end
    endgenerate
endmodule


module pure_quat_conv2d_3x3_controller #(
    parameter int IMG_W = 64,
    parameter int IMG_H = 64,
    parameter int TOTAL_PIPE_LAT = 7
)(
    input  logic                           i_clk,
    input  logic                           i_rst_n,

    input  logic                           i_start,
    input  logic                           i_next_frame,

    input  logic                           i_ker_done,

    input  logic                           i_pixel_valid,
    input  logic                           i_end_frame,
    input  logic [$clog2(IMG_W)-1:0]       i_x,
    input  logic [$clog2(IMG_H)-1:0]       i_y,

    output logic                           o_busy,
    output logic                           o_frame_done,

    output logic                           o_ker_load_en,

    output logic                           o_lb_en,
    output logic                           o_win_en,
    output logic                           o_win_valid,

    output logic                           o_pipe_shift_en,
    output logic                           o_tap_load_valid,

    output logic                           o_out_valid,
    output logic                           o_out_latch,
    output logic                           o_out_empty
);

    typedef enum logic [2:0] {
        ST_IDLE        = 3'd0,
        ST_LOAD_KERNEL = 3'd1,
        ST_FILL        = 3'd2,
        ST_RUN         = 3'd3,
        ST_FLUSH       = 3'd4,
        ST_DONE        = 3'd5
    } state_t;

    state_t state_cur, state_nxt;

    logic [TOTAL_PIPE_LAT:0] valid_pipe;
    logic                    pipeline_empty;

    logic                    start_d;
    logic                    start_pulse;

    logic                    x_ge_2;
    logic                    y_ge_2;

    logic                    window_ready_now;
    logic                    win_fill_valid_now;

    // delay 3 valid-beat de canh thoi diem chot input vao tap
    logic [2:0]              pipe_in_valid_dly;
    logic                    pipe_in_valid_now;

    //==================================================
    // start edge detect
    //==================================================
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            start_d <= 1'b0;
        else
            start_d <= i_start;
    end

    assign start_pulse = i_start & ~start_d;

    //==================================================
    // compare x >= 2, y >= 2
    //==================================================
    ge2_unsigned #(
        .W($clog2(IMG_W))
    ) u_cmp_x_ge_2 (
        .i_val (i_x),
        .o_ge_2(x_ge_2)
    );

    ge2_unsigned #(
        .W($clog2(IMG_H))
    ) u_cmp_y_ge_2 (
        .i_val (i_y),
        .o_ge_2(y_ge_2)
    );

    // raw ready theo toa do
    assign window_ready_now   = i_pixel_valid && x_ge_2 && y_ge_2;

    // cho phep window generator fill khi da co du 3 hang
    assign win_fill_valid_now = i_pixel_valid && y_ge_2;

    // valid da delay 3 valid-beat de dua vao tap_input_pipe
    assign pipe_in_valid_now  = i_pixel_valid && pipe_in_valid_dly[2];

    //==================================================
    // delay 3 valid-beat cho pipe_in_valid
    // giu nguyen qua bubble i_pixel_valid = 0
    //==================================================
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            pipe_in_valid_dly <= 3'b000;
        end
        else begin
            case (state_cur)
                ST_FILL, ST_RUN: begin
                    if (i_pixel_valid)
                        pipe_in_valid_dly <= {pipe_in_valid_dly[1:0], win_fill_valid_now};
                    else
                        pipe_in_valid_dly <= pipe_in_valid_dly;
                end

                default: begin
                    pipe_in_valid_dly <= 3'b000;
                end
            endcase
        end
    end

    //==================================================
    // state register
    //==================================================
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            state_cur <= ST_IDLE;
        else
            state_cur <= state_nxt;
    end

    //==================================================
    // next-state logic
    //==================================================
    always_comb begin
        state_nxt = state_cur;

        case (state_cur)
            ST_IDLE: begin
                if (start_pulse)
                    state_nxt = ST_LOAD_KERNEL;
            end

            ST_LOAD_KERNEL: begin
                if (i_ker_done)
                    state_nxt = ST_FILL;
            end

            ST_FILL: begin
                if (pipe_in_valid_now)
                    state_nxt = ST_RUN;
            end

            ST_RUN: begin
                if (i_end_frame)
                    state_nxt = ST_FLUSH;
            end

            ST_FLUSH: begin
                if (pipeline_empty)
                    state_nxt = ST_DONE;
            end

            ST_DONE: begin
                if (i_next_frame)
                    state_nxt = ST_IDLE;
            end

            default: begin
                state_nxt = ST_IDLE;
            end
        endcase
    end

    //==================================================
    // output logic
    //==================================================
    always_comb begin
        o_busy           = 1'b1;
        o_frame_done     = 1'b0;
        o_ker_load_en    = 1'b0;
        o_lb_en          = 1'b0;
        o_win_en         = 1'b0;
        o_win_valid      = 1'b0;
        o_pipe_shift_en  = 1'b0;
        o_tap_load_valid = 1'b0;

        case (state_cur)
            ST_IDLE: begin
            end

            ST_LOAD_KERNEL: begin
                o_ker_load_en = 1'b1;
            end

            ST_FILL: begin
                o_busy           = 1'b0;
                o_lb_en          = i_pixel_valid;
                o_win_en         = i_pixel_valid;
                o_win_valid      = win_fill_valid_now;
                o_pipe_shift_en  = pipe_in_valid_now;
                o_tap_load_valid = pipe_in_valid_now;
            end

            ST_RUN: begin
                o_busy           = 1'b0;
                o_lb_en          = i_pixel_valid;
                o_win_en         = i_pixel_valid;
                o_win_valid      = win_fill_valid_now;
                o_pipe_shift_en  = pipe_in_valid_now;
                o_tap_load_valid = pipe_in_valid_now;
            end

            ST_FLUSH: begin
                o_pipe_shift_en  = ~pipeline_empty;
                o_tap_load_valid = 1'b0;
            end

            ST_DONE: begin
                o_frame_done = 1'b1;
            end

            default: begin
            end
        endcase
    end

    //==================================================
    // output-valid pipeline
    // TOTAL_PIPE_LAT = so beat tu luc o_tap_load_valid = 1
    // den luc o_out_valid = 1
    //==================================================
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            valid_pipe <= '0;
        end
        else if (o_pipe_shift_en) begin
            valid_pipe <= {valid_pipe[TOTAL_PIPE_LAT-1:0], o_tap_load_valid};
        end
    end

    assign pipeline_empty = ~(|valid_pipe);

    assign o_out_valid = valid_pipe[TOTAL_PIPE_LAT];
    assign o_out_latch = o_out_valid;
    assign o_out_empty = pipeline_empty;

endmodule