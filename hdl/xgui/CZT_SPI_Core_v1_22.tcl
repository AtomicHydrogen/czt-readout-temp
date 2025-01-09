# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "OUT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "alert_bits" -parent ${Page_0}
  ipgui::add_param $IPINST -name "czt_spi_clk_ratio" -parent ${Page_0}
  ipgui::add_param $IPINST -name "data_in_size" -parent ${Page_0}
  ipgui::add_param $IPINST -name "fifo_size" -parent ${Page_0}
  ipgui::add_param $IPINST -name "limit" -parent ${Page_0}
  ipgui::add_param $IPINST -name "packet_in" -parent ${Page_0}
  ipgui::add_param $IPINST -name "packet_length" -parent ${Page_0}
  ipgui::add_param $IPINST -name "packet_out" -parent ${Page_0}
  ipgui::add_param $IPINST -name "packet_size_rx" -parent ${Page_0}
  ipgui::add_param $IPINST -name "packet_size_tx" -parent ${Page_0}
  ipgui::add_param $IPINST -name "timestamp_size" -parent ${Page_0}


}

proc update_PARAM_VALUE.OUT_WIDTH { PARAM_VALUE.OUT_WIDTH } {
	# Procedure called to update OUT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OUT_WIDTH { PARAM_VALUE.OUT_WIDTH } {
	# Procedure called to validate OUT_WIDTH
	return true
}

proc update_PARAM_VALUE.alert_bits { PARAM_VALUE.alert_bits } {
	# Procedure called to update alert_bits when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.alert_bits { PARAM_VALUE.alert_bits } {
	# Procedure called to validate alert_bits
	return true
}

proc update_PARAM_VALUE.czt_spi_clk_ratio { PARAM_VALUE.czt_spi_clk_ratio } {
	# Procedure called to update czt_spi_clk_ratio when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.czt_spi_clk_ratio { PARAM_VALUE.czt_spi_clk_ratio } {
	# Procedure called to validate czt_spi_clk_ratio
	return true
}

proc update_PARAM_VALUE.data_in_size { PARAM_VALUE.data_in_size } {
	# Procedure called to update data_in_size when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.data_in_size { PARAM_VALUE.data_in_size } {
	# Procedure called to validate data_in_size
	return true
}

proc update_PARAM_VALUE.fifo_size { PARAM_VALUE.fifo_size } {
	# Procedure called to update fifo_size when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.fifo_size { PARAM_VALUE.fifo_size } {
	# Procedure called to validate fifo_size
	return true
}

proc update_PARAM_VALUE.limit { PARAM_VALUE.limit } {
	# Procedure called to update limit when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.limit { PARAM_VALUE.limit } {
	# Procedure called to validate limit
	return true
}

proc update_PARAM_VALUE.packet_in { PARAM_VALUE.packet_in } {
	# Procedure called to update packet_in when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.packet_in { PARAM_VALUE.packet_in } {
	# Procedure called to validate packet_in
	return true
}

proc update_PARAM_VALUE.packet_length { PARAM_VALUE.packet_length } {
	# Procedure called to update packet_length when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.packet_length { PARAM_VALUE.packet_length } {
	# Procedure called to validate packet_length
	return true
}

proc update_PARAM_VALUE.packet_out { PARAM_VALUE.packet_out } {
	# Procedure called to update packet_out when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.packet_out { PARAM_VALUE.packet_out } {
	# Procedure called to validate packet_out
	return true
}

proc update_PARAM_VALUE.packet_size_rx { PARAM_VALUE.packet_size_rx } {
	# Procedure called to update packet_size_rx when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.packet_size_rx { PARAM_VALUE.packet_size_rx } {
	# Procedure called to validate packet_size_rx
	return true
}

proc update_PARAM_VALUE.packet_size_tx { PARAM_VALUE.packet_size_tx } {
	# Procedure called to update packet_size_tx when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.packet_size_tx { PARAM_VALUE.packet_size_tx } {
	# Procedure called to validate packet_size_tx
	return true
}

proc update_PARAM_VALUE.timestamp_size { PARAM_VALUE.timestamp_size } {
	# Procedure called to update timestamp_size when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.timestamp_size { PARAM_VALUE.timestamp_size } {
	# Procedure called to validate timestamp_size
	return true
}


proc update_MODELPARAM_VALUE.packet_size_tx { MODELPARAM_VALUE.packet_size_tx PARAM_VALUE.packet_size_tx } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.packet_size_tx}] ${MODELPARAM_VALUE.packet_size_tx}
}

proc update_MODELPARAM_VALUE.packet_size_rx { MODELPARAM_VALUE.packet_size_rx PARAM_VALUE.packet_size_rx } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.packet_size_rx}] ${MODELPARAM_VALUE.packet_size_rx}
}

proc update_MODELPARAM_VALUE.packet_length { MODELPARAM_VALUE.packet_length PARAM_VALUE.packet_length } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.packet_length}] ${MODELPARAM_VALUE.packet_length}
}

proc update_MODELPARAM_VALUE.timestamp_size { MODELPARAM_VALUE.timestamp_size PARAM_VALUE.timestamp_size } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.timestamp_size}] ${MODELPARAM_VALUE.timestamp_size}
}

proc update_MODELPARAM_VALUE.data_in_size { MODELPARAM_VALUE.data_in_size PARAM_VALUE.data_in_size } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.data_in_size}] ${MODELPARAM_VALUE.data_in_size}
}

proc update_MODELPARAM_VALUE.fifo_size { MODELPARAM_VALUE.fifo_size PARAM_VALUE.fifo_size } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.fifo_size}] ${MODELPARAM_VALUE.fifo_size}
}

proc update_MODELPARAM_VALUE.packet_in { MODELPARAM_VALUE.packet_in PARAM_VALUE.packet_in } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.packet_in}] ${MODELPARAM_VALUE.packet_in}
}

proc update_MODELPARAM_VALUE.packet_out { MODELPARAM_VALUE.packet_out PARAM_VALUE.packet_out } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.packet_out}] ${MODELPARAM_VALUE.packet_out}
}

proc update_MODELPARAM_VALUE.limit { MODELPARAM_VALUE.limit PARAM_VALUE.limit } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.limit}] ${MODELPARAM_VALUE.limit}
}

proc update_MODELPARAM_VALUE.OUT_WIDTH { MODELPARAM_VALUE.OUT_WIDTH PARAM_VALUE.OUT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OUT_WIDTH}] ${MODELPARAM_VALUE.OUT_WIDTH}
}

proc update_MODELPARAM_VALUE.alert_bits { MODELPARAM_VALUE.alert_bits PARAM_VALUE.alert_bits } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.alert_bits}] ${MODELPARAM_VALUE.alert_bits}
}

proc update_MODELPARAM_VALUE.czt_spi_clk_ratio { MODELPARAM_VALUE.czt_spi_clk_ratio PARAM_VALUE.czt_spi_clk_ratio } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.czt_spi_clk_ratio}] ${MODELPARAM_VALUE.czt_spi_clk_ratio}
}

