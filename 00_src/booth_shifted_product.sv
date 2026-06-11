`timescale 1ns/1ps
module booth_3b_group_gen (
    input  logic [8:0] i_y,

    output logic [2:0] o_group_0,
    output logic [2:0] o_group_1,
    output logic [2:0] o_group_2,
    output logic [2:0] o_group_3,
    output logic [2:0] o_group_4
);

    assign o_group_0 = {i_y[1], i_y[0], 1'b0};
    assign o_group_1 = {i_y[3], i_y[2], i_y[1]};
    assign o_group_2 = {i_y[5], i_y[4], i_y[3]};
    assign o_group_3 = {i_y[7], i_y[6], i_y[5]};
    assign o_group_4 = {i_y[8], i_y[8], i_y[7]};

endmodule

module booth_encoder_radix4 (
    input  logic [2:0] i_group,
    output logic [2:0] o_sel
);

    localparam logic [2:0] SEL_0      = 3'b000;
    localparam logic [2:0] SEL_POS_X  = 3'b001;
    localparam logic [2:0] SEL_NEG_X  = 3'b010;
    localparam logic [2:0] SEL_POS_2X = 3'b011;
    localparam logic [2:0] SEL_NEG_2X = 3'b100;

    always_comb begin
        case (i_group)
            3'b000: o_sel = SEL_0;
            3'b001: o_sel = SEL_POS_X;
            3'b010: o_sel = SEL_POS_X;
            3'b011: o_sel = SEL_POS_2X;
            3'b100: o_sel = SEL_NEG_2X;
            3'b101: o_sel = SEL_NEG_X;
            3'b110: o_sel = SEL_NEG_X;
            3'b111: o_sel = SEL_0;
            default: o_sel = SEL_0;
        endcase
    end

endmodule

module booth_pp_gen_18b (
    input  logic signed [8:0]  i_x,
    input  logic        [2:0]  i_sel,
    output logic signed [17:0] o_pp_unshifted
);

    localparam logic [2:0] SEL_0      = 3'b000;
    localparam logic [2:0] SEL_POS_X  = 3'b001;
    localparam logic [2:0] SEL_NEG_X  = 3'b010;
    localparam logic [2:0] SEL_POS_2X = 3'b011;
    localparam logic [2:0] SEL_NEG_2X = 3'b100;

    logic signed [23:0] x_ext_24;
    logic signed [23:0] x_inv_24;

    logic signed [23:0] pos_x_24;
    logic signed [23:0] neg_x_24;
    logic signed [23:0] pos_2x_24;
    logic signed [23:0] neg_2x_24;

    logic signed [23:0] pp_selected_24;

    logic               overflow_neg_x_unused;
    logic               overflow_neg_2x_unused;

    assign x_ext_24 = {{15{i_x[8]}}, i_x};
    assign x_inv_24 = ~x_ext_24;

    assign pos_x_24  = x_ext_24;

    // shift left 1 bit bang ghep bit, khong dung <<<
    assign pos_2x_24 = {x_ext_24[22:0], 1'b0};

    // -X = ~X + 1
    adder_signed_24b u_neg_x (
        .i_a        (x_inv_24),
        .i_b        (24'sd0),
        .i_cin      (1'b1),
        .o_sum      (neg_x_24),
        .o_overflow (overflow_neg_x_unused)
    );

    // -(2X) = ~(2X) + 1
    adder_signed_24b u_neg_2x (
        .i_a        (~pos_2x_24),
        .i_b        (24'sd0),
        .i_cin      (1'b1),
        .o_sum      (neg_2x_24),
        .o_overflow (overflow_neg_2x_unused)
    );

    always_comb begin
        case (i_sel)
            SEL_0      : pp_selected_24 = 24'sd0;
            SEL_POS_X  : pp_selected_24 = pos_x_24;
            SEL_NEG_X  : pp_selected_24 = neg_x_24;
            SEL_POS_2X : pp_selected_24 = pos_2x_24;
            SEL_NEG_2X : pp_selected_24 = neg_2x_24;
            default    : pp_selected_24 = 24'sd0;
        endcase
    end

    assign o_pp_unshifted = pp_selected_24[17:0];

endmodule

module booth_recode_9b (
    input  logic [8:0] i_y,

    output logic [2:0] o_sel_0,
    output logic [2:0] o_sel_1,
    output logic [2:0] o_sel_2,
    output logic [2:0] o_sel_3,
    output logic [2:0] o_sel_4
);

    logic [2:0] group_0;
    logic [2:0] group_1;
    logic [2:0] group_2;
    logic [2:0] group_3;
    logic [2:0] group_4;

    booth_3b_group_gen u_group_gen (
        .i_y      (i_y),
        .o_group_0(group_0),
        .o_group_1(group_1),
        .o_group_2(group_2),
        .o_group_3(group_3),
        .o_group_4(group_4)
    );

    booth_encoder_radix4 u_encoder_0 (
        .i_group(group_0),
        .o_sel  (o_sel_0)
    );

    booth_encoder_radix4 u_encoder_1 (
        .i_group(group_1),
        .o_sel  (o_sel_1)
    );

    booth_encoder_radix4 u_encoder_2 (
        .i_group(group_2),
        .o_sel  (o_sel_2)
    );

    booth_encoder_radix4 u_encoder_3 (
        .i_group(group_3),
        .o_sel  (o_sel_3)
    );

    booth_encoder_radix4 u_encoder_4 (
        .i_group(group_4),
        .o_sel  (o_sel_4)
    );

endmodule

module booth_shifted_product (
    input  logic               i_clk,
    input  logic               i_rst_n,
    input  logic               i_en,

    input  logic signed [8:0]  i_x,
    input  logic        [8:0]  i_y,

    output logic signed [17:0] o_pp0,
    output logic signed [17:0] o_pp1,
    output logic signed [17:0] o_pp2,
    output logic signed [17:0] o_pp3,
    output logic signed [17:0] o_pp4
);

    logic [2:0] sel_0;
    logic [2:0] sel_1;
    logic [2:0] sel_2;
    logic [2:0] sel_3;
    logic [2:0] sel_4;

    logic signed [17:0] pp0_unshifted;
    logic signed [17:0] pp1_unshifted;
    logic signed [17:0] pp2_unshifted;
    logic signed [17:0] pp3_unshifted;
    logic signed [17:0] pp4_unshifted;

    logic signed [17:0] pp0_shifted;
    logic signed [17:0] pp1_shifted;
    logic signed [17:0] pp2_shifted;
    logic signed [17:0] pp3_shifted;
    logic signed [17:0] pp4_shifted;

    booth_recode_9b u_booth_recode_9b (
        .i_y   (i_y),
        .o_sel_0(sel_0),
        .o_sel_1(sel_1),
        .o_sel_2(sel_2),
        .o_sel_3(sel_3),
        .o_sel_4(sel_4)
    );

    booth_pp_gen_18b u_pp_gen_0 (
        .i_x           (i_x),
        .i_sel         (sel_0),
        .o_pp_unshifted(pp0_unshifted)
    );

    booth_pp_gen_18b u_pp_gen_1 (
        .i_x           (i_x),
        .i_sel         (sel_1),
        .o_pp_unshifted(pp1_unshifted)
    );

    booth_pp_gen_18b u_pp_gen_2 (
        .i_x           (i_x),
        .i_sel         (sel_2),
        .o_pp_unshifted(pp2_unshifted)
    );

    booth_pp_gen_18b u_pp_gen_3 (
        .i_x           (i_x),
        .i_sel         (sel_3),
        .o_pp_unshifted(pp3_unshifted)
    );

    booth_pp_gen_18b u_pp_gen_4 (
        .i_x           (i_x),
        .i_sel         (sel_4),
        .o_pp_unshifted(pp4_unshifted)
    );

    assign pp0_shifted = pp0_unshifted;
    assign pp1_shifted = {pp1_unshifted[15:0], 2'b00};
    assign pp2_shifted = {pp2_unshifted[13:0], 4'b0000};
    assign pp3_shifted = {pp3_unshifted[11:0], 6'b000000};
    assign pp4_shifted = {pp4_unshifted[9:0],  8'b00000000};
	 
    // pipeline chot du lieu cua product
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_pp0 <= 18'sd0;
            o_pp1 <= 18'sd0;
            o_pp2 <= 18'sd0;
            o_pp3 <= 18'sd0;
            o_pp4 <= 18'sd0;
        end
        else if (i_en) begin
            o_pp0 <= pp0_shifted;
            o_pp1 <= pp1_shifted;
            o_pp2 <= pp2_shifted;
            o_pp3 <= pp3_shifted;
            o_pp4 <= pp4_shifted;
        end
    end

endmodule
