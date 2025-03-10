# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodule code
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-soc-ultra-plus-core/hardware/XilinxZcu208

# Load common ruckus.tcl files
loadRuckusTcl $::env(TOP_DIR)/shared
loadSource -dir "$::env(TOP_DIR)/shared/rtl/bor"

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadConstraints -dir "$::DIR_PATH/hdl"

# Load IP cores
loadIpCore -dir "$::DIR_PATH/ip"
