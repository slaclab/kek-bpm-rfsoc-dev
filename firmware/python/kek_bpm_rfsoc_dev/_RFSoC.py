#-----------------------------------------------------------------------------
# This file is part of the 'kek_bpm_rfsoc_dev'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'kek_bpm_rfsoc_dev', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

import axi_soc_ultra_plus_core                       as socCore
import axi_soc_ultra_plus_core.hardware.XilinxZcu111 as xilinxZcu111
import surf.xilinx                                   as xil
import kek_bpm_rfsoc_dev                             as rfsoc

class RFSoC(pr.Device):
    def __init__(self,**kwargs):
        super().__init__(**kwargs)

        self.add(socCore.AxiSocCore(
            offset       = 0x0000_0000,
            numDmaLanes  = 2,
            # expand       = True,
        ))

        self.add(xilinxZcu111.Hardware(
            offset       = 0x8000_0000,
            # expand       = True,
        ))

        self.add(xil.RfDataConverter(
            offset    = 0x9000_0000,
            gen3      = False, # True if using RFSoC GEN3 Hardware
            enAdcTile = [False,True,False,False], # adcTile[1] only
            enDacTile = [False,True,False,False], # dacTile[1] only
            expand       = True,
        ))

        # Hide the unused RF blocks
        self.RfDataConverter.adcTile[1].adcBlock[0].hidden = True
        self.RfDataConverter.adcTile[1].adcBlock[1].hidden = True
        self.RfDataConverter.dacTile[1].dacBlock[0].hidden = True
        self.RfDataConverter.dacTile[1].dacBlock[2].hidden = True
        self.RfDataConverter.dacTile[1].dacBlock[3].hidden = True

        # SOFTWARE VARIABLE ONLY!!! (doesn't change sampling speed, used for calculation)
        self.RfDataConverter.adcTile[1].adcBlock[2].samplingRate._default = 4072.0 # In units of MHz,
        self.RfDataConverter.adcTile[1].adcBlock[3].samplingRate._default = 4072.0 # In units of MHz,
        self.RfDataConverter.dacTile[1].dacBlock[1].samplingRate._default = 4072.0 # In units of MHz,

        self.add(rfsoc.Application(
            offset       = 0xA000_0000,
            expand       = True,
        ))
