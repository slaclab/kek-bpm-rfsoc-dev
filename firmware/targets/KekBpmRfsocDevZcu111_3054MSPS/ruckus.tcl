# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodule code
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-soc-ultra-plus-core/hardware/XilinxZcu111

# Load common ruckus.tcl files
loadRuckusTcl $::env(TOP_DIR)/shared

# Load model composer .ZIP output file
if { [get_ips ssr_ddc_0] eq ""  } {
   loadZipIpCore  -repo_path $::env(IP_REPO) -dir "$::env(TOP_DIR)/shared/model_composer/SSR12_Digital_Down_Conversion/netlist/ip"
   create_ip -name ssr_ddc -vendor SLAC -library KEK_BPM -version 1.0 -module_name ssr_ddc_0
}

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/rtl"
loadSource      -dir "$::DIR_PATH/shared"
loadConstraints -dir "$::DIR_PATH/shared"

# Load IP cores
loadIpCore -dir "$::DIR_PATH/ip"
