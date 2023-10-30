##############################################################################
## This file is part of 'kek_bpm_rfsoc_dev'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'kek_bpm_rfsoc_dev', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

######################################################
# Bypass the debug chipscope generation via return cmd
# ELSE ... comment out the return to include chipscope
######################################################
return

############################
## Open the synthesis design
############################
open_run synth_1

###############################
## Set the name of the ILA core
###############################
set ilaName u_ila_0

##################
## Create the core
##################
CreateDebugCore ${ilaName}

#######################
## Set the record depth
#######################
set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaName}]

#################################
## Set the clock for the ILA core
#################################
SetDebugCoreClk ${ilaName} {U_App/dspClk}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {U_App/sigGenTrig[*]}
ConfigProbe ${ilaName} {U_App/adc[0][*]}
ConfigProbe ${ilaName} {U_App/adc[1][*]}
ConfigProbe ${ilaName} {U_App/adc[2][*]}
ConfigProbe ${ilaName} {U_App/adc[3][*]}
ConfigProbe ${ilaName} {U_App/amp[0][*]}
ConfigProbe ${ilaName} {U_App/amp[1][*]}
ConfigProbe ${ilaName} {U_App/amp[2][*]}
ConfigProbe ${ilaName} {U_App/amp[3][*]}

##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName}
