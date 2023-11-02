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

import kek_bpm_rfsoc_dev                     as rfsoc
import axi_soc_ultra_plus_core.rfsoc_utility as rfsoc_utility
import surf.axi                              as axi

class Application(pr.Device):
    def __init__(self,sampleRate=0.0,**kwargs):
        super().__init__(**kwargs)

        self.add(rfsoc_utility.SigGen(
            name         = 'DacSigGen',
            offset       = 0x01_000000,
            numCh        = 4, # Must match NUM_CH_G config
            ramWidth     = 9, # Must match RAM_ADDR_WIDTH_G config
            smplPerCycle = 4, # Must match SAMPLE_PER_CYCLE_G config
            expand       = False,
        ))

        self.add(rfsoc.SigGenLoader(
            name         = 'DacSigGenLoader',
            DacSigGen    = self.DacSigGen,
            expand       = False,
        ))

        self.add(rfsoc.ReadoutCtrl(
            offset     = 0x00_000000,
            sampleRate = sampleRate,
            expand     = True,
        ))
