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
import kek_bpm_rfsoc_dev                             as rfsoc

class RFSoC(pr.Device):
    def __init__(self,
            sampleRate  = 0.0,
            ampDispProc = None,
            SSR         = 16,
            boardType   = None,
        **kwargs):
        super().__init__(**kwargs)

        self.add(socCore.AxiSocCore(
            offset       = 0x0000_0000,
            numDmaLanes  = 1,
            # expand       = True,
        ))

        if boardType == 'Zcu111':
            self.add(xilinxZcu111.Hardware(
                offset       = 0x8000_0000,
                # expand       = True,
            ))

        self.add(rfsoc.Application(
            offset      = 0xA000_0000,
            sampleRate  = sampleRate,
            ampDispProc = ampDispProc,
            SSR         = SSR,
            boardType   = boardType,
            expand      = True,
            enabled     = False, # Do not configure until after LMK/LMX is up
        ))
