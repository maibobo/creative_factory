# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "CH_BUF_LEN" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PROG_TIME" -parent ${Page_0}
  ipgui::add_param $IPINST -name "VERSION" -parent ${Page_0}


}

proc update_PARAM_VALUE.CH_BUF_LEN { PARAM_VALUE.CH_BUF_LEN } {
	# Procedure called to update CH_BUF_LEN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CH_BUF_LEN { PARAM_VALUE.CH_BUF_LEN } {
	# Procedure called to validate CH_BUF_LEN
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.PROG_TIME { PARAM_VALUE.PROG_TIME } {
	# Procedure called to update PROG_TIME when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PROG_TIME { PARAM_VALUE.PROG_TIME } {
	# Procedure called to validate PROG_TIME
	return true
}

proc update_PARAM_VALUE.VERSION { PARAM_VALUE.VERSION } {
	# Procedure called to update VERSION when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.VERSION { PARAM_VALUE.VERSION } {
	# Procedure called to validate VERSION
	return true
}


proc update_MODELPARAM_VALUE.VERSION { MODELPARAM_VALUE.VERSION PARAM_VALUE.VERSION } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.VERSION}] ${MODELPARAM_VALUE.VERSION}
}

proc update_MODELPARAM_VALUE.PROG_TIME { MODELPARAM_VALUE.PROG_TIME PARAM_VALUE.PROG_TIME } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PROG_TIME}] ${MODELPARAM_VALUE.PROG_TIME}
}

proc update_MODELPARAM_VALUE.CH_BUF_LEN { MODELPARAM_VALUE.CH_BUF_LEN PARAM_VALUE.CH_BUF_LEN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CH_BUF_LEN}] ${MODELPARAM_VALUE.CH_BUF_LEN}
}

proc update_MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH}
}

