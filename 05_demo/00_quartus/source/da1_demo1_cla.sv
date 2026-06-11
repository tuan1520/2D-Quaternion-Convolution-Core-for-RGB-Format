`timescale 1ns/1ps

module demo_add_unsigned_cin #(
    parameter int W = 8
)(
    input  logic [W-1:0] i_a,
    input  logic [W-1:0] i_b,
    input  logic         i_cin,
    output logic [W-1:0] o_sum,
    output logic         o_cout
);
    localparam int FULL4   = W / 4;
    localparam int REM     = W % 4;
    localparam int NUM_BLK = FULL4 + ((REM > 0) ? 1 : 0);

    logic [NUM_BLK:0] c;

    assign c[0] = i_cin;

    generate
        genvar g;
        for (g = 0; g < FULL4; g = g + 1) begin : gen_cla4
            logic [3:0] sum4;
            logic       cout4;

            cla_4b u_cla_4b (
                .i_a   (i_a[g*4 +: 4]),
                .i_b   (i_b[g*4 +: 4]),
                .i_cin (c[g]),
                .o_sum (sum4),
                .o_cout(cout4)
            );

            assign o_sum[g*4 +: 4] = sum4;
            assign c[g+1]          = cout4;
        end

        if (REM != 0) begin : gen_cla_rem
            logic [2:0] a3;
            logic [2:0] b3;
            logic [2:0] s3;
            logic       cout3;

            if (REM == 1) begin : gen_rem1
                assign a3 = {2'b00, i_a[FULL4*4]};
                assign b3 = {2'b00, i_b[FULL4*4]};
                assign o_sum[FULL4*4] = s3[0];
            end
            else if (REM == 2) begin : gen_rem2
                assign a3 = {1'b0, i_a[FULL4*4 +: 2]};
                assign b3 = {1'b0, i_b[FULL4*4 +: 2]};
                assign o_sum[FULL4*4 +: 2] = s3[1:0];
            end
            else begin : gen_rem3
                assign a3 = i_a[FULL4*4 +: 3];
                assign b3 = i_b[FULL4*4 +: 3];
                assign o_sum[FULL4*4 +: 3] = s3;
            end

            cla_3b u_cla_3b (
                .i_a   (a3),
                .i_b   (b3),
                .i_cin (c[FULL4]),
                .o_sum (s3),
                .o_cout(cout3)
            );

            assign c[NUM_BLK] = cout3;
        end
    endgenerate

    generate
        if (REM == 0) begin : gen_cout_full4
            assign o_cout = c[FULL4];
        end
        else begin : gen_cout_rem
            assign o_cout = c[NUM_BLK];
        end
    endgenerate
endmodule


module demo_inc_unsigned #(
    parameter int W = 8
)(
    input  logic [W-1:0] i_a,
    output logic [W-1:0] o_sum
);
    localparam logic [W-1:0] ONE = {{(W-1){1'b0}}, 1'b1};
    logic cout_unused;

    demo_add_unsigned_cin #(
        .W(W)
    ) u_add_inc (
        .i_a   (i_a),
        .i_b   (ONE),
        .i_cin (1'b0),
        .o_sum (o_sum),
        .o_cout(cout_unused)
    );
endmodule


module demo_dec_unsigned #(
    parameter int W = 8
)(
    input  logic [W-1:0] i_a,
    output logic [W-1:0] o_sum
);
    localparam logic [W-1:0] ONE = {{(W-1){1'b0}}, 1'b1};
    logic [W-1:0] b_inv;
    logic         cout_unused;

    assign b_inv = ~ONE;

    demo_add_unsigned_cin #(
        .W(W)
    ) u_add_dec (
        .i_a   (i_a),
        .i_b   (b_inv),
        .i_cin (1'b1),
        .o_sum (o_sum),
        .o_cout(cout_unused)
    );
endmodule


module demo_reset_sync (
    input  logic i_clk,
    input  logic i_rst_n_async,
    output logic o_rst_n_sync
);
    logic rst_ff1;
    logic rst_ff2;

    always_ff @(posedge i_clk or negedge i_rst_n_async) begin
        if (!i_rst_n_async) begin
            rst_ff1      <= 1'b0;
            rst_ff2      <= 1'b0;
            o_rst_n_sync <= 1'b0;
        end
        else begin
            rst_ff1      <= 1'b1;
            rst_ff2      <= rst_ff1;
            o_rst_n_sync <= rst_ff2;
        end
    end
endmodule


module demo_key_press (
    input  logic i_clk,
    input  logic i_rst_n,
    input  logic i_key_n,
    output logic o_press_pulse
);
    logic key_n_d;

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            key_n_d       <= 1'b1;
            o_press_pulse <= 1'b0;
        end
        else begin
            key_n_d       <= i_key_n;
            o_press_pulse <= key_n_d & ~i_key_n;
        end
    end
endmodule


module demo_tick_gen #(
    parameter int DIV_COUNT = 25_000_000
)(
    input  logic i_clk,
    input  logic i_rst_n,
    output logic o_tick
);
    localparam int CW = (DIV_COUNT <= 1) ? 1 : $clog2(DIV_COUNT);
    localparam logic [CW-1:0] DIV_LAST = DIV_COUNT - 1;
    logic [CW-1:0] cnt;
    logic [CW-1:0] cnt_next;

    demo_inc_unsigned #(
        .W(CW)
    ) u_cnt_inc (
        .i_a  (cnt),
        .o_sum(cnt_next)
    );

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            cnt    <= '0;
            o_tick <= 1'b0;
        end
        else begin
            if (cnt == DIV_LAST) begin
                cnt    <= '0;
                o_tick <= 1'b1;
            end
            else begin
                cnt    <= cnt_next;
                o_tick <= 1'b0;
            end
        end
    end
endmodule


module demo_image_rom_16x16 #(
    parameter int IMG_W = 16,
    parameter int IMG_H = 16,
    parameter string IMAGE_HEX_FILE = "image_16x16_rgb.hex"
)(
    input  logic [7:0]  i_addr,
    output logic [23:0] o_data
);
    logic [23:0] mem [0:255];

    initial begin
        $readmemh(IMAGE_HEX_FILE, mem);
    end

    assign o_data = mem[i_addr];
endmodule


module demo_kernel_loader #(
    parameter string KERNEL_HEX_FILE = "kernel_3x3.hex"
)(
    input  logic        i_clk,
    input  logic        i_rst_n,
    input  logic        i_core_ker_done,
    output logic        o_cfg_valid,
    output logic [3:0]  o_cfg_idx,
    output logic [23:0] o_cfg_data,
    output logic        o_sent_all
);
    logic [3:0]  cfg_idx;
    logic [3:0]  cfg_idx_next;
    logic [23:0] ker_mem [0:8];

    initial begin
        $readmemh(KERNEL_HEX_FILE, ker_mem);
    end

    demo_inc_unsigned #(
        .W(4)
    ) u_cfg_idx_inc (
        .i_a  (cfg_idx),
        .o_sum(cfg_idx_next)
    );

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            cfg_idx     <= 4'd0;
            o_cfg_valid <= 1'b0;
            o_cfg_idx   <= 4'd0;
            o_cfg_data  <= 24'd0;
            o_sent_all  <= 1'b0;
        end
        else begin
            o_cfg_valid <= 1'b0;

            if (i_core_ker_done) begin
                o_cfg_idx  <= cfg_idx;
                o_cfg_data <= ker_mem[cfg_idx];
                o_sent_all <= 1'b1;
            end
            else begin
                o_cfg_valid <= 1'b1;
                o_cfg_idx   <= cfg_idx;
                o_cfg_data  <= ker_mem[cfg_idx];

                if (cfg_idx == 4'd8) begin
                    cfg_idx    <= 4'd0;
                    o_sent_all <= 1'b0;
                end
                else begin
                    cfg_idx    <= cfg_idx_next;
                    o_sent_all <= 1'b0;
                end
            end
        end
    end
endmodule


module demo_pixel_feeder (
    input  logic        i_clk,
    input  logic        i_rst_n,
    input  logic        i_start_pulse,
    input  logic        i_mode_fullspeed,
    input  logic        i_slow_tick,
    input  logic        i_tb_ready,
    input  logic [23:0] i_rom_pixel,
    output logic [7:0]  o_rom_addr,
    output logic        o_tb_valid,
    output logic [23:0] o_tb_pixel,
    output logic        o_active,
    output logic        o_done
);
    logic active;
    logic [7:0] rom_addr;
    logic [7:0] rom_addr_next;
    logic [8:0] sent_count;
    logic [8:0] sent_count_next;
    logic       launch_now;
    logic       allow_step;
    logic       done_now;

    assign allow_step = i_mode_fullspeed ? 1'b1 : i_slow_tick;
    assign done_now   = (sent_count == 9'd256);
    assign launch_now = active & ~done_now & i_tb_ready & allow_step;

    demo_inc_unsigned #(
        .W(8)
    ) u_rom_addr_inc (
        .i_a  (rom_addr),
        .o_sum(rom_addr_next)
    );

    demo_inc_unsigned #(
        .W(9)
    ) u_sent_count_inc (
        .i_a  (sent_count),
        .o_sum(sent_count_next)
    );

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            active     <= 1'b0;
            rom_addr   <= 8'd0;
            sent_count <= 9'd0;
            o_tb_valid <= 1'b0;
            o_tb_pixel <= 24'd0;
            o_done     <= 1'b0;
        end
        else begin
            o_tb_valid <= 1'b0;

            if (i_start_pulse) begin
                active     <= 1'b1;
                rom_addr   <= 8'd0;
                sent_count <= 9'd0;
                o_done     <= 1'b0;
            end
            else if (active) begin
                if (launch_now) begin
                    o_tb_valid <= 1'b1;
                    o_tb_pixel <= i_rom_pixel;
                    rom_addr   <= rom_addr_next;
                    sent_count <= sent_count_next;

                    if (sent_count == 9'd255) begin
                        active <= 1'b0;
                        o_done <= 1'b1;
                    end
                end
            end
        end
    end

    assign o_rom_addr = rom_addr;
    assign o_active   = active;
endmodule


module demo_output_capture #(
    parameter int DEPTH = 196,
    parameter int AW    = 8
)(
    input  logic               i_clk,
    input  logic               i_rst_n,
    input  logic               i_clear,
    input  logic               i_write_en,
    input  logic signed [23:0] i_wr_s,
    input  logic signed [23:0] i_wr_i,
    input  logic signed [23:0] i_wr_j,
    input  logic signed [23:0] i_wr_k,
    input  logic [AW-1:0]      i_rd_addr,
    input  logic [3:0]         i_lane_sel,
    output logic signed [23:0] o_rd_data,
    output logic               o_lane_sel_valid,
    output logic [AW-1:0]      o_sample_count
);
    localparam logic [AW-1:0] DEPTH_U = DEPTH[AW-1:0];

    logic signed [23:0] mem_s [0:DEPTH-1];
    logic signed [23:0] mem_i [0:DEPTH-1];
    logic signed [23:0] mem_j [0:DEPTH-1];
    logic signed [23:0] mem_k [0:DEPTH-1];
    logic [AW-1:0] wr_addr;
    logic [AW-1:0] wr_addr_next;
    integer z;

    initial begin
        for (z = 0; z < DEPTH; z = z + 1) begin
            mem_s[z] = 24'sd0;
            mem_i[z] = 24'sd0;
            mem_j[z] = 24'sd0;
            mem_k[z] = 24'sd0;
        end
    end

    demo_inc_unsigned #(
        .W(AW)
    ) u_wr_addr_inc (
        .i_a  (wr_addr),
        .o_sum(wr_addr_next)
    );

    assign o_lane_sel_valid = (i_lane_sel == 4'b0001) |
                              (i_lane_sel == 4'b0010) |
                              (i_lane_sel == 4'b0100) |
                              (i_lane_sel == 4'b1000);

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            wr_addr        <= '0;
            o_sample_count <= '0;
        end
        else begin
            if (i_clear) begin
                wr_addr        <= '0;
                o_sample_count <= '0;
            end
            else if (i_write_en && (wr_addr < DEPTH_U)) begin
                mem_s[wr_addr] <= i_wr_s;
                mem_i[wr_addr] <= i_wr_i;
                mem_j[wr_addr] <= i_wr_j;
                mem_k[wr_addr] <= i_wr_k;
                wr_addr        <= wr_addr_next;
                o_sample_count <= wr_addr_next;
            end
        end
    end

    always_comb begin
        case (i_lane_sel)
            4'b0001: o_rd_data = mem_s[i_rd_addr];
            4'b0010: o_rd_data = mem_i[i_rd_addr];
            4'b0100: o_rd_data = mem_j[i_rd_addr];
            4'b1000: o_rd_data = mem_k[i_rd_addr];
            default: o_rd_data = 24'sd0;
        endcase
    end
endmodule


module demo_readback_ctrl #(
    parameter int AW = 8
)(
    input  logic          i_clk,
    input  logic          i_rst_n,
    input  logic          i_clear,
    input  logic          i_frame_done,
    input  logic          i_lane_sel_valid,
    input  logic          i_next_pulse,
    input  logic          i_prev_pulse,
    input  logic [AW-1:0] i_sample_count,
    output logic [AW-1:0] o_rd_addr
);
    logic [AW-1:0] sample_last;
    logic [AW-1:0] rd_addr_next;
    logic [AW-1:0] rd_addr_prev;

    demo_dec_unsigned #(
        .W(AW)
    ) u_sample_last_dec (
        .i_a  (i_sample_count),
        .o_sum(sample_last)
    );

    demo_inc_unsigned #(
        .W(AW)
    ) u_rd_addr_inc (
        .i_a  (o_rd_addr),
        .o_sum(rd_addr_next)
    );

    demo_dec_unsigned #(
        .W(AW)
    ) u_rd_addr_dec (
        .i_a  (o_rd_addr),
        .o_sum(rd_addr_prev)
    );

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_rd_addr <= '0;
        end
        else if (i_clear) begin
            o_rd_addr <= '0;
        end
        else if (i_frame_done && i_lane_sel_valid) begin
            if (i_next_pulse) begin
                if (i_sample_count == '0)
                    o_rd_addr <= '0;
                else if (o_rd_addr < sample_last)
                    o_rd_addr <= rd_addr_next;
                else
                    o_rd_addr <= o_rd_addr;
            end
            else if (i_prev_pulse) begin
                if (o_rd_addr != '0)
                    o_rd_addr <= rd_addr_prev;
                else
                    o_rd_addr <= o_rd_addr;
            end
        end
    end
endmodule


module demo_hex_mux (
    input  logic               i_show_addr,
    input  logic               i_frame_done,
    input  logic               i_lane_sel_valid,
    input  logic signed [23:0] i_data,
    input  logic [7:0]         i_addr,
    output logic [23:0]        o_hex_data
);
    always_comb begin
        if (!i_frame_done) begin
            o_hex_data = 24'h000000;
        end
        else if (!i_lane_sel_valid) begin
            o_hex_data = 24'h000000;
        end
        else if (i_show_addr) begin
            o_hex_data = {16'h0000, i_addr};
        end
        else begin
            o_hex_data = i_data[23:0];
        end
    end
endmodule


module demo_hex7seg (
    input  logic [3:0] i_hex,
    output logic [6:0] o_seg_n
);
    always_comb begin
        case (i_hex)
            4'h0: o_seg_n = 7'b1000000;
            4'h1: o_seg_n = 7'b1111001;
            4'h2: o_seg_n = 7'b0100100;
            4'h3: o_seg_n = 7'b0110000;
            4'h4: o_seg_n = 7'b0011001;
            4'h5: o_seg_n = 7'b0010010;
            4'h6: o_seg_n = 7'b0000010;
            4'h7: o_seg_n = 7'b1111000;
            4'h8: o_seg_n = 7'b0000000;
            4'h9: o_seg_n = 7'b0010000;
            4'hA: o_seg_n = 7'b0001000;
            4'hB: o_seg_n = 7'b0000011;
            4'hC: o_seg_n = 7'b1000110;
            4'hD: o_seg_n = 7'b0100001;
            4'hE: o_seg_n = 7'b0000110;
            4'hF: o_seg_n = 7'b0001110;
            default: o_seg_n = 7'b1111111;
        endcase
    end
endmodule


module da1_demo1 (
    input  logic        CLOCK_50,
    input  logic [3:0]  KEY,
    input  logic [9:0]  SW,
    output logic [9:0]  LEDR,
    output logic [6:0]  HEX0,
    output logic [6:0]  HEX1,
    output logic [6:0]  HEX2,
    output logic [6:0]  HEX3,
    output logic [6:0]  HEX4,
    output logic [6:0]  HEX5
);
    localparam int IMG_W       = 16;
    localparam int IMG_H       = 16;
    localparam int LINE_LENGTH = 16;
    localparam int OUT_AW      = 8;
    localparam int OUT_DEPTH   = 196;

    logic rst_n_sync;

    logic start_pulse;
    logic next_pulse;
    logic prev_pulse;

    logic slow_tick;
    logic mode_fullspeed;
    logic mode_show_addr;

    logic [7:0]  rom_addr;
    logic [23:0] rom_pixel;
    logic        tb_valid;
    logic [23:0] tb_pixel;
    logic        feeder_active;
    logic        feeder_done;

    logic        ker_cfg_valid;
    logic [3:0]  ker_cfg_idx;
    logic [23:0] ker_cfg_data;
    logic        ker_sent_all;

    logic        core_tb_ready;
    logic        core_ker_done;
    logic        core_frame_done;
    logic signed [23:0] out_s;
    logic signed [23:0] out_i;
    logic signed [23:0] out_j;
    logic signed [23:0] out_k;
    logic        out_valid;
    logic        out_empty;

    logic signed [23:0] lane_rd_data;
    logic               lane_sel_valid_raw;
    logic               lane_sel_valid;
    logic [OUT_AW-1:0]  sample_count;
    logic [OUT_AW-1:0]  rd_addr;
    logic [23:0]        hex_bus;
    logic [3:0]         lane_sel;

    assign mode_fullspeed = SW[9];
    assign mode_show_addr = SW[8];
    assign lane_sel       = SW[3:0];

    demo_reset_sync u_reset_sync (
        .i_clk        (CLOCK_50),
        .i_rst_n_async(KEY[0]),
        .o_rst_n_sync (rst_n_sync)
    );

    demo_key_press u_key_start (
        .i_clk        (CLOCK_50),
        .i_rst_n      (rst_n_sync),
        .i_key_n      (KEY[1]),
        .o_press_pulse(start_pulse)
    );

    demo_key_press u_key_next (
        .i_clk        (CLOCK_50),
        .i_rst_n      (rst_n_sync),
        .i_key_n      (KEY[2]),
        .o_press_pulse(next_pulse)
    );

    demo_key_press u_key_prev (
        .i_clk        (CLOCK_50),
        .i_rst_n      (rst_n_sync),
        .i_key_n      (KEY[3]),
        .o_press_pulse(prev_pulse)
    );

    demo_tick_gen #(
        .DIV_COUNT(25_000_000)
    ) u_tick_gen (
        .i_clk  (CLOCK_50),
        .i_rst_n(rst_n_sync),
        .o_tick (slow_tick)
    );

    demo_image_rom_16x16 u_image_rom (
        .i_addr(rom_addr),
        .o_data(rom_pixel)
    );

    demo_kernel_loader u_kernel_loader (
        .i_clk          (CLOCK_50),
        .i_rst_n        (rst_n_sync),
        .i_core_ker_done(core_ker_done),
        .o_cfg_valid    (ker_cfg_valid),
        .o_cfg_idx      (ker_cfg_idx),
        .o_cfg_data     (ker_cfg_data),
        .o_sent_all     (ker_sent_all)
    );

    demo_pixel_feeder u_pixel_feeder (
        .i_clk             (CLOCK_50),
        .i_rst_n           (rst_n_sync),
        .i_start_pulse     (start_pulse),
        .i_mode_fullspeed  (mode_fullspeed),
        .i_slow_tick       (slow_tick),
        .i_tb_ready        (core_tb_ready),
        .i_rom_pixel       (rom_pixel),
        .o_rom_addr        (rom_addr),
        .o_tb_valid        (tb_valid),
        .o_tb_pixel        (tb_pixel),
        .o_active          (feeder_active),
        .o_done            (feeder_done)
    );

    logic out_latch_unused;

    pure_quat_conv2d_3x3_core #(
        .IMG_W         (IMG_W),
        .IMG_H         (IMG_H),
        .LINE_LENGTH   (LINE_LENGTH),
        .TOTAL_PIPE_LAT(7)
    ) u_core (
        .i_clk            (CLOCK_50),
        .i_rst_n          (rst_n_sync),
        .i_start          (start_pulse),
        .i_next_frame     (start_pulse),
        .i_tb_pixel_valid (tb_valid),
        .i_tb_pixel       (tb_pixel),
        .o_tb_pixel_ready (core_tb_ready),
        .i_ker_cfg_valid  (ker_cfg_valid),
        .i_ker_cfg_idx    (ker_cfg_idx),
        .i_ker_input      (ker_cfg_data),
        .o_ker_done       (core_ker_done),
        .o_frame_done     (core_frame_done),
        .o_out_s          (out_s),
        .o_out_i          (out_i),
        .o_out_j          (out_j),
        .o_out_k          (out_k),
        .o_out_valid      (out_valid),
        .o_out_latch      (out_latch_unused),
        .o_out_empty      (out_empty)
    );

    demo_output_capture #(
        .DEPTH(OUT_DEPTH),
        .AW   (OUT_AW)
    ) u_output_capture (
        .i_clk            (CLOCK_50),
        .i_rst_n          (rst_n_sync),
        .i_clear          (start_pulse),
        .i_write_en       (out_valid),
        .i_wr_s           (out_s),
        .i_wr_i           (out_i),
        .i_wr_j           (out_j),
        .i_wr_k           (out_k),
        .i_rd_addr        (rd_addr),
        .i_lane_sel       (lane_sel),
        .o_rd_data        (lane_rd_data),
        .o_lane_sel_valid (lane_sel_valid_raw),
        .o_sample_count   (sample_count)
    );

    assign lane_sel_valid = core_frame_done & lane_sel_valid_raw;

    demo_readback_ctrl #(
        .AW(OUT_AW)
    ) u_readback_ctrl (
        .i_clk            (CLOCK_50),
        .i_rst_n          (rst_n_sync),
        .i_clear          (start_pulse),
        .i_frame_done     (core_frame_done),
        .i_lane_sel_valid (lane_sel_valid),
        .i_next_pulse     (next_pulse),
        .i_prev_pulse     (prev_pulse),
        .i_sample_count   (sample_count),
        .o_rd_addr        (rd_addr)
    );

    demo_hex_mux u_hex_mux (
        .i_show_addr      (mode_show_addr),
        .i_frame_done     (core_frame_done),
        .i_lane_sel_valid (lane_sel_valid),
        .i_data           (lane_rd_data),
        .i_addr           (rd_addr),
        .o_hex_data       (hex_bus)
    );

    demo_hex7seg u_hex0 (.i_hex(hex_bus[3:0]),   .o_seg_n(HEX0));
    demo_hex7seg u_hex1 (.i_hex(hex_bus[7:4]),   .o_seg_n(HEX1));
    demo_hex7seg u_hex2 (.i_hex(hex_bus[11:8]),  .o_seg_n(HEX2));
    demo_hex7seg u_hex3 (.i_hex(hex_bus[15:12]), .o_seg_n(HEX3));
    demo_hex7seg u_hex4 (.i_hex(hex_bus[19:16]), .o_seg_n(HEX4));
    demo_hex7seg u_hex5 (.i_hex(hex_bus[23:20]), .o_seg_n(HEX5));

    always_comb begin
        if (!mode_fullspeed) begin
            LEDR[0] = rst_n_sync;
            LEDR[1] = ker_sent_all;
            LEDR[2] = tb_valid;
            LEDR[3] = core_tb_ready;
            LEDR[4] = out_valid;
            LEDR[5] = out_empty;
            LEDR[6] = feeder_active;
            LEDR[7] = core_frame_done;
            LEDR[8] = lane_sel_valid;
            LEDR[9] = mode_show_addr;
        end
        else begin
            LEDR[0] = 1'b0;
            LEDR[1] = 1'b0;
            LEDR[2] = 1'b0;
            LEDR[3] = 1'b0;
            LEDR[4] = 1'b0;
            LEDR[5] = 1'b0;
            LEDR[6] = 1'b0;
            LEDR[7] = core_frame_done;
            LEDR[8] = lane_sel_valid;
            LEDR[9] = mode_show_addr;
        end
    end
endmodule
