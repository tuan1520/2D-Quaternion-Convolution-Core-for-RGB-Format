`timescale 1ns/1ps

module tb_pure_quat_conv2d_3x3_controller;

    localparam int IMG_W = 8;
    localparam int IMG_H = 8;
    localparam int TOTAL_PIPE_LAT = 7;

    localparam logic [2:0] ST_IDLE        = 3'd0;
    localparam logic [2:0] ST_LOAD_KERNEL = 3'd1;
    localparam logic [2:0] ST_FILL        = 3'd2;
    localparam logic [2:0] ST_RUN         = 3'd3;
    localparam logic [2:0] ST_FLUSH       = 3'd4;
    localparam logic [2:0] ST_DONE        = 3'd5;

    logic                     i_clk;
    logic                     i_rst_n;

    logic                     i_start;
    logic                     i_next_frame;

    logic                     i_ker_done;

    logic                     i_pixel_valid;
    logic                     i_end_frame;
    logic [$clog2(IMG_W)-1:0] i_x;
    logic [$clog2(IMG_H)-1:0] i_y;

    logic                     o_busy;
    logic                     o_frame_done;

    logic                     o_ker_load_en;

    logic                     o_lb_en;
    logic                     o_win_en;
    logic                     o_win_valid;

    logic                     o_pipe_shift_en;
    logic                     o_tap_load_valid;

    logic                     o_out_valid;
    logic                     o_out_latch;
    logic                     o_out_empty;

    int pass_count;
    int fail_count;

    pure_quat_conv2d_3x3_controller #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H),
        .TOTAL_PIPE_LAT(TOTAL_PIPE_LAT)
    ) dut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_start(i_start),
        .i_next_frame(i_next_frame),

        .i_ker_done(i_ker_done),

        .i_pixel_valid(i_pixel_valid),
        .i_end_frame(i_end_frame),
        .i_x(i_x),
        .i_y(i_y),

        .o_busy(o_busy),
        .o_frame_done(o_frame_done),

        .o_ker_load_en(o_ker_load_en),

        .o_lb_en(o_lb_en),
        .o_win_en(o_win_en),
        .o_win_valid(o_win_valid),

        .o_pipe_shift_en(o_pipe_shift_en),
        .o_tap_load_valid(o_tap_load_valid),

        .o_out_valid(o_out_valid),
        .o_out_latch(o_out_latch),
        .o_out_empty(o_out_empty)
    );

    initial i_clk = 1'b0;
    always #5 i_clk = ~i_clk;

    task automatic drive_idle_inputs;
    begin
        i_ker_done    = 1'b0;
        i_pixel_valid = 1'b0;
        i_end_frame   = 1'b0;
        i_x           = '0;
        i_y           = '0;
        i_next_frame  = 1'b0;
    end
    endtask

    task automatic check_main(
        input string name,
        input logic [2:0] exp_state,
        input logic exp_busy,
        input logic exp_frame_done,
        input logic exp_ker_load_en,
        input logic exp_lb_en,
        input logic exp_win_en,
        input logic exp_win_valid,
        input logic exp_pipe_shift_en,
        input logic exp_tap_load_valid,
        input logic exp_out_valid,
        input logic exp_out_latch,
        input logic exp_out_empty
    );
    begin
        $display("--------------------------------------------------");
        $display("[CASE] %s | t=%0t", name, $time);
        $display("  state=%0d busy=%0d frame_done=%0d ker_load=%0d",
                 dut.state_cur, o_busy, o_frame_done, o_ker_load_en);
        $display("  lb=%0d win=%0d win_valid=%0d pipe_shift=%0d tap_load=%0d",
                 o_lb_en, o_win_en, o_win_valid, o_pipe_shift_en, o_tap_load_valid);
        $display("  out_valid=%0d out_latch=%0d out_empty=%0d",
                 o_out_valid, o_out_latch, o_out_empty);

        if ((dut.state_cur        !== exp_state)         ||
            (o_busy               !== exp_busy)          ||
            (o_frame_done         !== exp_frame_done)    ||
            (o_ker_load_en        !== exp_ker_load_en)   ||
            (o_lb_en              !== exp_lb_en)         ||
            (o_win_en             !== exp_win_en)        ||
            (o_win_valid          !== exp_win_valid)     ||
            (o_pipe_shift_en      !== exp_pipe_shift_en) ||
            (o_tap_load_valid     !== exp_tap_load_valid)||
            (o_out_valid          !== exp_out_valid)     ||
            (o_out_latch          !== exp_out_latch)     ||
            (o_out_empty          !== exp_out_empty)) begin
            fail_count++;
            $display("[FAIL] %s", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s", name);
        end
    end
    endtask

    task automatic check_internal_flags(
        input string name,
        input logic exp_x_ge_2,
        input logic exp_y_ge_2,
        input logic exp_window_ready_now,
        input logic exp_win_fill_valid_now,
        input logic [2:0] exp_pipe_in_valid_dly,
        input logic exp_pipe_in_valid_now
    );
    begin
        $display("  int : x_ge_2=%0d y_ge_2=%0d window_ready=%0d",
                 dut.x_ge_2, dut.y_ge_2, dut.window_ready_now);
        $display("        win_fill_valid_now=%0d pipe_in_valid_dly=%03b pipe_in_valid_now=%0d",
                 dut.win_fill_valid_now, dut.pipe_in_valid_dly, dut.pipe_in_valid_now);

        if ((dut.x_ge_2             !== exp_x_ge_2)             ||
            (dut.y_ge_2             !== exp_y_ge_2)             ||
            (dut.window_ready_now   !== exp_window_ready_now)   ||
            (dut.win_fill_valid_now !== exp_win_fill_valid_now) ||
            (dut.pipe_in_valid_dly  !== exp_pipe_in_valid_dly)  ||
            (dut.pipe_in_valid_now  !== exp_pipe_in_valid_now)) begin
            fail_count++;
            $display("[FAIL] %s_INT", name);
        end
        else begin
            pass_count++;
            $display("[PASS] %s_INT", name);
        end
    end
    endtask

    task automatic wait_until_out_valid_or_timeout(
        input int max_cycles
    );
        int cyc;
    begin
        cyc = 0;
        while ((o_out_valid !== 1'b1) && (cyc < max_cycles)) begin
            @(posedge i_clk);
            #1;
            cyc = cyc + 1;
        end
    end
    endtask

    task automatic wait_until_flush_empty_or_timeout(
        input int max_cycles
    );
        int cyc;
    begin
        cyc = 0;
        while (!((dut.state_cur == ST_FLUSH) && (o_out_empty == 1'b1)) && (cyc < max_cycles)) begin
            @(posedge i_clk);
            #1;
            cyc = cyc + 1;
        end
    end
    endtask

    initial begin
        $shm_open("pure_quat_conv2d_3x3_controller.shm");
        $shm_probe(tb_pure_quat_conv2d_3x3_controller, "AS");
    end

    initial begin
        pass_count = 0;
        fail_count = 0;

        i_rst_n       = 1'b1;
        i_start       = 1'b0;
        i_next_frame  = 1'b0;
        i_ker_done    = 1'b0;
        i_pixel_valid = 1'b0;
        i_end_frame   = 1'b0;
        i_x           = '0;
        i_y           = '0;

        //==================================================
        // reset
        //==================================================
        #2;
        i_rst_n = 1'b0;
        #1;
        check_main("RESET", ST_IDLE, 1'b1, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b1);
        check_internal_flags("RESET", 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

        @(negedge i_clk);
        i_rst_n = 1'b1;

        //==================================================
        // start edge detect
        //==================================================
        @(negedge i_clk);
        i_start = 1'b1;
        drive_idle_inputs();

        @(posedge i_clk);
        #1;
        check_main("AFTER_START_EDGE", ST_LOAD_KERNEL, 1'b1, 1'b0, 1'b1,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b1);

        @(posedge i_clk);
        #1;
        check_main("STAY_LOAD_KERNEL", ST_LOAD_KERNEL, 1'b1, 1'b0, 1'b1,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b1);

        //==================================================
        // kernel done -> FILL
        //==================================================
        @(negedge i_clk);
        i_ker_done = 1'b1;

        @(posedge i_clk);
        #1;
        check_main("TO_FILL", ST_FILL, 1'b0, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b1);

        @(negedge i_clk);
        i_ker_done = 1'b0;

        //==================================================
        // y < 2
        //==================================================
        @(negedge i_clk);
        i_pixel_valid = 1'b1;
        i_x = 1;
        i_y = 1;

        #1;
        check_main("FILL_Y_LT_2", ST_FILL, 1'b0, 1'b0, 1'b0,
                   1'b1, 1'b1, 1'b0, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b1);
        check_internal_flags("FILL_Y_LT_2", 1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

        //==================================================
        // x=0, y=2
        //==================================================
        @(posedge i_clk);
        #1;
        @(negedge i_clk);
        i_pixel_valid = 1'b1;
        i_x = 0;
        i_y = 2;

        #1;
        check_main("FILL_ROW_X0", ST_FILL, 1'b0, 1'b0, 1'b0,
                   1'b1, 1'b1, 1'b1, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b1);
        check_internal_flags("FILL_ROW_X0", 1'b0, 1'b1, 1'b0, 1'b1, 3'b000, 1'b0);

        @(posedge i_clk);
        #1;
        check_internal_flags("FILL_ROW_X0_POST", 1'b0, 1'b1, 1'b0, 1'b1, 3'b001, 1'b0);

        //==================================================
        // x=1, y=2
        //==================================================
        @(negedge i_clk);
        i_pixel_valid = 1'b1;
        i_x = 1;
        i_y = 2;

        #1;
        check_main("FILL_ROW_X1", ST_FILL, 1'b0, 1'b0, 1'b0,
                   1'b1, 1'b1, 1'b1, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b1);
        check_internal_flags("FILL_ROW_X1", 1'b0, 1'b1, 1'b0, 1'b1, 3'b001, 1'b0);

        @(posedge i_clk);
        #1;
        check_internal_flags("FILL_ROW_X1_POST", 1'b0, 1'b1, 1'b0, 1'b1, 3'b011, 1'b0);

        //==================================================
        // x=2, y=2
        //==================================================
        @(negedge i_clk);
        i_pixel_valid = 1'b1;
        i_x = 2;
        i_y = 2;

        #1;
        check_main("FILL_ROW_X2", ST_FILL, 1'b0, 1'b0, 1'b0,
                   1'b1, 1'b1, 1'b1, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b1);
        check_internal_flags("FILL_ROW_X2", 1'b1, 1'b1, 1'b1, 1'b1, 3'b011, 1'b0);

        @(posedge i_clk);
        #1;
        check_internal_flags("FILL_ROW_X2_POST", 1'b1, 1'b1, 1'b1, 1'b1, 3'b111, 1'b1);

        //==================================================
        // x=3, y=2
        // sample dau tien duoc chot vao tap_input_pipe
        //==================================================
        @(negedge i_clk);
        i_pixel_valid = 1'b1;
        i_x = 3;
        i_y = 2;

        #1;
        check_main("FILL_PIPE_READY_COMB", ST_FILL, 1'b0, 1'b0, 1'b0,
                   1'b1, 1'b1, 1'b1, 1'b1, 1'b1,
                   1'b0, 1'b0, 1'b1);
        check_internal_flags("FILL_PIPE_READY_COMB", 1'b1, 1'b1, 1'b1, 1'b1, 3'b111, 1'b1);

        @(posedge i_clk);
        #1;
        check_main("ENTER_RUN", ST_RUN, 1'b0, 1'b0, 1'b0,
                   1'b1, 1'b1, 1'b1, 1'b1, 1'b1,
                   1'b0, 1'b0, 1'b0);

        //==================================================
        // RUN
        //==================================================
        @(negedge i_clk);
        i_pixel_valid = 1'b1;
        i_x = 4;
        i_y = 2;

        wait_until_out_valid_or_timeout(TOTAL_PIPE_LAT + 4);

        if (o_out_valid !== 1'b1) begin
            fail_count++;
            $display("[FAIL] RUN_WAIT_OUT_VALID_TIMEOUT");
        end
        else begin
            check_main("RUN_OUT_VALID_FIRST", ST_RUN, 1'b0, 1'b0, 1'b0,
                       1'b1, 1'b1, 1'b1, 1'b1, 1'b1,
                       1'b1, 1'b1, 1'b0);
        end

        //==================================================
        // FLUSH
        //==================================================
        @(negedge i_clk);
        i_end_frame = 1'b1;

        @(posedge i_clk);
        #1;
        check_main("ENTER_FLUSH", ST_FLUSH, 1'b1, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b0, 1'b1, 1'b0,
                   1'b0, 1'b0, 1'b0);

        @(negedge i_clk);
        i_end_frame   = 1'b0;
        i_pixel_valid = 1'b0;
        i_x           = '0;
        i_y           = '0;

        wait_until_flush_empty_or_timeout(TOTAL_PIPE_LAT + 4);

        if (!((dut.state_cur == ST_FLUSH) && (o_out_empty == 1'b1))) begin
            fail_count++;
            $display("[FAIL] FLUSH_EMPTY_TIMEOUT");
        end
        else begin
            check_main("FLUSH_EMPTY_LAST", ST_FLUSH, 1'b1, 1'b0, 1'b0,
                       1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                       1'b0, 1'b0, 1'b1);
        end

        @(posedge i_clk);
        #1;
        check_main("DONE_STATE", ST_DONE, 1'b1, 1'b1, 1'b0,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b1);

        @(negedge i_clk);
        i_next_frame = 1'b1;

        @(posedge i_clk);
        #1;
        check_main("BACK_TO_IDLE", ST_IDLE, 1'b1, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b1);

        @(posedge i_clk);
        #1;
        check_main("NO_RESTART_WHEN_START_HELD", ST_IDLE, 1'b1, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                   1'b0, 1'b0, 1'b1);

        $display("========================================");
        $display("tb_pure_quat_conv2d_3x3_controller DONE");
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