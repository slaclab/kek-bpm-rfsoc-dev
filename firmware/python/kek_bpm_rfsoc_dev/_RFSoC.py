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

import axi_soc_ultra_plus_core as socCore
import surf.xilinx             as xil
import kek_bpm_rfsoc_dev       as rfsoc

class RFSoC(pr.Device):
    def __init__(self,**kwargs):
        super().__init__(**kwargs)

        self.add(socCore.AxiSocCore(
            offset       = 0x0000_0000,
            numDmaLanes  = 2,
            # expand       = True,
        ))

        self.add(xil.RfDataConverter(
            offset    = 0x9000_0000,
            gen3      = True, # True if using RFSoC GEN3 Hardware
            enAdcTile = [True,False,True,False], # adcTile[0,2] only
            enDacTile = [True,False,True,False], # dacTile[0,2] only
            expand    = True,
        ))

        # Hide the unused RF blocks
        for i in [0,2]:
            for j in [1,2,3]:
                self.RfDataConverter.dacTile[i].dacBlock[j].hidden = True

        # SOFTWARE VARIABLE ONLY!!! (doesn't change sampling speed, used for calculation)
        for i in [0,2]:
            for j in range(4):
                self.RfDataConverter.adcTile[i].adcBlock[j].samplingRate._default = 4072.0 # In units of MHz,
        for i in [0,2]:
            self.RfDataConverter.dacTile[i].dacBlock[0].samplingRate._default = 4072.0 # In units of MHz,

        self.add(rfsoc.Application(
            offset       = 0xA000_0000,
            expand       = True,
        ))
