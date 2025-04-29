
# Genus Synthesis Flow
# aaqdas@purdue.edu Apr 18, 2025


# *********************************************************
# Synthesis of Wally Core
# *********************************************************
set t1 [clock seconds]
# Set Maximum CPUs for Synthesis
set_db max_cpus_per_server 16

# Get Environemnt Variables
set outputDir $::env(OUTPUTDIR)
set cfg $::env(CONFIGDIR)
set hdl_src "../src"
set maxopt $::env(MAXOPT)
set drive $::env(DRIVE)
set width $::env(WIDTH)

set_db hdl_parameter_naming_style "" 

eval file copy -force [glob ${cfg}/*.vh] {$outputDir/hdl/}
eval file copy -force [glob ${hdl_src}/cvw.sv] {$outputDir/hdl/}
eval file copy -force [glob ${hdl_src}/*/*.sv] {$outputDir/hdl/}
eval file copy -force [glob ${hdl_src}/*/*/*.sv] {$outputDir/hdl/}

set LIB_DIR  "/package/eda/cells/FreePDK15/NanGate_15nm_OCL_v0.1_2014_06_Apache.A/front_end/timing_power_noise/CCS/"
set LEF_DIR "/package/eda/cells/FreePDK15/NanGate_15nm_OCL_v0.1_2014_06_Apache.A/back_end/lef/"
set LEF_LIST { \
    /package/eda/cells/FreePDK15/NanGate_15nm_OCL_v0.1_2014_06_Apache.A/back_end/lef/NanGate_15nm_OCL.tech.lef \
    /package/eda/cells/FreePDK15/NanGate_15nm_OCL_v0.1_2014_06_Apache.A/back_end/lef/NanGate_15nm_OCL.macro.lef \
}

# Check if a wrapper is needed and create it (to pass parameters when cvw_t parameters are used)
set wrapper 0
if {[catch {eval exec grep "cvw_t" $outputDir/hdl/$::env(DESIGN).sv}] == 0} {
    echo "Creating wrapper"
    set wrapper 1
    # make the wrapper
	exec python3 $::env(WALLY)/synthDC/scripts/wrapperGen.py $::env(DESIGN) $outputDir/hdl
}

# Verilog files
set my_verilog_files [glob $outputDir/hdl/cvw.sv $outputDir/hdl/*.sv]

# Set toplevel
if { $wrapper == 1 } {
    set my_toplevel $::env(DESIGN)wrapper
} else {
    set my_toplevel $::env(DESIGN)
}
set my_design $::env(DESIGN)

set_db timing_time_unit 1ps
set_db max_cpus_per_server 16
set_db information_level 9
set_db auto_ungroup none

# Track filename with rows and columns for error reporting
set_db hdl_track_filename_row_col true

# Specifying Technology Library Path
set_db init_lib_search_path $LIB_DIR

# Specify RTL Directory Paths
set_db init_hdl_search_path $outputDir/hdl

# Preserve All Nets and Registers


# set_db preserve size_ok

# *********************************************************
# Set Variables For Quick Modifications
# *********************************************************

set rpt_dir  "${outputDir}/reports/"

    set designname [format "%s%s" $my_design "wrapper"]
    set top_level $designname

    # Specify Technology Library Files
    set_db library $LIB_DIR/NanGate_15nm_OCL_typical_conditional_ccs.lib

    # Read Libs
    read_libs $LIB_DIR/NanGate_15nm_OCL_typical_conditional_ccs.lib

    # Read Physical Parameters for Better Estimate
    read_physical -lefs $LEF_LIST

    # Specify RTL Files 
    read_hdl -sv $my_verilog_files

    # Elaborating Top Level Design 
    elaborate $top_level

    # Checking for Unresolved Issues After Elaborating
    check_design -unresolved

    check_timing_intent

    read_stimulus -file /home/min/a/aaqdas/Documents/cvw/sim/xcelium/testbench.fsdb

# Set Frequency in [MHz] or period in [ns]
set my_clock_pin clk
set my_uncertainty 0.0
set my_clk_freq_MHz $::env(FREQ)
# period in picoseconds
set my_period [expr 1000000.0 / $my_clk_freq_MHz] 

# Create clock object 
set find_clock [ get_ports $my_clock_pin]
if {  $find_clock != [list] } {
    echo "Found clock!"
    set my_clk $my_clock_pin
    create_clock -period $my_period $my_clk
    set_clock_uncertainty $my_uncertainty [get_clocks $my_clk]
 } else {
    echo "Did not find clock! Design is probably combinational!"
    set my_clk vclk
    create_clock -period $my_period -name $my_clk
}


# Optimize paths that are close to critical
# set_critical_range 0.05 $top_level
# set all_in_ex_clk [remove_from_collection [all_inputs] [get_ports $my_clk]]
puts "All inputs: [get_ports -filter {direction == in}]"

set all_in_ex_clk [get_ports -filter {direction == in && name !~ "clk"}]

set_max_fanout 16 $all_in_ex_clk
# Set input/output delay
if {$drive == "FLOP"} {
    set_input_delay  -max 0.0 -clock $my_clk $all_in_ex_clk
    set_output_delay -max 0.0 -clock $my_clk [all_outputs]
} else {
    set_input_delay -max 0.0 -clock $my_clk $all_in_ex_clk
    set_output_delay -max 0.0 -clock $my_clk [all_outputs]
}


# Report on DESIGN, not wrapper.  However, design has a suffix for the parameters.
if { $wrapper == 1 } {

    # recreate clock below wrapper level or reporting doesn't work properly
    set find_clock [get_ports $my_clock_pin]
    if {  $find_clock != [list] } {
        echo "Found clock!"
        set my_clk $my_clock_pin
        create_clock -period $my_period $my_clk
        set_clock_uncertainty $my_uncertainty [get_clocks $my_clk]
    } else {
        echo "Did not find clock! Design is probably combinational!"
        set my_clk vclk
        create_clock -period $my_period -name $my_clk
    }
} 




# Generic Synthesis
syn_generic
write_snapshot -outdir $rpt_dir -tag generic
report_summary -directory $rpt_dir
puts "Runtime and Memory after syn_generic"
time_info GENERIC

# Synthesis to Mapped Gates
syn_map
write_snapshot -outdir $rpt_dir -tag map
report_summary -directory $rpt_dir
puts "Runtime and Memory after syn_map"
time_info MAPPED

# Synthesis Optimizations
syn_opt
report_timing > ${rpt_dir}/final_timing.rpt
report_area   > ${rpt_dir}/final_area.rpt

write_snapshot -outdir $rpt_dir -tag syn_opt
report_summary -directory $rpt_dir
puts "Runtime and Memory after syn_opt"
time_info OPT

compute_power -mode time_based

write_snapshot -outdir $rpt_dir -tag final
report_power -by_hierarchy > ${rpt_dir}/final_static_power.rpt/
report_summary -directory $rpt_dir
report_units > ${rpt_dir}/final_units.rpt

write_hdl > ${outputDir}/mapped/wallypipelinedcore.sv

report_power -module alu > ${rpt_dir}/alu_power.rpt
report_power -module dcache > ${rpt_dir}/dcache_power.rpt
report_power -inst /wallypipelinedcorewrapper/dut/lsu/dcache > ${rpt_dir}/dcache_inst_power.rpt
report_power -inst /wallypipelinedcorewrapper/dut/ieu/dp/alu > ${rpt_dir}/alu_inst_power.rpt
# end run clock and echo run time in minutes
set t2 [clock seconds]
set t [expr $t2 - $t1]
echo [expr $t/60]

quit 

