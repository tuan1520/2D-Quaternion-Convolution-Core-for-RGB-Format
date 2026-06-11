# =========================================================
# SDC for pure_quat_conv2d_3x3_core
# Aggressive internal timing check at 1 GHz
#
# Purpose:
# - Push the design toward a high-frequency target (1 GHz)
# - Use light I/O timing assumptions so the report reflects
#   internal reg-to-reg capability more clearly
# - Avoid misleading timing failures dominated by external I/O
#
# Notes:
# - This is an aggressive block-level timing setup.
# - It is useful for estimating the internal timing limit of
#   the RTL after synthesis.
# - It is not necessarily the final system-level constraint.
# =========================================================

# ---------------------------------------------------------
# 1) Clock definition
# ---------------------------------------------------------
# Target clock period = 1.0 ns  =>  1 GHz
set CLK_PERIOD 1.0

# Create the real clock on the design clock input port
create_clock -name core_clk -period $CLK_PERIOD [get_ports i_clk]

# ---------------------------------------------------------
# 2) Clock uncertainty
# ---------------------------------------------------------
# Use a small uncertainty value to model limited clock jitter/skew
# while still keeping the setup aggressive for Fmax exploration.
set_clock_uncertainty 0.03 [get_clocks core_clk]

# ---------------------------------------------------------
# 3) Reset handling
# ---------------------------------------------------------
# Reset is treated as an asynchronous control path and is excluded
# from normal timing analysis.
set_false_path -from [get_ports i_rst_n]

# ---------------------------------------------------------
# 4) Input classification
# ---------------------------------------------------------
# Remove clock and reset from the generic input collection.
# Only real data/control inputs should receive input delay constraints.
set DATA_IN [remove_from_collection [all_inputs] [get_ports {i_clk i_rst_n}]]

# ---------------------------------------------------------
# 5) I/O timing assumptions
# ---------------------------------------------------------
# Aggressive block-level assumption:
# reserve only 0.10 ns for the external environment.
# This leaves most of the cycle budget for internal logic.
#
# Max values are used for setup-oriented checks.
# Min values are set to 0.00 for a simple aggressive timing model.
set_input_delay  -clock core_clk -max 0.10 $DATA_IN
set_input_delay  -clock core_clk -min 0.00 $DATA_IN

set_output_delay -clock core_clk -max 0.10 [all_outputs]
set_output_delay -clock core_clk -min 0.00 [all_outputs]

# ---------------------------------------------------------
# 6) Optional external driving/load assumptions
# ---------------------------------------------------------
# These are intentionally commented out for now.
# Enable them only after confirming valid cell names/pins in the
# target gpdk045 library.
#
# Example:
# set_driving_cell -lib_cell <VALID_LIB_CELL_NAME> -pin <OUTPUT_PIN> $DATA_IN
# set_load 0.01 [all_outputs]

# ---------------------------------------------------------
# 7) Transition constraint
# ---------------------------------------------------------
# Tight transition requirement to encourage synthesis to keep
# signal edges sharp, which may improve timing at the cost of
# extra buffering/area/power.
set_max_transition 0.10 [current_design]
