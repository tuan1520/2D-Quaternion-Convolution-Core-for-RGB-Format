`timescale 1ns/1ps

module tb_tap_4lane;

    logic               i_clk;
    logic               i_rst_n;
    logic               i_en;

    logic        [23:0] i_pixel_data;
    logic signed [23:0] i_kernel_data;

    logic signed [17:0] o_y0;
    logic signed [17:0] o_y1;
    logic signed [17:0] o_y2;
    logic signed [17:0] o_y3;

    int pass_count;
    int fail_count;

    logic signed [17:0] last_exp_y0;
    logic signed [17:0] last_exp_y1;
    logic signed [17:0] last_exp_y2;
    logic signed [17:0] last_exp_y3;

    tap_4lane dut (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .i_en         (i_en),
        .i_pixel_data (i_pixel_data),
        .i_kernel_data(i_kernel_data),
        .o_y0         (o_y0),
        .o_y1         (o_y1),
        .o_y2         (o_y2),
        .o_y3         (o_y3)
    );

    //==================================================
    // clock
    //==================================================
    initial i_clk = 1'b0;
    always #5 i_clk = ~i_clk;

    //==================================================
    // helpers
    //==================================================
    function automatic logic [23:0] pack_pixel(
        input integer r,
        input integer g,
        input integer b
    );
        logic [7:0] r8, g8, b8;
    begin
        r8 = r[7:0];
        g8 = g[7:0];
        b8 = b[7:0];
        pack_pixel = {r8, g8, b8};
    end
    endfunction

    function automatic logic signed [23:0] pack_kernel(
        input integer p,
        input integer q,
        input integer s
    );
        logic signed [7:0] p8, q8, s8;
    begin
        p8 = p[7:0];
        q8 = q[7:0];
        s8 = s[7:0];
        pack_kernel = {p8, q8, s8};
    end
    endfunction

    function automatic logic signed [8:0] pixel_ch_9b(
        input integer c
    );
        logic [7:0] c8;
    begin
        c8 = c[7:0];
        pixel_ch_9b = {1'b0, c8};
    end
    endfunction

    function automatic logic signed [8:0] kernel_ch_9b(
        input integer c
    );
        logic signed [7:0] c8;
    begin
        c8 = c[7:0];
        kernel_ch_9b = {c8[7], c8};
    end
    endfunction

    function automatic logic signed [17:0] mul18_ref(
        input logic signed [8:0] x,
        input logic signed [8:0] y
    );
        integer signed tmp;
    begin
        tmp = x * y;
        mul18_ref = tmp[17:0];
    end
    endfunction

    task automatic print_capture_detail(
        input string name,
        input integer r,
        input integer g,
        input integer b,
        input integer p,
        input integer q,
        input integer s,
        input logic signed [17:0] rp,
        input logic signed [17:0] rq,
        input logic signed [17:0] rs,
        input logic signed [17:0] gp,
        input logic signed [17:0] gq,
        input logic signed [17:0] gs,
        input logic signed [17:0] bp,
        input logic signed [17:0] bq,
        input logic signed [17:0] bs,
        input logic signed [17:0] exp_y0,
        input logic signed [17:0] exp_y1,
        input logic signed [17:0] exp_y2,
        input logic signed [17:0] exp_y3
    );
    begin
        $display("--------------------------------------------------");
        $display("[CASE] %s | t=%0t", name, $time);
        $display("  in  : R=%0d G=%0d B=%0d | P=%0d Q=%0d S=%0d", r, g, b, p, q, s);
        $display("  mulE: RP=%0d RQ=%0d RS=%0d | GP=%0d GQ=%0d GS=%0d | BP=%0d BQ=%0d BS=%0d",
                 rp, rq, rs, gp, gq, gs, bp, bq, bs);
        $display("  yE  : y0=%0d y1=%0d y2=%0d y3=%0d", exp_y0, exp_y1, exp_y2, exp_y3);
        $display("  yO  : y0=%0d y1=%0d y2=%0d y3=%0d", o_y0, o_y1, o_y2, o_y3);
    end
    endtask

    task automatic run_capture_case(
        input integer r,
        input integer g,
        input integer b,
        input integer p,
        input integer q,
        input integer s,
        input string name
    );
        logic signed [8:0] r9, g9, b9;
        logic signed [8:0] p9, q9, s9;

        logic signed [17:0] rp, rq, rs;
        logic signed [17:0] gp, gq, gs;
        logic signed [17:0] bp, bq, bs;

        integer signed t_y0, t_y1, t_y2, t_y3;
        logic signed [17:0] exp_y0, exp_y1, exp_y2, exp_y3;
    begin
        r9 = pixel_ch_9b(r);
        g9 = pixel_ch_9b(g);
        b9 = pixel_ch_9b(b);

        p9 = kernel_ch_9b(p);
        q9 = kernel_ch_9b(q);
        s9 = kernel_ch_9b(s);

        rp = mul18_ref(r9, p9);
        rq = mul18_ref(r9, q9);
        rs = mul18_ref(r9, s9);

        gp = mul18_ref(g9, p9);
        gq = mul18_ref(g9, q9);
        gs = mul18_ref(g9, s9);

        bp = mul18_ref(b9, p9);
        bq = mul18_ref(b9, q9);
        bs = mul18_ref(b9, s9);

        t_y0 = -($signed(rp) + $signed(gq) + $signed(bs));
        t_y1 =  $signed(gs) - $signed(bq);
        t_y2 =  $signed(bp) - $signed(rs);
        t_y3 =  $signed(rq) - $signed(gp);

        exp_y0 = t_y0[17:0];
        exp_y1 = t_y1[17:0];
        exp_y2 = t_y2[17:0];
        exp_y3 = t_y3[17:0];

        @(negedge i_clk);
        i_en         = 1'b1;
        i_pixel_data = pack_pixel(r, g, b);
        i_kernel_data= pack_kernel(p, q, s);

        // latency tong cong = 3 cycle
        @(posedge i_clk);
        @(posedge i_clk);
        @(posedge i_clk);
        #1;

        print_capture_detail(name, r, g, b, p, q, s,
                             rp, rq, rs, gp, gq, gs, bp, bq, bs,
                             exp_y0, exp_y1, exp_y2, exp_y3);

        if ((o_y0 !== exp_y0) || (o_y1 !== exp_y1) ||
            (o_y2 !== exp_y2) || (o_y3 !== exp_y3)) begin
            fail_count++;
            $display("[FAIL] %s", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s", name);

            last_exp_y0 = exp_y0;
            last_exp_y1 = exp_y1;
            last_exp_y2 = exp_y2;
            last_exp_y3 = exp_y3;
        end
    end
    endtask

    task automatic run_hold_case(
        input integer r,
        input integer g,
        input integer b,
        input integer p,
        input integer q,
        input integer s,
        input string name
    );
    begin
        @(negedge i_clk);
        i_en         = 1'b0;
        i_pixel_data = pack_pixel(r, g, b);
        i_kernel_data= pack_kernel(p, q, s);

        @(posedge i_clk);
        @(posedge i_clk);
        @(posedge i_clk);
        #1;

        $display("--------------------------------------------------");
        $display("[CASE] %s | t=%0t", name, $time);
        $display("  new_in : R=%0d G=%0d B=%0d | P=%0d Q=%0d S=%0d", r, g, b, p, q, s);
        $display("  hold_o : y0=%0d y1=%0d y2=%0d y3=%0d", o_y0, o_y1, o_y2, o_y3);

        if ((o_y0 !== last_exp_y0) || (o_y1 !== last_exp_y1) ||
            (o_y2 !== last_exp_y2) || (o_y3 !== last_exp_y3)) begin
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
        $display("  rst_o : y0=%0d y1=%0d y2=%0d y3=%0d", o_y0, o_y1, o_y2, o_y3);

        if ((o_y0 !== 18'sd0) || (o_y1 !== 18'sd0) ||
            (o_y2 !== 18'sd0) || (o_y3 !== 18'sd0)) begin
            fail_count++;
            $display("[FAIL] %s", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s", name);

            last_exp_y0 = 18'sd0;
            last_exp_y1 = 18'sd0;
            last_exp_y2 = 18'sd0;
            last_exp_y3 = 18'sd0;
        end
    end
    endtask

    initial begin
        $shm_open("tap_4lane.shm");
        $shm_probe(tb_tap_4lane, "AS");
    end

    initial begin
        pass_count = 0;
        fail_count = 0;

        i_rst_n      = 1'b1;
        i_en         = 1'b0;
        i_pixel_data = 24'd0;
        i_kernel_data= 24'sd0;

        // reset dau
        #2;
        i_rst_n = 1'b0;
        #1;
        check_reset_zero("RESET_INIT");

        @(negedge i_clk);
        i_rst_n = 1'b1;

        // case co ban
        run_capture_case(0,   0,   0,    0,   0,   0,   "CAP_ZERO");
        run_hold_case   (1,   2,   3,    4,   5,   6,   "HOLD_AFTER_ZERO");

        run_capture_case(1,   2,   3,    4,   5,   6,   "CAP_ALL_POS_SMALL");
        run_capture_case(5,   7,   9,   -3,   2,  -1,   "CAP_MIXED_SIGN_1");
        run_capture_case(37, 85,  12,    7,  -9,  11,   "CAP_MIXED_SIGN_2");
        run_capture_case(255,128, 64,    1,  -1,   2,   "CAP_BOUNDARY_PIXEL");
        run_capture_case(10, 20,  30, -128, 127, -64,   "CAP_BOUNDARY_KERNEL");
        run_capture_case(255,255,255, 127,127,127,      "CAP_MAX_POS_COMBO");

        run_hold_case   (10, 20, 30,    40,  50,  60,   "HOLD_AFTER_NONZERO");

        // reset giua du lieu
        #2;
        i_rst_n = 1'b0;
        #1;
        check_reset_zero("RESET_MID");

        $display("========================================");
        $display("tb_tap_4lane DONE");
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