`timescale 1ns/1ps

module tb_subtractor_signed_24b;

    logic signed [23:0] i_a;
    logic signed [23:0] i_b;
    logic signed [23:0] o_diff;

    logic signed [24:0] ext_a;
    logic signed [24:0] ext_b;
    logic signed [24:0] ext_diff;

    logic signed [23:0] expected_diff;

    int pass_count;
    int fail_count;

    subtractor_signed_24b dut (
        .i_a    (i_a),
        .i_b    (i_b),
        .o_diff (o_diff)
    );

    task automatic run_case(
        input logic signed [23:0] ta,
        input logic signed [23:0] tb
    );
    begin
        i_a = ta;
        i_b = tb;
        #1;

        ext_a = {ta[23], ta};
        ext_b = {tb[23], tb};
        ext_diff = ext_a - ext_b;

        expected_diff = ext_diff[23:0];

        if (o_diff !== expected_diff) begin
           fail_count++;
           $display("[FAIL] t=%0t | a=%0d (0x%h), b=%0d (0x%h) | diff=%0d (0x%h) | exp_diff=%0d (0x%h)",
             $time,
             ta, ta, tb, tb,
             o_diff, o_diff,
             expected_diff, expected_diff);
        end
        else begin
           pass_count++;
           $display("[PASS] t=%0t | a=%0d (0x%h), b=%0d (0x%h) | diff=%0d (0x%h)",
             $time,
             ta, ta, tb, tb,
             o_diff, o_diff);
end
    end
    endtask

    initial begin
        $shm_open("subtractor_signed_24b.shm");
        $shm_probe(tb_subtractor_signed_24b, "AS");
    end

    initial begin
        pass_count = 0;
        fail_count = 0;

        i_a = '0;
        i_b = '0;
        #5;

        // case co ban
        run_case( 24'sd0,         24'sd0);
        run_case( 24'sd10,        24'sd3);
        run_case( 24'sd3,         24'sd10);
        run_case(-24'sd10,        24'sd3);
        run_case( 24'sd10,       -24'sd3);
        run_case(-24'sd15,       -24'sd20);

        // bien 24-bit signed
        run_case( 24'sd8388607,   24'sd0);
        run_case(-24'sd8388608,   24'sd0);
        run_case(-24'sd8388608,   24'sd1);
        run_case( 24'sd8388607,  -24'sd1);

        // overflow / wrap-around observation
        run_case( 24'sd8388607,  -24'sd8388608);
        run_case(-24'sd8388608,   24'sd8388607);
        run_case( 24'sd7000000,  -24'sd2000000);
        run_case(-24'sd7000000,   24'sd2000000);

        // mixed sign
        run_case( 24'sd5000000,  -24'sd4000000);
        run_case(-24'sd5000000,   24'sd4000000);
        run_case( 24'sd1234567,   24'sd1234567);
        run_case( 24'sd1234567,  -24'sd1234567);

        // random it hon
        repeat (20) begin
            run_case($random, $random);
        end

        $display("========================================");
        $display("tb_subtractor_signed_24b DONE");
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
