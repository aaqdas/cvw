##############################################################################
## 			Parameterized Synthesis
##############################################################################

##############################################################################
## Set Paths 
##############################################################################
set DESIGN dcache_wrapper  
set TOP_LEVEL dcache_wrapper
set HOME_DIR "[exec pwd]"
set RPT_DIR  "${HOME_DIR}/cadence/reports/"
set RTL_DIR "${HOME_DIR}/rtl"
set LIB_DIR "/home/min/a/aaqdas/Documents/aes_build/asap7nm/frontend/lib/"
set LEF_DIR "/home/min/a/aaqdas/Documents/aes_build/asap7nm/backend/lef/"
set VCD_PATH "${HOME_DIR}/../gate_sim/dut.shm"
set FRONTEND_DIR "/home/min/a/aaqdas/Documents/aes_build/asap7nm/frontend/Verilog/"
set_db lp_power_unit mW 
set_db lib_search_path $LIB_DIR
set_db init_hdl_search_path $RTL_DIR

# Clock Pin Name
set CLK "clk"
# Clock Period in Picoseconds
set CLK_PERIOD 588


set LIB_LIST { \
    /home/min/a/aaqdas/Documents/aes_build/asap7nm/frontend/lib/asap7sc7p5t_AO_LVT_TT_nldm_211120.lib \
    /home/min/a/aaqdas/Documents/aes_build/asap7nm/frontend/lib/asap7sc7p5t_INVBUF_LVT_TT_nldm_220122.lib \
    /home/min/a/aaqdas/Documents/aes_build/asap7nm/frontend/lib/asap7sc7p5t_OA_LVT_TT_nldm_211120.lib \
    /home/min/a/aaqdas/Documents/aes_build/asap7nm/frontend/lib/asap7sc7p5t_SEQ_LVT_TT_nldm_220123.lib \
    /home/min/a/aaqdas/Documents/aes_build/asap7nm/frontend/lib/asap7sc7p5t_SIMPLE_LVT_TT_nldm_211120.lib \
}
set LEF_LIST { \
    /home/min/a/aaqdas/Documents/aes_build/asap7nm/backend/lef/asap7_tech_1x_201209.lef \
    /home/min/a/aaqdas/Documents/aes_build/asap7nm/backend/lef/asap7sc7p5t_28_L_1x_220121a.lef \
}



if {[file isdirectory ${RTL_DIR}]} {
    file delete -force ${RTL_DIR}
}
file mkdir ${RTL_DIR}

eval file copy -force [glob ${HOME_DIR}/../../../src/*/*.sv] {${HOME_DIR}/rtl/}
eval file copy -force [glob ${HOME_DIR}/../../../src/*/*/*.sv] {${HOME_DIR}/rtl/}
eval file copy -force [glob ${HOME_DIR}/../../synthesis/include/*.vh] {${HOME_DIR}/rtl/}
eval file copy -force [glob ${HOME_DIR}/../../synthesis/include/*.sv] {${HOME_DIR}/rtl/}
eval file copy -force [glob ${HOME_DIR}/../../synthesis/alu/cadence/output/alu_wrapper.v] {${HOME_DIR}/rtl/}
eval file copy -force [glob ${HOME_DIR}/../synthesis/dcache/cadence/output/dcache_wrapper.v] {${HOME_DIR}/rtl/}


# set_db verilog_macro {GATE_SIM}
# set RTL_LIST [glob $RTL_DIR/cvw.sv $RTL_DIR/*.sv]
set RTL_LIST $RTL_DIR/${DESIGN}.v
read_libs $LIB_LIST

read_hdl -sv -define GATE_SIM -define JOULES $RTL_LIST
set_db lp_insert_clock_gating true

elaborate ${TOP_LEVEL}
# Design Timing Constraints
# create_clock -period $CLK_PERIOD $CLK
# set_clock_uncertainty 0 [get_clocks $CLK]

write_db -all -to_file ${DESIGN}.joules.flow.elab.db

syn_power -effort high 
read_stimulus -file $VCD_PATH -format shm -dut_instance /testbench/dut/core/lsu/dcache
compute_power -mode time_based
report_power -by_hierarchy > $RPT_DIR/${DESIGN}_power_hierarchy.joules.rpt

write_db -all -to_file ${DESIGN}.joules.flow.proto.db