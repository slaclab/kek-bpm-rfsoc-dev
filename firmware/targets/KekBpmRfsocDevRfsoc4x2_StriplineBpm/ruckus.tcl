# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodule code
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-soc-ultra-plus-core/hardware/RealDigitalRfSoC4x2

# Load common ruckus.tcl files
loadRuckusTcl $::env(TOP_DIR)/shared
loadSource -dir "$::env(TOP_DIR)/shared/rtl/stripline"

# Load local source Code and constraints
loadSource      -dir  "$::DIR_PATH/hdl"
loadConstraints -dir  "$::DIR_PATH/hdl"

# Shared RFSoC4x2 code/modules
loadSource -path "$::DIR_PATH/../KekBpmRfsocDevRfsoc4x2_BOR/hdl/AxiFifoAndResizerWrapper.vhd"
loadSource -path "$::DIR_PATH/../KekBpmRfsocDevRfsoc4x2_BOR/hdl/RfDataConverter.vhd"
loadIpCore -dir  "$::DIR_PATH/../KekBpmRfsocDevRfsoc4x2_BOR/ip"
