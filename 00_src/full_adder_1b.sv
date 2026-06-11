`timescale 1ns/1ps
module full_adder_1b (
    input  logic i_a,
    input  logic i_b,
    input  logic i_cin,
    output logic o_sum,
    output logic o_cout
);

    assign o_sum  = i_a ^ i_b ^ i_cin;
    assign o_cout = (i_a & i_b)
                  | (i_a & i_cin)
                  | (i_b & i_cin);

endmodule