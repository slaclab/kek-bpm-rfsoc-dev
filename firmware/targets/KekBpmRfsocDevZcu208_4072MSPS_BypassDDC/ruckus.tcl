# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodule code
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-soc-ultra-plus-core/hardware/XilinxZcu208

# Load common ruckus.tcl files
loadRuckusTcl $::env(TOP_DIR)/shared
loadSource -path "$::env(TOP_DIR)/shared/rtl/4072MSPS/Application.vhd"

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadSource     -path "$::DIR_PATH/../KekBpmRfsocDevZcu208_4072MSPS/rtl/RfDataConverter.vhd"
loadConstraints -dir "$::DIR_PATH/../KekBpmRfsocDevZcu208_4072MSPS/rtl"

# Load IP cores
loadIpCore -dir "$::DIR_PATH/../KekBpmRfsocDevZcu208_4072MSPS/ip"

# Set the top level simulation
set_property top {AxiStreamRingBufferTb} [get_filesets sim_1]
