# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodule code
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-soc-ultra-plus-core/hardware/XilinxZcu111

# Load common ruckus.tcl files
loadRuckusTcl $::env(TOP_DIR)/shared

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadSource      -dir "$::DIR_PATH/../KekBpmRfsocDevZcu111_4072MSPS/shared"
loadConstraints -dir "$::DIR_PATH/../KekBpmRfsocDevZcu111_4072MSPS/shared"

# Load IP cores
loadIpCore -dir "$::DIR_PATH/../KekBpmRfsocDevZcu111_4072MSPS/ip"

# Set the top level simulation
set_property top {AxiStreamRingBufferTb} [get_filesets sim_1]
