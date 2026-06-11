`timescale 1ns/1ps

module tb_accumulator_9tap_4lane;

    logic               i_clk;
    logic               i_rst_n;
    logic               i_pipe_shift_en;

    // lane s
    logic signed [17:0] i_y00, i_y01, i_y02, i_y03, i_y04, i_y05, i_y06, i_y07, i_y08;
    // lane i
    logic signed [17:0] i_y10, i_y11, i_y12, i_y13, i_y14, i_y15, i_y16, i_y17, i_y18;
    // lane j
    logic signed [17:0] i_y20, i_y21, i_y22, i_y23, i_y24, i_y25, i_y26, i_y27, i_y28;
    // lane k
    logic signed [17:0] i_y30, i_y31, i_y32, i_y33, i_y34, i_y35, i_y36, i_y37, i_y38;

    logic signed [23:0] o_out_s;
    logic signed [23:0] o_out_i;
    logic signed [23:0] o_out_j;
    logic signed [23:0] o_out_k;

    int pass_count;
    int fail_count;

    logic signed [23:0] last_exp_s;
    logic signed [23:0] last_exp_i;
    logic signed [23:0] last_exp_j;
    logic signed [23:0] last_exp_k;

    accumulator_9tap_4lane dut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_pipe_shift_en(i_pipe_shift_en),

        .i_y00(i_y00), .i_y01(i_y01), .i_y02(i_y02), .i_y03(i_y03), .i_y04(i_y04),
        .i_y05(i_y05), .i_y06(i_y06), .i_y07(i_y07), .i_y08(i_y08),

        .i_y10(i_y10), .i_y11(i_y11), .i_y12(i_y12), .i_y13(i_y13), .i_y14(i_y14),
        .i_y15(i_y15), .i_y16(i_y16), .i_y17(i_y17), .i_y18(i_y18),

        .i_y20(i_y20), .i_y21(i_y21), .i_y22(i_y22), .i_y23(i_y23), .i_y24(i_y24),
        .i_y25(i_y25), .i_y26(i_y26), .i_y27(i_y27), .i_y28(i_y28),

        .i_y30(i_y30), .i_y31(i_y31), .i_y32(i_y32), .i_y33(i_y33), .i_y34(i_y34),
        .i_y35(i_y35), .i_y36(i_y36), .i_y37(i_y37), .i_y38(i_y38),

        .o_out_s(o_out_s),
        .o_out_i(o_out_i),
        .o_out_j(o_out_j),
        .o_out_k(o_out_k)
    );

    //==================================================
    // clock
    //==================================================
    initial i_clk = 1'b0;
    always #5 i_clk = ~i_clk;

    //==================================================
    // helpers
    //==================================================
    function automatic logic signed [23:0] sx18(
        input logic signed [17:0] v
    );
    begin
        sx18 = {{6{v[17]}}, v};
    end
    endfunction

    function automatic logic signed [23:0] sum9_24(
        input logic signed [17:0] a0,
        input logic signed [17:0] a1,
        input logic signed [17:0] a2,
        input logic signed [17:0] a3,
        input logic signed [17:0] a4,
        input logic signed [17:0] a5,
        input logic signed [17:0] a6,
        input logic signed [17:0] a7,
        input logic signed [17:0] a8
    );
    begin
        sum9_24 = sx18(a0) + sx18(a1) + sx18(a2) + sx18(a3) + sx18(a4)
                + sx18(a5) + sx18(a6) + sx18(a7) + sx18(a8);
    end
    endfunction

    task automatic calc_current_expected(
        output logic signed [23:0] es,
        output logic signed [23:0] ei,
        output logic signed [23:0] ej,
        output logic signed [23:0] ek
    );
    begin
        es = sum9_24(i_y00, i_y01, i_y02, i_y03, i_y04, i_y05, i_y06, i_y07, i_y08);
        ei = sum9_24(i_y10, i_y11, i_y12, i_y13, i_y14, i_y15, i_y16, i_y17, i_y18);
        ej = sum9_24(i_y20, i_y21, i_y22, i_y23, i_y24, i_y25, i_y26, i_y27, i_y28);
        ek = sum9_24(i_y30, i_y31, i_y32, i_y33, i_y34, i_y35, i_y36, i_y37, i_y38);
    end
    endtask

    task automatic clear_all_inputs;
    begin
        i_y00 = 18'sd0; i_y01 = 18'sd0; i_y02 = 18'sd0; i_y03 = 18'sd0; i_y04 = 18'sd0;
        i_y05 = 18'sd0; i_y06 = 18'sd0; i_y07 = 18'sd0; i_y08 = 18'sd0;

        i_y10 = 18'sd0; i_y11 = 18'sd0; i_y12 = 18'sd0; i_y13 = 18'sd0; i_y14 = 18'sd0;
        i_y15 = 18'sd0; i_y16 = 18'sd0; i_y17 = 18'sd0; i_y18 = 18'sd0;

        i_y20 = 18'sd0; i_y21 = 18'sd0; i_y22 = 18'sd0; i_y23 = 18'sd0; i_y24 = 18'sd0;
        i_y25 = 18'sd0; i_y26 = 18'sd0; i_y27 = 18'sd0; i_y28 = 18'sd0;

        i_y30 = 18'sd0; i_y31 = 18'sd0; i_y32 = 18'sd0; i_y33 = 18'sd0; i_y34 = 18'sd0;
        i_y35 = 18'sd0; i_y36 = 18'sd0; i_y37 = 18'sd0; i_y38 = 18'sd0;
    end
    endtask

    // case 1 lay tu output tap_3x3_4lane truoc do de realistic
    task automatic load_case_1;
    begin
        // lane s
        i_y00 = -18'sd32;   i_y01 =  18'sd10;   i_y02 =  18'sd374;
        i_y03 = -18'sd255;  i_y04 =  18'sd660;  i_y05 = -18'sd97155;
        i_y06 =  18'sd0;    i_y07 = -18'sd86;   i_y08 =  18'sd32;

        // lane i
        i_y10 = -18'sd3;    i_y11 = -18'sd25;   i_y12 =  18'sd1043;
        i_y13 =  18'sd320;  i_y14 = -18'sd5090; i_y15 =  18'sd0;
        i_y16 =  18'sd0;    i_y17 = -18'sd3;    i_y18 = -18'sd73;

        // lane j
        i_y20 =  18'sd6;    i_y21 = -18'sd22;   i_y22 = -18'sd323;
        i_y23 = -18'sd446;  i_y24 = -18'sd3200; i_y25 =  18'sd0;
        i_y26 =  18'sd0;    i_y27 =  18'sd6;    i_y28 =  18'sd14;

        // lane k
        i_y30 = -18'sd3;    i_y31 =  18'sd31;   i_y32 = -18'sd928;
        i_y33 = -18'sd383;  i_y34 =  18'sd3830; i_y35 =  18'sd0;
        i_y36 =  18'sd0;    i_y37 = -18'sd3;    i_y38 =  18'sd47;
    end
    endtask

    task automatic load_case_2;
    begin
        // lane s
        i_y00 = -18'sd316;  i_y01 =  18'sd306;  i_y02 = -18'sd550;
        i_y03 =  18'sd480;  i_y04 = -18'sd182;  i_y05 =  18'sd84;
        i_y06 = -18'sd40;   i_y07 =  18'sd8;    i_y08 = -18'sd18;

        // lane i
        i_y10 =  18'sd754;  i_y11 = -18'sd183;  i_y12 =  18'sd200;
        i_y13 = -18'sd960;  i_y14 =  18'sd434;  i_y15 = -18'sd228;
        i_y16 =  18'sd115;  i_y17 = -18'sd32;   i_y18 =  18'sd36;

        // lane j
        i_y20 =  18'sd284;  i_y21 =  18'sd210;  i_y22 = -18'sd550;
        i_y23 =  18'sd0;    i_y24 =  18'sd140;  i_y25 = -18'sd120;
        i_y26 =  18'sd70;   i_y27 = -18'sd32;   i_y28 =  18'sd0;

        // lane k
        i_y30 = -18'sd334;  i_y31 =  18'sd585;  i_y32 =  18'sd300;
        i_y33 =  18'sd320;  i_y34 = -18'sd238;  i_y35 =  18'sd156;
        i_y36 = -18'sd85;   i_y37 =  18'sd32;   i_y38 = -18'sd12;
    end
    endtask

    task automatic print_capture_detail(
        input string name,
        input logic signed [23:0] es,
        input logic signed [23:0] ei,
        input logic signed [23:0] ej,
        input logic signed [23:0] ek
    );
    begin
        $display("--------------------------------------------------");
        $display("[CASE] %s | t=%0t", name, $time);
        $display("  exp : S=%0d I=%0d J=%0d K=%0d", es, ei, ej, ek);
        $display("  obs : S=%0d I=%0d J=%0d K=%0d", o_out_s, o_out_i, o_out_j, o_out_k);
    end
    endtask

    task automatic run_capture_case(
        input string name,
        input int case_id
    );
        logic signed [23:0] es, ei, ej, ek;
    begin
        @(negedge i_clk);
        i_pipe_shift_en = 1'b1;
        case (case_id)
            1: load_case_1();
            2: load_case_2();
            default: clear_all_inputs();
        endcase

        calc_current_expected(es, ei, ej, ek);

        // latency tong cong = 4 cycle
        @(posedge i_clk);
        @(posedge i_clk);
        @(posedge i_clk);
        @(posedge i_clk);
        #1;

        print_capture_detail(name, es, ei, ej, ek);

        if ((o_out_s !== es) || (o_out_i !== ei) || (o_out_j !== ej) || (o_out_k !== ek)) begin
            fail_count++;
            $display("[FAIL] %s", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s", name);

            last_exp_s = es;
            last_exp_i = ei;
            last_exp_j = ej;
            last_exp_k = ek;
        end
    end
    endtask

    task automatic run_hold_case(
        input string name,
        input int case_id
    );
    begin
        @(negedge i_clk);
        i_pipe_shift_en = 1'b0;
        case (case_id)
            1: load_case_1();
            2: load_case_2();
            default: clear_all_inputs();
        endcase

        @(posedge i_clk);
        @(posedge i_clk);
        @(posedge i_clk);
        @(posedge i_clk);
        #1;

        $display("--------------------------------------------------");
        $display("[CASE] %s | t=%0t", name, $time);
        $display("  hold: S=%0d I=%0d J=%0d K=%0d", o_out_s, o_out_i, o_out_j, o_out_k);

        if ((o_out_s !== last_exp_s) || (o_out_i !== last_exp_i) ||
            (o_out_j !== last_exp_j) || (o_out_k !== last_exp_k)) begin
            fail_count++;
            $display("[FAIL] %s", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s", name);
        end
    end
    endtask

    task automatic check_reset_zero(
        input string name
    );
    begin
        $display("--------------------------------------------------");
        $display("[CASE] %s | t=%0t", name, $time);
        $display("  rst : S=%0d I=%0d J=%0d K=%0d", o_out_s, o_out_i, o_out_j, o_out_k);

        if ((o_out_s !== 24'sd0) || (o_out_i !== 24'sd0) ||
            (o_out_j !== 24'sd0) || (o_out_k !== 24'sd0)) begin
            fail_count++;
            $display("[FAIL] %s", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s", name);

            last_exp_s = 24'sd0;
            last_exp_i = 24'sd0;
            last_exp_j = 24'sd0;
            last_exp_k = 24'sd0;
        end
    end
    endtask

    initial begin
        $shm_open("accumulator_9tap_4lane.shm");
        $shm_probe(tb_accumulator_9tap_4lane, "AS");
    end

    initial begin
        pass_count = 0;
        fail_count = 0;

        i_rst_n = 1'b1;
        i_pipe_shift_en = 1'b0;
        clear_all_inputs();

        #2;
        i_rst_n = 1'b0;
        #1;
        check_reset_zero("RESET_INIT");

        @(negedge i_clk);
        i_rst_n = 1'b1;

        run_capture_case("CAP_CASE_1", 1);
        run_hold_case   ("HOLD_AFTER_CASE_1", 2);
        run_capture_case("CAP_CASE_2", 2);

        #2;
        i_rst_n = 1'b0;
        #1;
        check_reset_zero("RESET_MID");

        $display("========================================");
        $display("tb_accumulator_9tap_4lane DONE");
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