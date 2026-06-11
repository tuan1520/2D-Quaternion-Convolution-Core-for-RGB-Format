`timescale 1ns/1ps

module tb_booth_shifted_product;

    logic              i_clk;
    logic              i_rst_n;
    logic              i_en;
    logic signed [8:0] i_x;
    logic        [8:0] i_y;

    logic signed [17:0] o_pp0;
    logic signed [17:0] o_pp1;
    logic signed [17:0] o_pp2;
    logic signed [17:0] o_pp3;
    logic signed [17:0] o_pp4;

    int pass_count;
    int fail_count;

    logic signed [17:0] last_exp_pp0;
    logic signed [17:0] last_exp_pp1;
    logic signed [17:0] last_exp_pp2;
    logic signed [17:0] last_exp_pp3;
    logic signed [17:0] last_exp_pp4;

    booth_shifted_product dut (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (i_en),
        .i_x   (i_x),
        .i_y   (i_y),
        .o_pp0 (o_pp0),
        .o_pp1 (o_pp1),
        .o_pp2 (o_pp2),
        .o_pp3 (o_pp3),
        .o_pp4 (o_pp4)
    );

    //==================================================
    // clock
    //==================================================
    initial i_clk = 1'b0;
    always #5 i_clk = ~i_clk;

    //==================================================
    // helper functions
    //==================================================
    function automatic logic [2:0] get_group(
        input logic [8:0] y,
        input int idx
    );
    begin
        case (idx)
            0: get_group = {y[1], y[0], 1'b0};
            1: get_group = {y[3], y[2], y[1]};
            2: get_group = {y[5], y[4], y[3]};
            3: get_group = {y[7], y[6], y[5]};
            4: get_group = {y[8], y[8], y[7]};
            default: get_group = 3'b000;
        endcase
    end
    endfunction

    function automatic logic [2:0] booth_sel(
        input logic [2:0] group
    );
    begin
        case (group)
            3'b000: booth_sel = 3'b000; // 0
            3'b001: booth_sel = 3'b001; // +X
            3'b010: booth_sel = 3'b001; // +X
            3'b011: booth_sel = 3'b011; // +2X
            3'b100: booth_sel = 3'b100; // -2X
            3'b101: booth_sel = 3'b010; // -X
            3'b110: booth_sel = 3'b010; // -X
            3'b111: booth_sel = 3'b000; // 0
            default: booth_sel = 3'b000;
        endcase
    end
    endfunction

    function automatic string sel_name(
        input logic [2:0] sel
    );
    begin
        case (sel)
            3'b000: sel_name = "0";
            3'b001: sel_name = "+X";
            3'b010: sel_name = "-X";
            3'b011: sel_name = "+2X";
            3'b100: sel_name = "-2X";
            default: sel_name = "?";
        endcase
    end
    endfunction

    function automatic logic signed [17:0] pp_unshifted_ref(
        input logic signed [8:0] x,
        input logic [2:0] sel
    );
        logic signed [17:0] x18;
    begin
        x18 = {{9{x[8]}}, x};

        case (sel)
            3'b000: pp_unshifted_ref = 18'sd0;
            3'b001: pp_unshifted_ref = x18;
            3'b010: pp_unshifted_ref = -x18;
            3'b011: pp_unshifted_ref = (x18 <<< 1);
            3'b100: pp_unshifted_ref = -(x18 <<< 1);
            default: pp_unshifted_ref = 18'sd0;
        endcase
    end
    endfunction

    function automatic logic signed [17:0] pp_shifted_ref(
        input logic signed [17:0] pp,
        input int sh
    );
        logic signed [35:0] wide;
    begin
        wide = {{18{pp[17]}}, pp};
        wide = wide <<< sh;
        pp_shifted_ref = wide[17:0];
    end
    endfunction

    task automatic print_case_detail(
        input string name,
        input logic signed [8:0] tx,
        input logic signed [8:0] ty,
        input logic [2:0] s0, input logic [2:0] s1, input logic [2:0] s2, input logic [2:0] s3, input logic [2:0] s4,
        input logic signed [17:0] e0, input logic signed [17:0] e1, input logic signed [17:0] e2, input logic signed [17:0] e3, input logic signed [17:0] e4
    );
        integer exp_total;
        integer obs_total;
    begin
        exp_total = $signed(e0) + $signed(e1) + $signed(e2) + $signed(e3) + $signed(e4);
        obs_total = $signed(o_pp0) + $signed(o_pp1) + $signed(o_pp2) + $signed(o_pp3) + $signed(o_pp4);

        $display("--------------------------------------------------");
        $display("[CASE] %s | t=%0t", name, $time);
        $display("  in   : x=%0d (0x%b), y=%0d (0x%b)", tx, tx, ty, ty);

        $display("  selE : s0=%03b(%s) s1=%03b(%s) s2=%03b(%s) s3=%03b(%s) s4=%03b(%s)",
                 s0, sel_name(s0),
                 s1, sel_name(s1),
                 s2, sel_name(s2),
                 s3, sel_name(s3),
                 s4, sel_name(s4));

        $display("  selO : s0=%03b(%s) s1=%03b(%s) s2=%03b(%s) s3=%03b(%s) s4=%03b(%s)",
                 dut.sel_0, sel_name(dut.sel_0),
                 dut.sel_1, sel_name(dut.sel_1),
                 dut.sel_2, sel_name(dut.sel_2),
                 dut.sel_3, sel_name(dut.sel_3),
                 dut.sel_4, sel_name(dut.sel_4));

        $display("  ppS_E: %0d %0d %0d %0d %0d | total=%0d",
                 e0, e1, e2, e3, e4, exp_total);

        $display("  ppS_O: %0d %0d %0d %0d %0d | total=%0d",
                 o_pp0, o_pp1, o_pp2, o_pp3, o_pp4, obs_total);
    end
    endtask

    task automatic run_capture_case(
        input logic signed [8:0] tx,
        input logic signed [8:0] ty,
        input string name
    );
        logic [2:0] g0, g1, g2, g3, g4;
        logic [2:0] s0, s1, s2, s3, s4;
        logic signed [17:0] u0, u1, u2, u3, u4;
        logic signed [17:0] e0, e1, e2, e3, e4;
    begin
        g0 = get_group(ty[8:0], 0);
        g1 = get_group(ty[8:0], 1);
        g2 = get_group(ty[8:0], 2);
        g3 = get_group(ty[8:0], 3);
        g4 = get_group(ty[8:0], 4);

        s0 = booth_sel(g0);
        s1 = booth_sel(g1);
        s2 = booth_sel(g2);
        s3 = booth_sel(g3);
        s4 = booth_sel(g4);

        u0 = pp_unshifted_ref(tx, s0);
        u1 = pp_unshifted_ref(tx, s1);
        u2 = pp_unshifted_ref(tx, s2);
        u3 = pp_unshifted_ref(tx, s3);
        u4 = pp_unshifted_ref(tx, s4);

        e0 = pp_shifted_ref(u0, 0);
        e1 = pp_shifted_ref(u1, 2);
        e2 = pp_shifted_ref(u2, 4);
        e3 = pp_shifted_ref(u3, 6);
        e4 = pp_shifted_ref(u4, 8);

        @(negedge i_clk);
        i_en = 1'b1;
        i_x  = tx;
        i_y  = ty[8:0];

        @(posedge i_clk);
        #1;

        print_case_detail(name, tx, ty, s0, s1, s2, s3, s4, e0, e1, e2, e3, e4);

        if ((dut.sel_0 !== s0) || (dut.sel_1 !== s1) || (dut.sel_2 !== s2) || (dut.sel_3 !== s3) || (dut.sel_4 !== s4) ||
            (dut.pp0_unshifted !== u0) || (dut.pp1_unshifted !== u1) || (dut.pp2_unshifted !== u2) || (dut.pp3_unshifted !== u3) || (dut.pp4_unshifted !== u4) ||
            (o_pp0 !== e0) || (o_pp1 !== e1) || (o_pp2 !== e2) || (o_pp3 !== e3) || (o_pp4 !== e4)) begin
            fail_count++;
            $display("[FAIL] %s", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s", name);
        end

        last_exp_pp0 = e0;
        last_exp_pp1 = e1;
        last_exp_pp2 = e2;
        last_exp_pp3 = e3;
        last_exp_pp4 = e4;
    end
    endtask

    task automatic run_hold_case(
        input logic signed [8:0] tx,
        input logic signed [8:0] ty,
        input string name
    );
        integer kept_total;
    begin
        @(negedge i_clk);
        i_en = 1'b0;
        i_x  = tx;
        i_y  = ty[8:0];

        @(posedge i_clk);
        #1;

        kept_total = $signed(o_pp0) + $signed(o_pp1) + $signed(o_pp2) + $signed(o_pp3) + $signed(o_pp4);

        $display("--------------------------------------------------");
        $display("[CASE] %s | t=%0t", name, $time);
        $display("  new_in : x=%0d (0x%b), y=%0d (0x%b)", tx, tx, ty, ty);
        $display("  hold_o : %0d %0d %0d %0d %0d | total=%0d",
                 o_pp0, o_pp1, o_pp2, o_pp3, o_pp4, kept_total);

        if ((o_pp0 !== last_exp_pp0) || (o_pp1 !== last_exp_pp1) || (o_pp2 !== last_exp_pp2) ||
            (o_pp3 !== last_exp_pp3) || (o_pp4 !== last_exp_pp4)) begin
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
        $display("  rst_o : %0d %0d %0d %0d %0d",
                 o_pp0, o_pp1, o_pp2, o_pp3, o_pp4);

        if ((o_pp0 !== 18'sd0) || (o_pp1 !== 18'sd0) || (o_pp2 !== 18'sd0) ||
            (o_pp3 !== 18'sd0) || (o_pp4 !== 18'sd0)) begin
            fail_count++;
            $display("[FAIL] %s", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s", name);
        end
    end
    endtask

    initial begin
        $shm_open("booth_shifted_product.shm");
        $shm_probe(tb_booth_shifted_product, "AS");
    end

    initial begin
        pass_count = 0;
        fail_count = 0;

        i_rst_n = 1'b1;
        i_en    = 1'b0;
        i_x     = 9'sd0;
        i_y     = 9'd0;

        // reset dau
        #2;
        i_rst_n = 1'b0;
        #1;
        check_reset_zero("RESET_INIT");

        @(negedge i_clk);
        i_rst_n = 1'b1;

        // case vua du de nhin select + pp shifted
        run_capture_case( 9'sd0,    9'sd0,   "CAP_ZERO");
        run_hold_case   ( 9'sd13,   9'sd7,   "HOLD_AFTER_ZERO");

        run_capture_case( 9'sd5,    9'sd1,   "CAP_POS_X");
        run_capture_case( 9'sd5,    9'sd2,   "CAP_NEG_2X_PATH");
        run_capture_case( 9'sd5,    9'sd3,   "CAP_NEG_X_PATH");
        run_capture_case( 9'sd5,    9'sd6,   "CAP_POS_2X_PATH");

        run_capture_case( 9'sd5,   -9'sd1,   "CAP_Y_NEG1");
        run_capture_case(-9'sd5,    9'sd6,   "CAP_X_NEG");
        run_capture_case( 9'sd37,   9'sd85,  "CAP_MIXED_POS");
        run_capture_case(-9'sd73,  -9'sd45,  "CAP_MIXED_NEG");

        run_hold_case   (-9'sd21,   9'sd19,  "HOLD_AFTER_NONZERO");

        // reset giua du lieu
        #2;
        i_rst_n = 1'b0;
        #1;
        check_reset_zero("RESET_MID");

        $display("========================================");
        $display("tb_booth_shifted_product DONE");
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
