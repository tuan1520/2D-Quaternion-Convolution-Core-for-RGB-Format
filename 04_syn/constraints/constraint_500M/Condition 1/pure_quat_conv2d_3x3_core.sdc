# =========================================================
# pure_quat_conv2d_3x3_core.sdc
# =========================================================

set CLK_PERIOD 2.0

create_clock -name core_clk -period $CLK_PERIOD [get_ports i_clk]

set_clock_uncertainty 0.2 [get_clocks core_clk]
set_clock_transition 0.1 [get_clocks core_clk]

set_false_path -from [get_ports i_rst_n]

set DATA_IN [remove_from_collection [all_inputs] [get_ports {i_clk i_rst_n}]]

set_input_delay  2.0 -clock core_clk $DATA_IN
set_output_delay 2.0 -clock core_clk [all_outputs]
