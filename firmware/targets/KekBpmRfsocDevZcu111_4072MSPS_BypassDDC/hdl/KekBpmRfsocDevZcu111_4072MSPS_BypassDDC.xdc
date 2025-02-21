##############################################################################
## This file is part of 'kek_bpm_rfsoc_dev'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'kek_bpm_rfsoc_dev', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

create_clock -name plClkP -period  1.964 [get_ports {plClkP}]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/REAL_CPU.U_CPU/U_Pll/PllGen.U_Pll/CLKOUT1]] -group [get_clocks -of_objects [get_pins U_RFDC/U_DacPll/PllGen.U_Pll/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/REAL_CPU.U_CPU/U_Pll/PllGen.U_Pll/CLKOUT1]] -group [get_clocks -of_objects [get_pins U_RFDC/U_AdcPll/PllGen.U_Pll/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_RFDC/U_AdcPll/PllGen.U_Pll/CLKOUT1]] -group [get_clocks -of_objects [get_pins U_Core/REAL_CPU.U_CPU/U_Pll/PllGen.U_Pll/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_RFDC/U_AdcPll/PllGen.U_Pll/CLKOUT1]] -group [get_clocks -of_objects [get_pins U_RFDC/U_AdcPll/PllGen.U_Pll/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_RFDC/U_AdcPll/PllGen.U_Pll/CLKOUT1]] -group [get_clocks -of_objects [get_pins U_RFDC/U_DacPll/PllGen.U_Pll/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_RFDC/U_DacPll/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins U_PL_MEM/U_MigCore/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_RFDC/U_AdcPll/PllGen.U_Pll/CLKOUT1]] -group [get_clocks -of_objects [get_pins U_PL_MEM/U_MigCore/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]]

set_property -dict { PULLTYPE PULLDOWN } [get_ports { pmod[0][6] }]
set_property -dict { PULLTYPE PULLDOWN } [get_ports { pmod[0][7] }]

set_property -dict { PULLTYPE PULLDOWN } [get_ports { pmod[1][6] }]
set_property -dict { PULLTYPE PULLDOWN } [get_ports { pmod[1][7] }]

set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_ports pmod[0][7]]

