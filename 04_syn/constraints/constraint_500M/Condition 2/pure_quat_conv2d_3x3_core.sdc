create_clock -name core_clk -period 1.0 [get_ports i_clk]
set_clock_uncertainty 0.05 [get_clocks core_clk]

set_false_path -from [get_ports i_rst_n]

set DATA_IN [remove_from_collection [all_inputs] [get_ports {i_clk i_rst_n}]]

set_input_delay  0.2 -clock core_clk $DATA_IN
set_output_delay 0.2 -clock core_clk [all_outputs]
