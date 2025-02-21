##############################################################################
## This file is part of 'kek_bpm_rfsoc_dev'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'kek_bpm_rfsoc_dev', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property PACKAGE_PIN N5 [get_ports { dacClk228P }]
set_property PACKAGE_PIN N4 [get_ports { dacClk228N }]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_RFDC/U_AdcPll/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_RFDC/U_DacPll/PllGen.U_Pll/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_RFDC/U_DacPll/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_Core/REAL_CPU.U_CPU/U_Pll/PllGen.U_Pll/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_RFDC/U_DacPll/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_Core/REAL_CPU.U_CPU/U_Pll/PllGen.U_Pll/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_RFDC/U_DacPll/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_PL_MEM/U_MigCore/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]]
