`timescale 1ns/1ps

module tb_tap_3x3_4lane;

    logic               i_clk;
    logic               i_rst_n;
    logic               i_en;

    logic [23:0]        i_w00, i_w01, i_w02;
    logic [23:0]        i_w10, i_w11, i_w12;
    logic [23:0]        i_w20, i_w21, i_w22;

    logic signed [23:0] i_k00, i_k01, i_k02;
    logic signed [23:0] i_k10, i_k11, i_k12;
    logic signed [23:0] i_k20, i_k21, i_k22;

    logic signed [17:0] o_y00, o_y01, o_y02, o_y03;
    logic signed [17:0] o_y10, o_y11, o_y12, o_y13;
    logic signed [17:0] o_y20, o_y21, o_y22, o_y23;
    logic signed [17:0] o_y30, o_y31, o_y32, o_y33;
    logic signed [17:0] o_y40, o_y41, o_y42, o_y43;
    logic signed [17:0] o_y50, o_y51, o_y52, o_y53;
    logic signed [17:0] o_y60, o_y61, o_y62, o_y63;
    logic signed [17:0] o_y70, o_y71, o_y72, o_y73;
    logic signed [17:0] o_y80, o_y81, o_y82, o_y83;

    int pass_count;
    int fail_count;

    logic signed [17:0] last_exp_y00, last_exp_y01, last_exp_y02, last_exp_y03;
    logic signed [17:0] last_exp_y10, last_exp_y11, last_exp_y12, last_exp_y13;
    logic signed [17:0] last_exp_y20, last_exp_y21, last_exp_y22, last_exp_y23;
    logic signed [17:0] last_exp_y30, last_exp_y31, last_exp_y32, last_exp_y33;
    logic signed [17:0] last_exp_y40, last_exp_y41, last_exp_y42, last_exp_y43;
    logic signed [17:0] last_exp_y50, last_exp_y51, last_exp_y52, last_exp_y53;
    logic signed [17:0] last_exp_y60, last_exp_y61, last_exp_y62, last_exp_y63;
    logic signed [17:0] last_exp_y70, last_exp_y71, last_exp_y72, last_exp_y73;
    logic signed [17:0] last_exp_y80, last_exp_y81, last_exp_y82, last_exp_y83;

    tap_3x3_4lane dut (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (i_en),

        .i_w00(i_w00), .i_w01(i_w01), .i_w02(i_w02),
        .i_w10(i_w10), .i_w11(i_w11), .i_w12(i_w12),
        .i_w20(i_w20), .i_w21(i_w21), .i_w22(i_w22),

        .i_k00(i_k00), .i_k01(i_k01), .i_k02(i_k02),
        .i_k10(i_k10), .i_k11(i_k11), .i_k12(i_k12),
        .i_k20(i_k20), .i_k21(i_k21), .i_k22(i_k22),

        .o_y00(o_y00), .o_y01(o_y01), .o_y02(o_y02), .o_y03(o_y03),
        .o_y10(o_y10), .o_y11(o_y11), .o_y12(o_y12), .o_y13(o_y13),
        .o_y20(o_y20), .o_y21(o_y21), .o_y22(o_y22), .o_y23(o_y23),
        .o_y30(o_y30), .o_y31(o_y31), .o_y32(o_y32), .o_y33(o_y33),
        .o_y40(o_y40), .o_y41(o_y41), .o_y42(o_y42), .o_y43(o_y43),
        .o_y50(o_y50), .o_y51(o_y51), .o_y52(o_y52), .o_y53(o_y53),
        .o_y60(o_y60), .o_y61(o_y61), .o_y62(o_y62), .o_y63(o_y63),
        .o_y70(o_y70), .o_y71(o_y71), .o_y72(o_y72), .o_y73(o_y73),
        .o_y80(o_y80), .o_y81(o_y81), .o_y82(o_y82), .o_y83(o_y83)
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

    task automatic calc_tap_expected(
        input  integer r,
        input  integer g,
        input  integer b,
        input  integer p,
        input  integer q,
        input  integer s,
        output logic signed [17:0] ey0,
        output logic signed [17:0] ey1,
        output logic signed [17:0] ey2,
        output logic signed [17:0] ey3
    );
        logic signed [8:0] r9, g9, b9;
        logic signed [8:0] p9, q9, s9;

        logic signed [17:0] rp, rq, rs;
        logic signed [17:0] gp, gq, gs;
        logic signed [17:0] bp, bq, bs;

        integer signed ty0, ty1, ty2, ty3;
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

        ty0 = -($signed(rp) + $signed(gq) + $signed(bs));
        ty1 =  $signed(gs) - $signed(bq);
        ty2 =  $signed(bp) - $signed(rs);
        ty3 =  $signed(rq) - $signed(gp);

        ey0 = ty0[17:0];
        ey1 = ty1[17:0];
        ey2 = ty2[17:0];
        ey3 = ty3[17:0];
    end
    endtask

    task automatic print_capture_detail(
        input string name
    );
    begin
        $display("--------------------------------------------------");
        $display("[CASE] %s | t=%0t", name, $time);

        $display("  obs0 : %0d %0d %0d %0d", o_y00, o_y01, o_y02, o_y03);
        $display("  obs1 : %0d %0d %0d %0d", o_y10, o_y11, o_y12, o_y13);
        $display("  obs2 : %0d %0d %0d %0d", o_y20, o_y21, o_y22, o_y23);
        $display("  obs3 : %0d %0d %0d %0d", o_y30, o_y31, o_y32, o_y33);
        $display("  obs4 : %0d %0d %0d %0d", o_y40, o_y41, o_y42, o_y43);
        $display("  obs5 : %0d %0d %0d %0d", o_y50, o_y51, o_y52, o_y53);
        $display("  obs6 : %0d %0d %0d %0d", o_y60, o_y61, o_y62, o_y63);
        $display("  obs7 : %0d %0d %0d %0d", o_y70, o_y71, o_y72, o_y73);
        $display("  obs8 : %0d %0d %0d %0d", o_y80, o_y81, o_y82, o_y83);
    end
    endtask

    task automatic load_case_1;
    begin
        i_w00 = pack_pixel(  1,  2,  3);  i_k00 = pack_kernel(   4,   5,   6);
        i_w01 = pack_pixel(  5,  7,  9);  i_k01 = pack_kernel(  -3,   2,  -1);
        i_w02 = pack_pixel( 37, 85, 12);  i_k02 = pack_kernel(   7,  -9,  11);

        i_w10 = pack_pixel(255,128, 64);  i_k10 = pack_kernel(   1,  -1,   2);
        i_w11 = pack_pixel( 10, 20, 30);  i_k11 = pack_kernel(-128, 127, -64);
        i_w12 = pack_pixel(255,255,255);  i_k12 = pack_kernel( 127, 127, 127);

        i_w20 = pack_pixel(  0,  0,  0);  i_k20 = pack_kernel(   0,   0,   0);
        i_w21 = pack_pixel(  3,  4,  5);  i_k21 = pack_kernel(   6,   7,   8);
        i_w22 = pack_pixel(  9, 10, 11);  i_k22 = pack_kernel(  -2,   3,  -4);
    end
    endtask

    task automatic load_case_2;
    begin
        i_w00 = pack_pixel( 12, 34, 56);  i_k00 = pack_kernel(   7,  -8,   9);
        i_w01 = pack_pixel( 90, 45, 12);  i_k01 = pack_kernel(  -5,   4,  -3);
        i_w02 = pack_pixel(200,100, 50);  i_k02 = pack_kernel(   1,   2,   3);

        i_w10 = pack_pixel(  8, 16, 24);  i_k10 = pack_kernel( -10,  20, -30);
        i_w11 = pack_pixel(  7, 14, 21);  i_k11 = pack_kernel(  11, -12,  13);
        i_w12 = pack_pixel(  6, 12, 18);  i_k12 = pack_kernel(  -9,   8,  -7);

        i_w20 = pack_pixel(  5, 10, 15);  i_k20 = pack_kernel(   6,  -5,   4);
        i_w21 = pack_pixel(  4,  8, 12);  i_k21 = pack_kernel(  -3,   2,  -1);
        i_w22 = pack_pixel(  3,  6,  9);  i_k22 = pack_kernel(   1,  -2,   3);
    end
    endtask

    task automatic run_capture_case(
        input string name,
        input int case_id
    );
        logic signed [17:0] ey00, ey01, ey02, ey03;
        logic signed [17:0] ey10, ey11, ey12, ey13;
        logic signed [17:0] ey20, ey21, ey22, ey23;
        logic signed [17:0] ey30, ey31, ey32, ey33;
        logic signed [17:0] ey40, ey41, ey42, ey43;
        logic signed [17:0] ey50, ey51, ey52, ey53;
        logic signed [17:0] ey60, ey61, ey62, ey63;
        logic signed [17:0] ey70, ey71, ey72, ey73;
        logic signed [17:0] ey80, ey81, ey82, ey83;
    begin
        @(negedge i_clk);
        i_en = 1'b1;
        case (case_id)
            1: load_case_1();
            2: load_case_2();
            default: begin
                i_w00 = 24'd0; i_w01 = 24'd0; i_w02 = 24'd0;
                i_w10 = 24'd0; i_w11 = 24'd0; i_w12 = 24'd0;
                i_w20 = 24'd0; i_w21 = 24'd0; i_w22 = 24'd0;

                i_k00 = 24'sd0; i_k01 = 24'sd0; i_k02 = 24'sd0;
                i_k10 = 24'sd0; i_k11 = 24'sd0; i_k12 = 24'sd0;
                i_k20 = 24'sd0; i_k21 = 24'sd0; i_k22 = 24'sd0;
            end
        endcase

        // expected for case 1
        if (case_id == 1) begin
            calc_tap_expected(  1,  2,  3,    4,   5,   6,   ey00, ey01, ey02, ey03);
            calc_tap_expected(  5,  7,  9,   -3,   2,  -1,   ey10, ey11, ey12, ey13);
            calc_tap_expected( 37, 85, 12,    7,  -9,  11,   ey20, ey21, ey22, ey23);

            calc_tap_expected(255,128, 64,    1,  -1,   2,   ey30, ey31, ey32, ey33);
            calc_tap_expected( 10, 20, 30, -128, 127, -64,   ey40, ey41, ey42, ey43);
            calc_tap_expected(255,255,255, 127, 127, 127,    ey50, ey51, ey52, ey53);

            calc_tap_expected(  0,  0,  0,    0,   0,   0,   ey60, ey61, ey62, ey63);
            calc_tap_expected(  3,  4,  5,    6,   7,   8,   ey70, ey71, ey72, ey73);
            calc_tap_expected(  9, 10, 11,   -2,   3,  -4,   ey80, ey81, ey82, ey83);
        end
        else begin
            calc_tap_expected( 12, 34, 56,    7,  -8,   9,   ey00, ey01, ey02, ey03);
            calc_tap_expected( 90, 45, 12,   -5,   4,  -3,   ey10, ey11, ey12, ey13);
            calc_tap_expected(200,100, 50,    1,   2,   3,   ey20, ey21, ey22, ey23);

            calc_tap_expected(  8, 16, 24,  -10,  20, -30,   ey30, ey31, ey32, ey33);
            calc_tap_expected(  7, 14, 21,   11, -12,  13,   ey40, ey41, ey42, ey43);
            calc_tap_expected(  6, 12, 18,   -9,   8,  -7,   ey50, ey51, ey52, ey53);

            calc_tap_expected(  5, 10, 15,    6,  -5,   4,   ey60, ey61, ey62, ey63);
            calc_tap_expected(  4,  8, 12,   -3,   2,  -1,   ey70, ey71, ey72, ey73);
            calc_tap_expected(  3,  6,  9,    1,  -2,   3,   ey80, ey81, ey82, ey83);
        end

        // latency tong cong = 3 cycle
        @(posedge i_clk);
        @(posedge i_clk);
        @(posedge i_clk);
        #1;

        print_capture_detail(name);

        if ((o_y00 !== ey00) || (o_y01 !== ey01) || (o_y02 !== ey02) || (o_y03 !== ey03) ||
            (o_y10 !== ey10) || (o_y11 !== ey11) || (o_y12 !== ey12) || (o_y13 !== ey13) ||
            (o_y20 !== ey20) || (o_y21 !== ey21) || (o_y22 !== ey22) || (o_y23 !== ey23) ||
            (o_y30 !== ey30) || (o_y31 !== ey31) || (o_y32 !== ey32) || (o_y33 !== ey33) ||
            (o_y40 !== ey40) || (o_y41 !== ey41) || (o_y42 !== ey42) || (o_y43 !== ey43) ||
            (o_y50 !== ey50) || (o_y51 !== ey51) || (o_y52 !== ey52) || (o_y53 !== ey53) ||
            (o_y60 !== ey60) || (o_y61 !== ey61) || (o_y62 !== ey62) || (o_y63 !== ey63) ||
            (o_y70 !== ey70) || (o_y71 !== ey71) || (o_y72 !== ey72) || (o_y73 !== ey73) ||
            (o_y80 !== ey80) || (o_y81 !== ey81) || (o_y82 !== ey82) || (o_y83 !== ey83)) begin
            fail_count++;
            $display("[FAIL] %s", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s", name);

            last_exp_y00 = ey00; last_exp_y01 = ey01; last_exp_y02 = ey02; last_exp_y03 = ey03;
            last_exp_y10 = ey10; last_exp_y11 = ey11; last_exp_y12 = ey12; last_exp_y13 = ey13;
            last_exp_y20 = ey20; last_exp_y21 = ey21; last_exp_y22 = ey22; last_exp_y23 = ey23;
            last_exp_y30 = ey30; last_exp_y31 = ey31; last_exp_y32 = ey32; last_exp_y33 = ey33;
            last_exp_y40 = ey40; last_exp_y41 = ey41; last_exp_y42 = ey42; last_exp_y43 = ey43;
            last_exp_y50 = ey50; last_exp_y51 = ey51; last_exp_y52 = ey52; last_exp_y53 = ey53;
            last_exp_y60 = ey60; last_exp_y61 = ey61; last_exp_y62 = ey62; last_exp_y63 = ey63;
            last_exp_y70 = ey70; last_exp_y71 = ey71; last_exp_y72 = ey72; last_exp_y73 = ey73;
            last_exp_y80 = ey80; last_exp_y81 = ey81; last_exp_y82 = ey82; last_exp_y83 = ey83;
        end
    end
    endtask

    task automatic run_hold_case(
        input string name,
        input int case_id
    );
    begin
        @(negedge i_clk);
        i_en = 1'b0;
        case (case_id)
            1: load_case_1();
            2: load_case_2();
            default: begin end
        endcase

        @(posedge i_clk);
        @(posedge i_clk);
        @(posedge i_clk);
        #1;

        $display("--------------------------------------------------");
        $display("[CASE] %s | t=%0t", name, $time);
        $display("  hold0 : %0d %0d %0d %0d", o_y00, o_y01, o_y02, o_y03);
        $display("  hold1 : %0d %0d %0d %0d", o_y10, o_y11, o_y12, o_y13);
        $display("  hold2 : %0d %0d %0d %0d", o_y20, o_y21, o_y22, o_y23);
        $display("  hold3 : %0d %0d %0d %0d", o_y30, o_y31, o_y32, o_y33);
        $display("  hold4 : %0d %0d %0d %0d", o_y40, o_y41, o_y42, o_y43);
        $display("  hold5 : %0d %0d %0d %0d", o_y50, o_y51, o_y52, o_y53);
        $display("  hold6 : %0d %0d %0d %0d", o_y60, o_y61, o_y62, o_y63);
        $display("  hold7 : %0d %0d %0d %0d", o_y70, o_y71, o_y72, o_y73);
        $display("  hold8 : %0d %0d %0d %0d", o_y80, o_y81, o_y82, o_y83);

        if ((o_y00 !== last_exp_y00) || (o_y01 !== last_exp_y01) || (o_y02 !== last_exp_y02) || (o_y03 !== last_exp_y03) ||
            (o_y10 !== last_exp_y10) || (o_y11 !== last_exp_y11) || (o_y12 !== last_exp_y12) || (o_y13 !== last_exp_y13) ||
            (o_y20 !== last_exp_y20) || (o_y21 !== last_exp_y21) || (o_y22 !== last_exp_y22) || (o_y23 !== last_exp_y23) ||
            (o_y30 !== last_exp_y30) || (o_y31 !== last_exp_y31) || (o_y32 !== last_exp_y32) || (o_y33 !== last_exp_y33) ||
            (o_y40 !== last_exp_y40) || (o_y41 !== last_exp_y41) || (o_y42 !== last_exp_y42) || (o_y43 !== last_exp_y43) ||
            (o_y50 !== last_exp_y50) || (o_y51 !== last_exp_y51) || (o_y52 !== last_exp_y52) || (o_y53 !== last_exp_y53) ||
            (o_y60 !== last_exp_y60) || (o_y61 !== last_exp_y61) || (o_y62 !== last_exp_y62) || (o_y63 !== last_exp_y63) ||
            (o_y70 !== last_exp_y70) || (o_y71 !== last_exp_y71) || (o_y72 !== last_exp_y72) || (o_y73 !== last_exp_y73) ||
            (o_y80 !== last_exp_y80) || (o_y81 !== last_exp_y81) || (o_y82 !== last_exp_y82) || (o_y83 !== last_exp_y83)) begin
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
        $display("  rst0 : %0d %0d %0d %0d", o_y00, o_y01, o_y02, o_y03);
        $display("  rst1 : %0d %0d %0d %0d", o_y10, o_y11, o_y12, o_y13);
        $display("  rst2 : %0d %0d %0d %0d", o_y20, o_y21, o_y22, o_y23);
        $display("  rst3 : %0d %0d %0d %0d", o_y30, o_y31, o_y32, o_y33);
        $display("  rst4 : %0d %0d %0d %0d", o_y40, o_y41, o_y42, o_y43);
        $display("  rst5 : %0d %0d %0d %0d", o_y50, o_y51, o_y52, o_y53);
        $display("  rst6 : %0d %0d %0d %0d", o_y60, o_y61, o_y62, o_y63);
        $display("  rst7 : %0d %0d %0d %0d", o_y70, o_y71, o_y72, o_y73);
        $display("  rst8 : %0d %0d %0d %0d", o_y80, o_y81, o_y82, o_y83);

        if ((o_y00 !== 18'sd0) || (o_y01 !== 18'sd0) || (o_y02 !== 18'sd0) || (o_y03 !== 18'sd0) ||
            (o_y10 !== 18'sd0) || (o_y11 !== 18'sd0) || (o_y12 !== 18'sd0) || (o_y13 !== 18'sd0) ||
            (o_y20 !== 18'sd0) || (o_y21 !== 18'sd0) || (o_y22 !== 18'sd0) || (o_y23 !== 18'sd0) ||
            (o_y30 !== 18'sd0) || (o_y31 !== 18'sd0) || (o_y32 !== 18'sd0) || (o_y33 !== 18'sd0) ||
            (o_y40 !== 18'sd0) || (o_y41 !== 18'sd0) || (o_y42 !== 18'sd0) || (o_y43 !== 18'sd0) ||
            (o_y50 !== 18'sd0) || (o_y51 !== 18'sd0) || (o_y52 !== 18'sd0) || (o_y53 !== 18'sd0) ||
            (o_y60 !== 18'sd0) || (o_y61 !== 18'sd0) || (o_y62 !== 18'sd0) || (o_y63 !== 18'sd0) ||
            (o_y70 !== 18'sd0) || (o_y71 !== 18'sd0) || (o_y72 !== 18'sd0) || (o_y73 !== 18'sd0) ||
            (o_y80 !== 18'sd0) || (o_y81 !== 18'sd0) || (o_y82 !== 18'sd0) || (o_y83 !== 18'sd0)) begin
            fail_count++;
            $display("[FAIL] %s", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s", name);

            last_exp_y00 = 18'sd0; last_exp_y01 = 18'sd0; last_exp_y02 = 18'sd0; last_exp_y03 = 18'sd0;
            last_exp_y10 = 18'sd0; last_exp_y11 = 18'sd0; last_exp_y12 = 18'sd0; last_exp_y13 = 18'sd0;
            last_exp_y20 = 18'sd0; last_exp_y21 = 18'sd0; last_exp_y22 = 18'sd0; last_exp_y23 = 18'sd0;
            last_exp_y30 = 18'sd0; last_exp_y31 = 18'sd0; last_exp_y32 = 18'sd0; last_exp_y33 = 18'sd0;
            last_exp_y40 = 18'sd0; last_exp_y41 = 18'sd0; last_exp_y42 = 18'sd0; last_exp_y43 = 18'sd0;
            last_exp_y50 = 18'sd0; last_exp_y51 = 18'sd0; last_exp_y52 = 18'sd0; last_exp_y53 = 18'sd0;
            last_exp_y60 = 18'sd0; last_exp_y61 = 18'sd0; last_exp_y62 = 18'sd0; last_exp_y63 = 18'sd0;
            last_exp_y70 = 18'sd0; last_exp_y71 = 18'sd0; last_exp_y72 = 18'sd0; last_exp_y73 = 18'sd0;
            last_exp_y80 = 18'sd0; last_exp_y81 = 18'sd0; last_exp_y82 = 18'sd0; last_exp_y83 = 18'sd0;
        end
    end
    endtask

    initial begin
        $shm_open("tap_3x3_4lane.shm");
        $shm_probe(tb_tap_3x3_4lane, "AS");
    end

    initial begin
        pass_count = 0;
        fail_count = 0;

        i_rst_n = 1'b1;
        i_en    = 1'b0;

        i_w00 = 24'd0; i_w01 = 24'd0; i_w02 = 24'd0;
        i_w10 = 24'd0; i_w11 = 24'd0; i_w12 = 24'd0;
        i_w20 = 24'd0; i_w21 = 24'd0; i_w22 = 24'd0;

        i_k00 = 24'sd0; i_k01 = 24'sd0; i_k02 = 24'sd0;
        i_k10 = 24'sd0; i_k11 = 24'sd0; i_k12 = 24'sd0;
        i_k20 = 24'sd0; i_k21 = 24'sd0; i_k22 = 24'sd0;

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
        $display("tb_tap_3x3_4lane DONE");
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