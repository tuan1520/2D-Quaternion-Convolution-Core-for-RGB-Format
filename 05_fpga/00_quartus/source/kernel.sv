`timescale 1ns/1ps
module kernel (
    input  logic        i_clk,
    input  logic        i_rst_n,

    input  logic        i_ker_cfg_valid,
    input  logic [3:0]  i_ker_cfg_idx,
    input  logic [23:0] i_ker_input,

    output logic        o_ker_done,

    output logic [23:0] o_k00,
    output logic [23:0] o_k01,
    output logic [23:0] o_k02,
    output logic [23:0] o_k10,
    output logic [23:0] o_k11,
    output logic [23:0] o_k12,
    output logic [23:0] o_k20,
    output logic [23:0] o_k21,
    output logic [23:0] o_k22
);

    logic [23:0] kernel_reg [0:8];
    logic [8:0]  kernel_loaded;

    integer n;

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (n = 0; n < 9; n = n + 1) begin
                kernel_reg[n] <= 24'd0;
            end
            kernel_loaded <= 9'd0;
        end
        else begin
            if (i_ker_cfg_valid) begin
                case (i_ker_cfg_idx)
                    4'd0: begin
                        kernel_reg[0]    <= i_ker_input;
                        kernel_loaded[0] <= 1'b1;
                    end
                    4'd1: begin
                        kernel_reg[1]    <= i_ker_input;
                        kernel_loaded[1] <= 1'b1;
                    end
                    4'd2: begin
                        kernel_reg[2]    <= i_ker_input;
                        kernel_loaded[2] <= 1'b1;
                    end
                    4'd3: begin
                        kernel_reg[3]    <= i_ker_input;
                        kernel_loaded[3] <= 1'b1;
                    end
                    4'd4: begin
                        kernel_reg[4]    <= i_ker_input;
                        kernel_loaded[4] <= 1'b1;
                    end
                    4'd5: begin
                        kernel_reg[5]    <= i_ker_input;
                        kernel_loaded[5] <= 1'b1;
                    end
                    4'd6: begin
                        kernel_reg[6]    <= i_ker_input;
                        kernel_loaded[6] <= 1'b1;
                    end
                    4'd7: begin
                        kernel_reg[7]    <= i_ker_input;
                        kernel_loaded[7] <= 1'b1;
                    end
                    4'd8: begin
                        kernel_reg[8]    <= i_ker_input;
                        kernel_loaded[8] <= 1'b1;
                    end
                    default: begin
                    end
                endcase
            end
        end
    end

    assign o_ker_done = &kernel_loaded;

    assign o_k00 = kernel_reg[0];
    assign o_k01 = kernel_reg[1];
    assign o_k02 = kernel_reg[2];
    assign o_k10 = kernel_reg[3];
    assign o_k11 = kernel_reg[4];
    assign o_k12 = kernel_reg[5];
    assign o_k20 = kernel_reg[6];
    assign o_k21 = kernel_reg[7];
    assign o_k22 = kernel_reg[8];

endmodule
