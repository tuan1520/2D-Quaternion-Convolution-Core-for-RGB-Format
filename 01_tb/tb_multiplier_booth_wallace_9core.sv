`timescale 1ns/1ps

module tb_multiplier_booth_wallace_9core;

    logic               i_clk;
    logic               i_rst_n;
    logic               i_en;

    logic signed [8:0]  i_r;
    logic signed [8:0]  i_g;
    logic signed [8:0]  i_b;

    logic signed [8:0]  i_p;
    logic signed [8:0]  i_q;
    logic signed [8:0]  i_s;

    logic signed [17:0] o_rp;
    logic signed [17:0] o_rq;
    logic signed [17:0] o_rs;
    logic signed [17:0] o_gp;
    logic signed [17:0] o_gq;
    logic signed [17:0] o_gs;
    logic signed [17:0] o_bp;
    logic signed [17:0] o_bq;
    logic signed [17:0] o_bs;

    int pass_count;
    int fail_count;

    logic signed [17:0] last_exp_rp;
    logic signed [17:0] last_exp_rq;
    logic signed [17:0] last_exp_rs;
    logic signed [17:0] last_exp_gp;
    logic signed [17:0] last_exp_gq;
    logic signed [17:0] last_exp_gs;
    logic signed [17:0] last_exp_bp;
    logic signed [17:0] last_exp_bq;
    logic signed [17:0] last_exp_bs;

    multiplier_booth_wallace_9core dut (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (i_en),

        .i_r(i_r),
        .i_g(i_g),
        .i_b(i_b),

        .i_p(i_p),
        .i_q(i_q),
        .i_s(i_s),

        .o_rp(o_rp),
        .o_rq(o_rq),
        .o_rs(o_rs),
        .o_gp(o_gp),
        .o_gq(o_gq),
        .o_gs(o_gs),
        .o_bp(o_bp),
        .o_bq(o_bq),
        .o_bs(o_bs)
    );

    //==================================================
    // clock
    //==================================================
    initial i_clk = 1'b0;
    always #5 i_clk = ~i_clk;

    //==================================================
    // helpers
    //==================================================
    function automatic logic signed [17:0] mul9x9_ref(
        input logic signed [8:0] x,
        input logic signed [8:0] y
    );
        integer signed tmp;
    begin
        tmp = x * y;
        mul9x9_ref = tmp[17:0];
    end
    endfunction

    task automatic print_capture_detail(
        input string name,
        input logic signed [8:0] r,
        input logic signed [8:0] g,
        input logic signed [8:0] b,
        input logic signed [8:0] p,
        input logic signed [8:0] q,
        input logic signed [8:0] s,

        input logic signed [17:0] exp_rp,
        input logic signed [17:0] exp_rq,
        input logic signed [17:0] exp_rs,
        input logic signed [17:0] exp_gp,
        input logic signed [17:0] exp_gq,
        input logic signed [17:0] exp_gs,
        input logic signed [17:0] exp_bp,
        input logic signed [17:0] exp_bq,
        input logic signed [17:0] exp_bs
    );
    begin
        $display("--------------------------------------------------");
        $display("[CASE] %s | t=%0t", name, $time);
        $display("  in  : R=%0d G=%0d B=%0d | P=%0d Q=%0d S=%0d", r, g, b, p, q, s);

        $display("  exp : RP=%0d RQ=%0d RS=%0d | GP=%0d GQ=%0d GS=%0d | BP=%0d BQ=%0d BS=%0d",
                 exp_rp, exp_rq, exp_rs, exp_gp, exp_gq, exp_gs, exp_bp, exp_bq, exp_bs);

        $display("  obs : RP=%0d RQ=%0d RS=%0d | GP=%0d GQ=%0d GS=%0d | BP=%0d BQ=%0d BS=%0d",
                 o_rp, o_rq, o_rs, o_gp, o_gq, o_gs, o_bp, o_bq, o_bs);
    end
    endtask

    task automatic run_capture_case(
        input logic signed [8:0] r,
        input logic signed [8:0] g,
        input logic signed [8:0] b,
        input logic signed [8:0] p,
        input logic signed [8:0] q,
        input logic signed [8:0] s,
        input string name
    );
        logic signed [17:0] exp_rp;
        logic signed [17:0] exp_rq;
        logic signed [17:0] exp_rs;
        logic signed [17:0] exp_gp;
        logic signed [17:0] exp_gq;
        logic signed [17:0] exp_gs;
        logic signed [17:0] exp_bp;
        logic signed [17:0] exp_bq;
        logic signed [17:0] exp_bs;
    begin
        exp_rp = mul9x9_ref(r, p);
        exp_rq = mul9x9_ref(r, q);
        exp_rs = mul9x9_ref(r, s);

        exp_gp = mul9x9_ref(g, p);
        exp_gq = mul9x9_ref(g, q);
        exp_gs = mul9x9_ref(g, s);

        exp_bp = mul9x9_ref(b, p);
        exp_bq = mul9x9_ref(b, q);
        exp_bs = mul9x9_ref(b, s);

        @(negedge i_clk);
        i_en = 1'b1;
        i_r  = r;
        i_g  = g;
        i_b  = b;
        i_p  = p;
        i_q  = q;
        i_s  = s;

        // latency 2 cycle
        @(posedge i_clk);
        @(posedge i_clk);
        #1;

        print_capture_detail(name, r, g, b, p, q, s,
                             exp_rp, exp_rq, exp_rs,
                             exp_gp, exp_gq, exp_gs,
                             exp_bp, exp_bq, exp_bs);

        if ((o_rp !== exp_rp) || (o_rq !== exp_rq) || (o_rs !== exp_rs) ||
            (o_gp !== exp_gp) || (o_gq !== exp_gq) || (o_gs !== exp_gs) ||
            (o_bp !== exp_bp) || (o_bq !== exp_bq) || (o_bs !== exp_bs)) begin
            fail_count++;
            $display("[FAIL] %s", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s", name);

            last_exp_rp = exp_rp;
            last_exp_rq = exp_rq;
            last_exp_rs = exp_rs;
            last_exp_gp = exp_gp;
            last_exp_gq = exp_gq;
            last_exp_gs = exp_gs;
            last_exp_bp = exp_bp;
            last_exp_bq = exp_bq;
            last_exp_bs = exp_bs;
        end
    end
    endtask

    task automatic run_hold_case(
        input logic signed [8:0] r,
        input logic signed [8:0] g,
        input logic signed [8:0] b,
        input logic signed [8:0] p,
        input logic signed [8:0] q,
        input logic signed [8:0] s,
        input string name
    );
    begin
        @(negedge i_clk);
        i_en = 1'b0;
        i_r  = r;
        i_g  = g;
        i_b  = b;
        i_p  = p;
        i_q  = q;
        i_s  = s;

        @(posedge i_clk);
        @(posedge i_clk);
        #1;

        $display("--------------------------------------------------");
        $display("[CASE] %s | t=%0t", name, $time);
        $display("  new_in : R=%0d G=%0d B=%0d | P=%0d Q=%0d S=%0d", r, g, b, p, q, s);
        $display("  hold_o : RP=%0d RQ=%0d RS=%0d | GP=%0d GQ=%0d GS=%0d | BP=%0d BQ=%0d BS=%0d",
                 o_rp, o_rq, o_rs, o_gp, o_gq, o_gs, o_bp, o_bq, o_bs);

        if ((o_rp !== last_exp_rp) || (o_rq !== last_exp_rq) || (o_rs !== last_exp_rs) ||
            (o_gp !== last_exp_gp) || (o_gq !== last_exp_gq) || (o_gs !== last_exp_gs) ||
            (o_bp !== last_exp_bp) || (o_bq !== last_exp_bq) || (o_bs !== last_exp_bs)) begin
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
        $display("  rst_o : RP=%0d RQ=%0d RS=%0d | GP=%0d GQ=%0d GS=%0d | BP=%0d BQ=%0d BS=%0d",
                 o_rp, o_rq, o_rs, o_gp, o_gq, o_gs, o_bp, o_bq, o_bs);

        if ((o_rp !== 18'sd0) || (o_rq !== 18'sd0) || (o_rs !== 18'sd0) ||
            (o_gp !== 18'sd0) || (o_gq !== 18'sd0) || (o_gs !== 18'sd0) ||
            (o_bp !== 18'sd0) || (o_bq !== 18'sd0) || (o_bs !== 18'sd0)) begin
            fail_count++;
            $display("[FAIL] %s", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s", name);

            last_exp_rp = 18'sd0;
            last_exp_rq = 18'sd0;
            last_exp_rs = 18'sd0;
            last_exp_gp = 18'sd0;
            last_exp_gq = 18'sd0;
            last_exp_gs = 18'sd0;
            last_exp_bp = 18'sd0;
            last_exp_bq = 18'sd0;
            last_exp_bs = 18'sd0;
        end
    end
    endtask

    initial begin
        $shm_open("multiplier_booth_wallace_9core.shm");
        $shm_probe(tb_multiplier_booth_wallace_9core, "AS");
    end

    initial begin
        pass_count = 0;
        fail_count = 0;

        i_rst_n = 1'b1;
        i_en    = 1'b0;

        i_r = 9'sd0;
        i_g = 9'sd0;
        i_b = 9'sd0;
        i_p = 9'sd0;
        i_q = 9'sd0;
        i_s = 9'sd0;

        // reset dau
        #2;
        i_rst_n = 1'b0;
        #1;
        check_reset_zero("RESET_INIT");

        @(negedge i_clk);
        i_rst_n = 1'b1;

        // case co ban
        run_capture_case( 9'sd0,    9'sd0,    9'sd0,    9'sd0,    9'sd0,    9'sd0,    "CAP_ZERO");
        run_hold_case   ( 9'sd1,    9'sd2,    9'sd3,    9'sd4,    9'sd5,    9'sd6,    "HOLD_AFTER_ZERO");

        run_capture_case( 9'sd1,    9'sd2,    9'sd3,    9'sd4,    9'sd5,    9'sd6,    "CAP_ALL_POS_SMALL");
        run_capture_case(-9'sd1,    9'sd2,   -9'sd3,    9'sd4,   -9'sd5,    9'sd6,    "CAP_ALT_SIGN_1");
        run_capture_case( 9'sd5,   -9'sd7,    9'sd9,   -9'sd3,    9'sd2,   -9'sd1,    "CAP_ALT_SIGN_2");

        run_capture_case( 9'sd37,   9'sd85,  -9'sd12,   9'sd7,   -9'sd9,   9'sd11,    "CAP_MIXED_1");
        run_capture_case(-9'sd73,  -9'sd45,   9'sd18,  -9'sd6,    9'sd13,  -9'sd4,    "CAP_MIXED_2");

        run_capture_case( 9'sd255,  9'sd128, -9'sd256,  9'sd1,   -9'sd1,    9'sd2,    "CAP_BOUNDARY_1");
        run_capture_case(-9'sd256,  9'sd255,  9'sd127, -9'sd1,    9'sd2,   -9'sd2,    "CAP_BOUNDARY_2");

        run_hold_case   ( 9'sd10,   9'sd20,   9'sd30,   9'sd40,   9'sd50,   9'sd60,   "HOLD_AFTER_NONZERO");

        // reset giua du lieu
        #2;
        i_rst_n = 1'b0;
        #1;
        check_reset_zero("RESET_MID");

        $display("========================================");
        $display("tb_multiplier_booth_wallace_9core DONE");
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