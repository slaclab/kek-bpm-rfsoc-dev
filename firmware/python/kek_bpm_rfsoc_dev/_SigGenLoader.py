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

import numpy as np
import click

class SigGenLoader(pr.Device):
    def __init__(self,DacSigGen=None,**kwargs):
        super().__init__(**kwargs)

        self.DacSigGen = DacSigGen
        self.length    = DacSigGen.smplPerCycle*(2**DacSigGen.ramWidth)

        @self.command()
        def LoadPulseModFunction():
            click.secho(f'{self.path}.LoadPulseModFunction()', fg='green')
            I = np.zeros(shape=self.length, dtype=np.int32, order='C')
            Q = np.zeros(shape=self.length, dtype=np.int32, order='C')

            # Generate the waveform
            for i in range(self.length//8):
                I[8*i+0] = 1000
                I[8*i+1] = 10000
                I[8*i+2] = 20000
                I[8*i+3] = 30000
                I[8*i+4] = 20000
                I[8*i+5] = 10000
                I[8*i+6] = 1000
                I[8*i+7] = 0
            Q = I

            # Write the waveforms to hardware
            for x in range(self.DacSigGen.numCh//2):
                self.DacSigGen.Waveform[2*x+0].set(I)
                self.DacSigGen.Waveform[2*x+1].set(Q)

            # Update the BufferLength register to be normalized to smplPerCycle (zero inclusive)
            self.DacSigGen.BufferLength.set((self.length//self.DacSigGen.smplPerCycle)-1)

            # Toggle flags (if flags already active)
            self.DacSigGen.RefreshDacFsm()
