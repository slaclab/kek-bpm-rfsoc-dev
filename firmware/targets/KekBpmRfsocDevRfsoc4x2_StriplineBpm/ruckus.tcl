# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodule code
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-soc-ultra-plus-core/hardware/RealDigitalRfSoC4x2

# Load common ruckus.tcl files
loadRuckusTcl $::env(TOP_DIR)/shared
# Load files we want individually to avoid loading shared/.../Application.vhd
# which clashes with the adjusted Application for this target
loadSource -path "$::env(TOP_DIR)/shared/rtl/BypassDDC/DownSampleAdc.vhd"
loadSource -path "$::env(TOP_DIR)/shared/rtl/BypassDDC/SsrDdcWrapper.vhd"

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadConstraints -dir "$::DIR_PATH/hdl"

# Load IP cores
loadIpCore -dir "$::DIR_PATH/ip"
