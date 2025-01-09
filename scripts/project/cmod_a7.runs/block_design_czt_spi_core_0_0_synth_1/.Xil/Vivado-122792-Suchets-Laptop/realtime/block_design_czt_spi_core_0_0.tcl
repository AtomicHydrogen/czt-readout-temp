# 
# Synthesis run script generated by Vivado
# 

namespace eval rt {
    variable rc
}
set rt::rc [catch {
  uplevel #0 {
    set ::env(BUILTIN_SYNTH) true
    source $::env(HRT_TCL_PATH)/rtSynthPrep.tcl
    rt::HARTNDb_resetJobStats
    rt::HARTNDb_resetSystemStats
    rt::HARTNDb_startSystemStats
    rt::HARTNDb_startJobStats
    set rt::cmdEcho 0
    rt::set_parameter writeXmsg true
    rt::set_parameter enableParallelHelperSpawn true
    set ::env(RT_TMP) "c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.runs/block_design_czt_spi_core_0_0_synth_1/.Xil/Vivado-122792-Suchets-Laptop/realtime/tmp"
    if { [ info exists ::env(RT_TMP) ] } {
      file delete -force $::env(RT_TMP)
      file mkdir $::env(RT_TMP)
    }

    rt::delete_design

    rt::set_parameter datapathDensePacking false
    set rt::partid xc7a35tcpg236-1
    source $::env(HRT_TCL_PATH)/rtSynthParallelPrep.tcl
     file delete -force synth_hints.os

    set rt::multiChipSynthesisFlow false
    source $::env(SYNTH_COMMON)/common.tcl
    set rt::defaultWorkLibName xil_defaultlib

    set rt::useElabCache false
    if {$rt::useElabCache == false} {
      rt::read_verilog -sv C:/Xilinx/Vivado/2022.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv
      rt::read_vhdl -lib xpm C:/Xilinx/Vivado/2022.1/data/ip/xpm/xpm_VCOMP.vhd
      rt::read_vhdl -lib xil_defaultlib {
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/top_level.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/basic_czt_spi.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/clock_counter.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/command_fifo.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/czt_spi_core_2det.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/data_concat.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/data_fifo.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/packet_parity.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/spi_slave.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/spi_slave_tx_sync.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/sync_fifo.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/tx_packetise.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/validate_command.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ipshared/fa6d/watchdog.vhdl}
      {c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.gen/sources_1/bd/block_design/ip/block_design_czt_spi_core_0_0/synth/block_design_czt_spi_core_0_0.vhd}
    }
      rt::filesetChecksum
    }
    rt::set_parameter usePostFindUniquification false
    set rt::top block_design_czt_spi_core_0_0
    rt::set_parameter enableIncremental true
    rt::set_parameter markDebugPreservationLevel "enable"
    set rt::reportTiming false
    rt::set_parameter elaborateOnly true
    rt::set_parameter elaborateRtl true
    rt::set_parameter eliminateRedundantBitOperator false
    rt::set_parameter dataflowBusHighlighting false
    rt::set_parameter generateDataflowBusNetlist false
    rt::set_parameter dataFlowViewInElab false
    rt::set_parameter busViewFixBrokenConnections false
    set_param edifin.funnel true
    rt::set_parameter elaborateRtlOnlyFlow false
    rt::set_parameter writeBlackboxInterface true
    rt::set_parameter merge_flipflops true
    rt::set_parameter srlDepthThreshold 3
    rt::set_parameter rstSrlDepthThreshold 4
# MODE: 
    rt::set_parameter webTalkPath {}
    rt::set_parameter synthDebugLog false
    rt::set_parameter printModuleName false
    rt::set_parameter enableSplitFlowPath "c:/Users/Suchet Gopal/Desktop/cmod_project/scripts/project/cmod_a7.runs/block_design_czt_spi_core_0_0_synth_1/.Xil/Vivado-122792-Suchets-Laptop/"
    set ok_to_delete_rt_tmp true 
    if { [rt::get_parameter parallelDebug] } { 
       set ok_to_delete_rt_tmp false 
    } 
    if {$rt::useElabCache == false} {
        set oldMIITMVal [rt::get_parameter maxInputIncreaseToMerge]; rt::set_parameter maxInputIncreaseToMerge 1000
        set oldCDPCRL [rt::get_parameter createDfgPartConstrRecurLimit]; rt::set_parameter createDfgPartConstrRecurLimit 1
        $rt::db readXRFFile
      rt::run_rtlelab -module $rt::top
        rt::set_parameter maxInputIncreaseToMerge $oldMIITMVal
        rt::set_parameter createDfgPartConstrRecurLimit $oldCDPCRL
    }

    set rt::flowresult [ source $::env(SYNTH_COMMON)/flow.tcl ]
    rt::HARTNDb_stopJobStats
    if { $rt::flowresult == 1 } { return -code error }


    if { [ info exists ::env(RT_TMP) ] } {
      if { [info exists ok_to_delete_rt_tmp] && $ok_to_delete_rt_tmp } { 
        file delete -force $::env(RT_TMP)
      }
    }

    source $::env(HRT_TCL_PATH)/rtSynthCleanup.tcl
  } ; #end uplevel
} rt::result]

if { $rt::rc } {
  $rt::db resetHdlParse
  set hsKey [rt::get_parameter helper_shm_key] 
  if { $hsKey != "" && [info exists ::env(BUILTIN_SYNTH)] && [rt::get_parameter enableParallelHelperSpawn] } { 
     $rt::db killSynthHelper $hsKey
  } 
  source $::env(HRT_TCL_PATH)/rtSynthCleanup.tcl
  return -code "error" $rt::result
}
