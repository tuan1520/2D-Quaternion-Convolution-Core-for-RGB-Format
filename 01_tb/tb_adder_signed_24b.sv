`timescale 1ns/1ps

module tb_adder_signed_24b;

    logic signed [23:0] i_a;
    logic signed [23:0] i_b;
    logic               i_cin;
    logic signed [23:0] o_sum;
    logic               o_overflow;

    logic signed [23:0] expected_sum;
    logic               expected_overflow;

    logic signed [24:0] ext_a;
    logic signed [24:0] ext_b;
    logic signed [24:0] ext_sum;

    int pass_count;
    int fail_count;

    adder_signed_24b dut (
        .i_a        (i_a),
        .i_b        (i_b),
        .i_cin      (i_cin),
        .o_sum      (o_sum),
        .o_overflow (o_overflow)
    );

    task automatic run_case(
        input logic signed [23:0] ta,
        input logic signed [23:0] tb,
        input logic               tcin
    );
    begin
        i_a   = ta;
        i_b   = tb;
        i_cin = tcin;
        #1;

        ext_a = {ta[23], ta};
        ext_b = {tb[23], tb};
        ext_sum = ext_a + ext_b + tcin;

        expected_sum      = ext_sum[23:0];
        expected_overflow = (ext_sum[24] != ext_sum[23]);

        if ((o_sum !== expected_sum) || (o_overflow !== expected_overflow)) begin
            fail_count++;
            $display("[FAIL] t=%0t | a=%0d (0x%h), b=%0d (0x%h), cin=%0d | sum=%0d (0x%h), ovf=%0d | exp_sum=%0d (0x%h), exp_ovf=%0d",
                     $time,
                     ta, ta, tb, tb, tcin,
                     o_sum, o_sum, o_overflow,
                     expected_sum, expected_sum, expected_overflow);
        end
        else begin
            pass_count++;
            $display("[PASS] t=%0t | a=%0d, b=%0d, cin=%0d | sum=%0d, ovf=%0d",
                     $time, ta, tb, tcin, o_sum, o_overflow);
        end
    end
    endtask

    initial begin
        $shm_open("adder_signed_24b.shm");
        $shm_probe(tb_adder_signed_24b, "AS");
    end

    initial begin
        pass_count = 0;
        fail_count = 0;

        i_a   = '0;
        i_b   = '0;
        i_cin = 1'b0;
        #5;

        // case co ban
        run_case( 24'sd0,         24'sd0,         1'b0);
        run_case( 24'sd1,         24'sd2,         1'b0);
        run_case( 24'sd1,         24'sd2,         1'b1);
        run_case(-24'sd1,         24'sd1,         1'b0);
        run_case(-24'sd10,        24'sd3,         1'b1);
        run_case(-24'sd15,       -24'sd20,        1'b0);

        // bien 24-bit signed
        run_case( 24'sd8388607,   24'sd0,         1'b0);
        run_case(-24'sd8388608,   24'sd0,         1'b0);
        run_case(-24'sd8388608,   24'sd1,         1'b0);

        // overflow duong
        run_case( 24'sd8388607,   24'sd1,         1'b0);
        run_case( 24'sd8388607,   24'sd0,         1'b1);
        run_case( 24'sd7000000,   24'sd2000000,   1'b0);

        // overflow am
        run_case(-24'sd8388608,  -24'sd1,         1'b0);
        run_case(-24'sd8388608,  -24'sd1,         1'b1);
        run_case(-24'sd7000000,  -24'sd2000000,   1'b0);

        // mixed sign
        run_case( 24'sd5000000,  -24'sd4000000,   1'b0);
        run_case( 24'sd5000000,  -24'sd4000000,   1'b1);
        run_case(-24'sd5000000,   24'sd4000000,   1'b0);

        // random it hon
        repeat (20) begin
            run_case($random, $random, $random);
        end

        $display("========================================");
        $display("tb_adder_signed_24b DONE");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("========================================");

        if (fail_count == 0) begin
            $display("TEST PASSED");
            $finish;
        end
        else begin
            $fatal(1, "TEST FAILED with %0d errors", fail_count);
        end
    end

endmodule
