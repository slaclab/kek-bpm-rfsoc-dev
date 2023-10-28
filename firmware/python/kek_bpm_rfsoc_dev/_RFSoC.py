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
    def __init__(self,boardType='',sampleRate=0.0,**kwargs):
        super().__init__(**kwargs)

        self.add(socCore.AxiSocCore(
            offset       = 0x0000_0000,
            numDmaLanes  = 1,
            # expand       = True,
        ))

        # Check for ZCU111
        if (boardType == 'zcu111'):

            self.add(xilinxZcu111.Hardware(
                offset       = 0x8000_0000,
                # expand       = True,
            ))

            self.add(xil.RfDataConverter(
                offset    = 0x9000_0000,
                gen3      = False, # True if using RFSoC GEN3 Hardware
                enAdcTile = [True,True,False,False],   # adcTile[0,1]
                enDacTile = [False,True,False,False],  # dacTile[1]
                # expand       = True,
            ))

            # SOFTWARE VARIABLE ONLY!!! (doesn't change sampling speed, used for calculation)
            self.RfDataConverter.dacTile[1].dacBlock[1].samplingRate._default = 4072.0 # In units of MHz,

        # Else rfsoc4x2 board
        else:

            self.add(xil.RfDataConverter(
                offset    = 0x9000_0000,
                gen3      = True, # True if using RFSoC GEN3 Hardware
                enAdcTile = [True,False,True,False], # adcTile[0,2]
                enDacTile = [True,False,True,False], # dacTile[0,2]
                # expand    = True,
            ))

            # SOFTWARE VARIABLE ONLY!!! (doesn't change sampling speed, used for calculation)
            for i in [0,2]:
                self.RfDataConverter.dacTile[i].dacBlock[0].samplingRate._default = 4072.0 # In units of MHz,

        self.add(rfsoc.Application(
            offset     = 0xA000_0000,
            sampleRate = sampleRate,
            expand     = True,
        ))
