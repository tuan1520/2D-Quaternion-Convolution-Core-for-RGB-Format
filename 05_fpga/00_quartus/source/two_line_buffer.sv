`timescale 1ns/1ps
module dff_1b (
    input  logic i_clk,
    input  logic i_rst_n,
    input  logic i_en,
    input  logic i_d,
    output logic o_q
);

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            o_q <= 1'b0;
        else if (i_en)
            o_q <= i_d;
    end

endmodule


module lb_reg_24b (
    input  logic        i_clk,
    input  logic        i_rst_n, 
    input  logic        i_en,
    input  logic [23:0] i_pixel_in,
    output logic [23:0] o_pixel_out
);

    genvar k;

    generate
        for (k = 0; k < 24; k = k + 1) begin : gen_dff
            dff_1b u_dff (
                .i_clk  (i_clk),
                .i_rst_n(i_rst_n),
                .i_en   (i_en),
                .i_d    (i_pixel_in[k]),
                .o_q    (o_pixel_out[k])
            );
        end
    endgenerate

endmodule


module line_buffer #(
    parameter int LINE_LENGTH = 64
)(
    input  logic        i_clk,
    input  logic        i_rst_n,
    input  logic        i_lb_en,
    input  logic [23:0] i_start_lb,
    output logic [23:0] o_end_lb
);

    logic [23:0] pixel_shift [0:LINE_LENGTH-1];

    genvar k;

    generate
        for (k = 0; k < LINE_LENGTH; k = k + 1) begin : gen_lb
            if (k == 0) begin : gen_first // line buffer 1: get stream input, line buffer 2: get input from line 1
                lb_reg_24b u_lb_reg (
                    .i_clk       (i_clk),
                    .i_rst_n     (i_rst_n),
                    .i_en        (i_lb_en),
                    .i_pixel_in  (i_start_lb),
                    .o_pixel_out (pixel_shift[k])
                );
            end
            else begin : gen_rest
                lb_reg_24b u_lb_reg (
                    .i_clk       (i_clk),
                    .i_rst_n     (i_rst_n),
                    .i_en        (i_lb_en),
                    .i_pixel_in  (pixel_shift[k-1]),
                    .o_pixel_out (pixel_shift[k])
                );
            end
        end
    endgenerate

    assign o_end_lb = pixel_shift[LINE_LENGTH-1];

endmodule


module two_line_buffer #(
    parameter int LINE_LENGTH = 64
)(
    input  logic        i_clk,
    input  logic        i_rst_n,
    input  logic        i_lb_en,
    input  logic [23:0] i_pixel_data,

    output logic [23:0] o_window_line_0,
    output logic [23:0] o_window_line_1,
    output logic [23:0] o_window_line_2
);

    logic [23:0] line_buffer_1_out;
    logic [23:0] line_buffer_2_out;

    line_buffer #(
        .LINE_LENGTH(LINE_LENGTH)
    ) line_buffer_1 (
        .i_clk       (i_clk),
        .i_rst_n     (i_rst_n),
        .i_lb_en     (i_lb_en),
        .i_start_lb  (i_pixel_data),
        .o_end_lb    (line_buffer_1_out)
    );

    line_buffer #(
        .LINE_LENGTH(LINE_LENGTH)
    ) line_buffer_2 (
        .i_clk       (i_clk),
        .i_rst_n     (i_rst_n),
        .i_lb_en     (i_lb_en),
        .i_start_lb  (line_buffer_1_out),
        .o_end_lb    (line_buffer_2_out)
    );

    assign o_window_line_0 = line_buffer_2_out;
    assign o_window_line_1 = line_buffer_1_out;
    assign o_window_line_2 = i_pixel_data;

endmodule
