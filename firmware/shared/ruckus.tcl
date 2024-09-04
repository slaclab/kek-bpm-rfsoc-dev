# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load RTL code
loadSource -dir  "$::DIR_PATH/rtl"

# Load model composer .ZIP output file
if { [get_ips poscalc_0] eq ""  } {
   loadZipIpCore  -repo_path $::env(IP_REPO) -dir "$::DIR_PATH/model_composer/Position_calculation/netlist/ip"
   create_ip -name poscalc -vendor SLAC -library KEK_BPM -version 1.0 -module_name poscalc_0
}

# Load model composer .ZIP output file
if { [get_ips abort_issue_0] eq ""  } {
   loadZipIpCore  -repo_path $::env(IP_REPO) -dir "$::DIR_PATH/model_composer/Abort_issue/netlist/ip"
   create_ip -name poscalc -vendor SLAC -library KEK_BPM -version 1.0 -module_name abort_issue_0
}

# Updating the impl_1 strategy
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
