# =========================================================
# run_genus.tcl
# Genus flow + external SDC
# =========================================================

# ---------------------------------------------------------
# 0) Resolve directory tree
# ---------------------------------------------------------
set SCRIPT_DIR   [file normalize [file dirname [info script]]]
set SYN_DIR      [file normalize [file join $SCRIPT_DIR ..]]
set PROJ_DIR     [file normalize [file join $SYN_DIR ..]]

set FILELIST_DIR [file join $SYN_DIR filelist]
set FILELIST     [file join $FILELIST_DIR filelist_syn.f]
set SDC_FILE     [file join $SYN_DIR constraints pure_quat_conv2d_3x3_core.sdc]

set REPORT_DIR   [file join $SYN_DIR reports]
set NETLIST_DIR  [file join $SYN_DIR netlist]
set LOG_DIR      [file join $SYN_DIR log]
set WORK_DIR     [file join $SYN_DIR work]

set TOP_MODULE   pure_quat_conv2d_3x3_core

# ---------------------------------------------------------
# 1) Library path
# ---------------------------------------------------------
set LIB_DIR [file join $SYN_DIR libs gpdk045 gpdk045_lib]

# Quet .lib trong LIB_DIR
set LIB_FILES [glob -nocomplain [file join $LIB_DIR *.lib]]

if {[llength $LIB_FILES] == 0} {
    puts "ERROR: no .lib file found in $LIB_DIR"
    exit 1
}

if {![file exists $FILELIST]} {
    puts "ERROR: filelist not found: $FILELIST"
    exit 1
}

if {![file exists $SDC_FILE]} {
    puts "ERROR: SDC file not found: $SDC_FILE"
    exit 1
}

puts "========================================================="
puts "PROJ_DIR   : $PROJ_DIR"
puts "SYN_DIR    : $SYN_DIR"
puts "TOP_MODULE : $TOP_MODULE"
puts "FILELIST   : $FILELIST"
puts "SDC_FILE   : $SDC_FILE"
puts "LIB_DIR    : $LIB_DIR"
puts "LIB_FILES  : $LIB_FILES"
puts "========================================================="

# ---------------------------------------------------------
# 2) Prepare output directories
# ---------------------------------------------------------
file mkdir $REPORT_DIR
file mkdir $NETLIST_DIR
file mkdir $LOG_DIR
file mkdir $WORK_DIR

# ---------------------------------------------------------
# 3) Library setup
# ---------------------------------------------------------
set_db init_lib_search_path [list $LIB_DIR]
set_db library $LIB_FILES

# ---------------------------------------------------------
# 4) Read RTL
# Filelist entries are ../../00_src/*.sv
# => phai cd vao 04_syn/filelist truoc khi read_hdl
# ---------------------------------------------------------
set OLD_PWD [pwd]
cd $FILELIST_DIR

read_hdl -sv -f filelist_syn.f

cd $OLD_PWD

elaborate $TOP_MODULE
current_design $TOP_MODULE

check_design > [file join $REPORT_DIR check_design.rpt]

# ---------------------------------------------------------
# 5) Read constraints
# ---------------------------------------------------------
read_sdc $SDC_FILE

# ---------------------------------------------------------
# 6) Synthesis
# ---------------------------------------------------------
syn_generic
syn_map
syn_opt

# ---------------------------------------------------------
# 7) Reports
# ---------------------------------------------------------
report_qor                  > [file join $REPORT_DIR qor.rpt]
report_area                 > [file join $REPORT_DIR area.rpt]
report_gates                > [file join $REPORT_DIR gates.rpt]
report_timing -max_paths 20 > [file join $REPORT_DIR timing.rpt]

catch {report_power > [file join $REPORT_DIR power.rpt]}

# ---------------------------------------------------------
# 8) Outputs
# ---------------------------------------------------------
write_hdl > [file join $NETLIST_DIR ${TOP_MODULE}_syn.v]
catch {write_sdc > [file join $NETLIST_DIR ${TOP_MODULE}_syn_out.sdc}]}

puts "========================================================="
puts "SYNTHESIS DONE"
puts "Netlist : [file join $NETLIST_DIR ${TOP_MODULE}_syn.v]"
puts "Reports : $REPORT_DIR"
puts "========================================================="

quit