# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodule code
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-soc-ultra-plus-core/hardware/XilinxZcu111

# Load RTL code
loadSource -dir  "$::DIR_PATH/rtl"

# Load IP cores
loadIpCore -dir "$::DIR_PATH/ip"

# Load model composer .ZIP output file
if { [get_ips ssr_ddc_0] eq ""  } {
   loadZipIpCore  -repo_path $::env(IP_REPO) -dir "$::DIR_PATH/model_composer/SSR_Digital_Down_Conversion/netlist/ip"
   create_ip -name ssr_ddc -vendor SLAC -library KEK_BPM -version 1.0 -module_name ssr_ddc_0
}

# Updating the impl_1 strategy
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

# Updating target langage
set_property target_language Verilog [current_project]
