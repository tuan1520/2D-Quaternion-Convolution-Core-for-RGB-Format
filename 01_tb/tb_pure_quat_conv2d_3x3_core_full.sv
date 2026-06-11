`timescale 1ns/1ps

module tb_pure_quat_conv2d_3x3_core_full;

    localparam int IMG_W = 64;
    localparam int IMG_H = 64;
    localparam int LINE_LENGTH = 64;
    localparam int TOTAL_PIPE_LAT = 7;

    localparam int FRAME_PIXELS = IMG_W * IMG_H;

    localparam int FIRST_TAP_REQ_ACCEPTED = 132;
    localparam int FIRST_OUT_ACCEPTED     = 139;

    // Cho du margin de last pixel duoc fire + pipeline flush + ST_DONE
    localparam int FRAME_DONE_TIMEOUT = FRAME_PIXELS + 500;

    logic               i_clk;
    logic               i_rst_n;

    logic               i_start;
    logic               i_next_frame;

    logic               i_tb_pixel_valid;
    logic [23:0]        i_tb_pixel;
    logic               o_tb_pixel_ready;

    logic               i_ker_cfg_valid;
    logic [3:0]         i_ker_cfg_idx;
    logic [23:0]        i_ker_input;
    logic               o_ker_done;
    logic               o_frame_done;

    logic signed [23:0] o_out_s;
    logic signed [23:0] o_out_i;
    logic signed [23:0] o_out_j;
    logic signed [23:0] o_out_k;

    logic               o_out_valid;
    logic               o_out_latch;
    logic               o_out_empty;

    int pass_count;
    int fail_count;

    int accepted_pixel_count;
    int pixel_id;

    int out_valid_count;

    logic send_this_cycle;
    logic first_tap_req_seen;
    logic first_out_seen;
    logic frame_done_seen;

    int req_accepted;
    int req_x;
    int req_y;

    int out_accepted;

    pure_quat_conv2d_3x3_core #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H),
        .LINE_LENGTH(LINE_LENGTH),
        .TOTAL_PIPE_LAT(TOTAL_PIPE_LAT)
    ) dut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_start(i_start),
        .i_next_frame(i_next_frame),

        .i_tb_pixel_valid(i_tb_pixel_valid),
        .i_tb_pixel(i_tb_pixel),
        .o_tb_pixel_ready(o_tb_pixel_ready),

        .i_ker_cfg_valid(i_ker_cfg_valid),
        .i_ker_cfg_idx(i_ker_cfg_idx),
        .i_ker_input(i_ker_input),
        .o_ker_done(o_ker_done),
        .o_frame_done(o_frame_done),

        .o_out_s(o_out_s),
        .o_out_i(o_out_i),
        .o_out_j(o_out_j),
        .o_out_k(o_out_k),

        .o_out_valid(o_out_valid),
        .o_out_latch(o_out_latch),
        .o_out_empty(o_out_empty)
    );

    //==================================================
    // clock
    //==================================================
    initial i_clk = 1'b0;
    always #5 i_clk = ~i_clk;

    //==================================================
    // helpers
    //==================================================
    function automatic logic [23:0] pack_gray(
        input int v
    );
        logic [7:0] b;
    begin
        b = v[7:0];
        pack_gray = {b, b, b};
    end
    endfunction

    function automatic logic [23:0] ker_word_center_only(
        input int idx
    );
    begin
        case (idx)
            4: ker_word_center_only = 24'h01_00_00; // p=1, q=0, s=0
            default: ker_word_center_only = 24'h00_00_00;
        endcase
    end
    endfunction

    task automatic drive_idle_inputs;
    begin
        i_next_frame     = 1'b0;
        i_tb_pixel_valid = 1'b0;
        i_tb_pixel       = 24'd0;
        i_ker_cfg_valid  = 1'b0;
        i_ker_cfg_idx    = 4'd0;
        i_ker_input      = 24'd0;
        send_this_cycle  = 1'b0;
    end
    endtask

    task automatic check_kernel_bank_center_only;
    begin
        $display("--------------------------------------------------");
        $display("[CASE] CHECK_KERNEL_BANK | t=%0t", $time);
        $display("  ker_done=%0d", o_ker_done);
        $display("  k00=%h k01=%h k02=%h", dut.k00, dut.k01, dut.k02);
        $display("  k10=%h k11=%h k12=%h", dut.k10, dut.k11, dut.k12);
        $display("  k20=%h k21=%h k22=%h", dut.k20, dut.k21, dut.k22);

        if ((o_ker_done !== 1'b1) ||
            (dut.k00 !== ker_word_center_only(0)) || (dut.k01 !== ker_word_center_only(1)) || (dut.k02 !== ker_word_center_only(2)) ||
            (dut.k10 !== ker_word_center_only(3)) || (dut.k11 !== ker_word_center_only(4)) || (dut.k12 !== ker_word_center_only(5)) ||
            (dut.k20 !== ker_word_center_only(6)) || (dut.k21 !== ker_word_center_only(7)) || (dut.k22 !== ker_word_center_only(8))) begin
            fail_count++;
            $display("[FAIL] CHECK_KERNEL_BANK");
        end
        else begin
            pass_count++;
            $display("[PASS] CHECK_KERNEL_BANK");
        end
    end
    endtask

    task automatic load_kernel_center_only;
        int idx;
    begin
        while (dut.ctrl_ker_load_en !== 1'b1) begin
            @(posedge i_clk);
            #1;
        end

        for (idx = 0; idx < 9; idx = idx + 1) begin
            @(negedge i_clk);
            i_ker_cfg_valid = 1'b1;
            i_ker_cfg_idx   = idx[3:0];
            i_ker_input     = ker_word_center_only(idx);

            @(posedge i_clk);
            #1;
        end

        @(negedge i_clk);
        i_ker_cfg_valid = 1'b0;
        i_ker_cfg_idx   = 4'd0;
        i_ker_input     = 24'd0;

        while (o_ker_done !== 1'b1) begin
            @(posedge i_clk);
            #1;
        end
    end
    endtask

    task automatic dump_status_on_fail(
        input string name
    );
    begin
        $display("--------------------------------------------------");
        $display("[DBG] %s | t=%0t", name, $time);
        $display("  accepted_pixel_count=%0d pixel_id=%0d", accepted_pixel_count, pixel_id);
        $display("  tb_valid=%0d tb_ready=%0d tb_pixel=%h", i_tb_pixel_valid, o_tb_pixel_ready, i_tb_pixel);
        $display("  stream_valid=%0d stream_pixel=%h", dut.stream_pixel_valid, dut.stream_pixel_data);
        $display("  stream_x=%0d stream_y=%0d", dut.stream_x, dut.stream_y);
        $display("  ctrl_win_valid=%0d ctrl_tap_load_valid=%0d ctrl_pipe_shift_en=%0d",
                 dut.ctrl_win_valid, dut.ctrl_tap_load_valid, dut.ctrl_pipe_shift_en);
        $display("  o_out_valid=%0d o_out_latch=%0d o_out_empty=%0d o_frame_done=%0d",
                 o_out_valid, o_out_latch, o_out_empty, o_frame_done);
        $display("  out_s=%0d out_i=%0d out_j=%0d out_k=%0d",
                 o_out_s, o_out_i, o_out_j, o_out_k);
        $display("  out_valid_count=%0d", out_valid_count);
    end
    endtask

    task automatic check_first_tap_req;
    begin
        $display("--------------------------------------------------");
        $display("[CASE] FIRST_TAP_REQ | t=%0t", $time);
        $display("  req_accepted=%0d", req_accepted);
        $display("  req_x=%0d req_y=%0d", req_x, req_y);
        $display("  ctrl_win_valid=%0d ctrl_tap_load_valid=%0d",
                 dut.ctrl_win_valid, dut.ctrl_tap_load_valid);

        if ((req_accepted != FIRST_TAP_REQ_ACCEPTED) ||
            (req_x != 3) || (req_y != 2) ||
            (dut.ctrl_tap_load_valid != 1'b1)) begin
            fail_count++;
            $display("[FAIL] FIRST_TAP_REQ");
        end
        else begin
            pass_count++;
            $display("[PASS] FIRST_TAP_REQ");
        end
    end
    endtask

    task automatic check_first_output;
        logic signed [23:0] exp_s;
        logic signed [23:0] exp_i;
        logic signed [23:0] exp_j;
        logic signed [23:0] exp_k;
    begin
        // center pixel cua first full 3x3 = 65
        // kernel center-only p=1,q=0,s=0
        // y0=-R, y1=0, y2=B, y3=-G
        exp_s = -24'sd65;
        exp_i =  24'sd0;
        exp_j =  24'sd65;
        exp_k = -24'sd65;

        $display("--------------------------------------------------");
        $display("[CASE] FIRST_OUTPUT | t=%0t", $time);
        $display("  out_accepted=%0d", out_accepted);
        $display("  exp_s=%0d exp_i=%0d exp_j=%0d exp_k=%0d",
                 exp_s, exp_i, exp_j, exp_k);
        $display("  obs_s=%0d obs_i=%0d obs_j=%0d obs_k=%0d",
                 o_out_s, o_out_i, o_out_j, o_out_k);
        $display("  out_valid=%0d out_latch=%0d out_empty=%0d",
                 o_out_valid, o_out_latch, o_out_empty);

        if ((out_accepted != FIRST_OUT_ACCEPTED) ||
            (o_out_valid !== 1'b1) ||
            (o_out_latch !== 1'b1) ||
            (o_out_s !== exp_s) ||
            (o_out_i !== exp_i) ||
            (o_out_j !== exp_j) ||
            (o_out_k !== exp_k)) begin
            fail_count++;
            $display("[FAIL] FIRST_OUTPUT");
        end
        else begin
            pass_count++;
            $display("[PASS] FIRST_OUTPUT");
        end
    end
    endtask

    task automatic check_frame_done;
    begin
        $display("--------------------------------------------------");
        $display("[CASE] FRAME_DONE | t=%0t", $time);
        $display("  accepted_pixel_count=%0d", accepted_pixel_count);
        $display("  pixel_id=%0d", pixel_id);
        $display("  out_valid_count=%0d", out_valid_count);
        $display("  o_frame_done=%0d", o_frame_done);
        $display("  o_out_empty=%0d", o_out_empty);

        if ((accepted_pixel_count != FRAME_PIXELS) ||
            (pixel_id != FRAME_PIXELS) ||
            (o_frame_done !== 1'b1)) begin
            fail_count++;
            $display("[FAIL] FRAME_DONE");
        end
        else begin
            pass_count++;
            $display("[PASS] FRAME_DONE");
        end
    end
    endtask

    //==================================================
    // SHM dump
    //==================================================
    initial begin
        $shm_open("pure_quat_conv2d_3x3_core_full.shm");
        $shm_probe(tb_pure_quat_conv2d_3x3_core_full, "AS");
    end

    //==================================================
    // main test
    //==================================================
    initial begin : test_main
        pass_count = 0;
        fail_count = 0;

        accepted_pixel_count = 0;
        pixel_id = 0;
        out_valid_count = 0;

        send_this_cycle = 1'b0;
        first_tap_req_seen = 1'b0;
        first_out_seen = 1'b0;
        frame_done_seen = 1'b0;

        req_accepted = -1;
        req_x = -1;
        req_y = -1;
        out_accepted = -1;

        i_rst_n = 1'b1;
        i_start = 1'b0;
        drive_idle_inputs();

        // reset
        #2;
        i_rst_n = 1'b0;
        #2;
        i_rst_n = 1'b1;

        // start roi giu 1
        @(negedge i_clk);
        i_start = 1'b1;

        // kernel load
        load_kernel_center_only();
        check_kernel_bank_center_only();

        // stream du 1 frame, sau do giu idle de doi flush va frame_done
        while ((frame_done_seen == 1'b0) &&
               (accepted_pixel_count < FRAME_DONE_TIMEOUT)) begin

            @(negedge i_clk);

            if (o_tb_pixel_ready && (accepted_pixel_count < FRAME_PIXELS)) begin
                send_this_cycle  = 1'b1;
                i_tb_pixel_valid = 1'b1;
                i_tb_pixel       = pack_gray(pixel_id);
            end
            else begin
                send_this_cycle  = 1'b0;
                i_tb_pixel_valid = 1'b0;
                i_tb_pixel       = 24'd0;
            end

            @(posedge i_clk);
            #1;

            if (send_this_cycle) begin
                accepted_pixel_count = accepted_pixel_count + 1;
                pixel_id = pixel_id + 1;
            end

            if (o_out_valid == 1'b1) begin
                out_valid_count = out_valid_count + 1;
            end

            if ((first_tap_req_seen == 1'b0) &&
                (dut.ctrl_tap_load_valid == 1'b1)) begin
                first_tap_req_seen = 1'b1;
                req_accepted = accepted_pixel_count;
                req_x = dut.stream_x;
                req_y = dut.stream_y;
                check_first_tap_req();
            end

            if ((first_out_seen == 1'b0) &&
                (o_out_valid == 1'b1)) begin
                first_out_seen = 1'b1;
                out_accepted = accepted_pixel_count;
                check_first_output();
            end

            if ((frame_done_seen == 1'b0) &&
                (o_frame_done == 1'b1)) begin
                frame_done_seen = 1'b1;
                check_frame_done();
            end
        end

        if (first_tap_req_seen == 1'b0) begin
            fail_count++;
            dump_status_on_fail("TIMEOUT_NO_FIRST_TAP_REQ");
            $display("[FAIL] FIRST_TAP_REQ_TIMEOUT_AT_ACCEPTED=%0d", accepted_pixel_count);
        end

        if (first_out_seen == 1'b0) begin
            fail_count++;
            dump_status_on_fail("TIMEOUT_NO_FIRST_OUTPUT");
            $display("[FAIL] FIRST_OUTPUT_TIMEOUT_AT_ACCEPTED=%0d", accepted_pixel_count);
        end

        if (frame_done_seen == 1'b0) begin
            fail_count++;
            dump_status_on_fail("TIMEOUT_NO_FRAME_DONE");
            $display("[FAIL] FRAME_DONE_TIMEOUT_AT_ACCEPTED=%0d", accepted_pixel_count);
        end

        // clear drive truoc khi ket thuc
        @(negedge i_clk);
        i_tb_pixel_valid = 1'b0;
        i_tb_pixel       = 24'd0;
        i_ker_cfg_valid  = 1'b0;
        i_ker_cfg_idx    = 4'd0;
        i_ker_input      = 24'd0;

        $display("========================================");
        $display("tb_pure_quat_conv2d_3x3_core_full DONE");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("accepted_pixel_count = %0d", accepted_pixel_count);
        $display("out_valid_count      = %0d", out_valid_count);
        $display("========================================");

        if (fail_count == 0) begin
            $display("TEST PASSED");
            repeat (20) @(posedge i_clk);
            $shm_close();
            $finish;
        end
        else begin
            repeat (20) @(posedge i_clk);
            $shm_close();
            $fatal(1, "TEST FAILED with %0d errors", fail_count);
        end
    end

endmodule
