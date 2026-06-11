`timescale 1ns/1ps
module rgb_stream_in #(
    parameter int IMG_W = 64,
    parameter int IMG_H = 64
)(
    input  logic        i_clk,
    input  logic        i_rst_n,

    // input from testbench
    input  logic        i_tb_valid,
    input  logic [23:0] i_tb_pixel,
    output logic        o_tb_ready,

    // input from controller
    input  logic        i_busy,
    input  logic        i_frame_done,

    // pixel stream output
    output logic        o_pixel_valid,
    output logic [23:0] o_pixel_data,
    output logic        o_start_frame,
    output logic        o_end_line,
    output logic        o_end_frame,
    output logic [$clog2(IMG_W)-1:0] o_x,
    output logic [$clog2(IMG_H)-1:0] o_y
);

    localparam int X_W = $clog2(IMG_W);
    localparam int Y_W = $clog2(IMG_H);

    logic           hold_valid;
    logic [23:0]    hold_pixel;

    logic [X_W-1:0] x_cnt;
    logic [Y_W-1:0] y_cnt;

    logic           fire;

    logic [6:0]     x_cnt_plus_1;
    logic [6:0]     y_cnt_plus_1;

    assign o_tb_ready    = ~hold_valid;
    assign fire          = hold_valid & ~i_busy;

    assign o_pixel_valid = fire;
    assign o_pixel_data  = hold_pixel;

    assign o_start_frame = fire && (x_cnt == '0) && (y_cnt == '0);
    assign o_end_line    = fire && (x_cnt == IMG_W-1);
    assign o_end_frame   = fire && (x_cnt == IMG_W-1) && (y_cnt == IMG_H-1);

    assign o_x           = x_cnt;
    assign o_y           = y_cnt;

    adder_unsigned_6b u_add_x (
        .i_a  (x_cnt),
        .i_b  (6'd1),
        .o_sum(x_cnt_plus_1)
    );

    adder_unsigned_6b u_add_y (
        .i_a  (y_cnt),
        .i_b  (6'd1),
        .o_sum(y_cnt_plus_1)
    );

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            hold_valid <= 1'b0;
            hold_pixel <= 24'd0;
            x_cnt      <= '0;
            y_cnt      <= '0;
        end
        else begin
            if (i_frame_done) begin
                hold_valid <= 1'b0;
                hold_pixel <= 24'd0;
                x_cnt      <= '0;
                y_cnt      <= '0;
            end
            else begin
                if (i_tb_valid && o_tb_ready) begin
                    hold_valid <= 1'b1;
                    hold_pixel <= i_tb_pixel;
                end

                if (fire) begin
                    hold_valid <= 1'b0;

                    if (x_cnt == IMG_W-1) begin
                        x_cnt <= '0;

                        if (y_cnt == IMG_H-1)
                            y_cnt <= '0;
                        else
                            y_cnt <= y_cnt_plus_1[Y_W-1:0];
                    end
                    else begin
                        x_cnt <= x_cnt_plus_1[X_W-1:0];
                    end
                end
            end
        end
    end

endmodule
