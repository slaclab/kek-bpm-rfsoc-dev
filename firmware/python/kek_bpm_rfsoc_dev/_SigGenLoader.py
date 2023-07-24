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

        self.add(pr.LocalVariable(
            name         = 'RectPulseDuration',
            description  = 'Sets the I/Q pulse duration using the LoadRectFunction()',
            typeStr      = 'Int16[np]',
            units        = 'clock cycles',
            value        = 256,
        ))

        self.add(pr.LocalVariable(
            name        = 'RectPulseAmplitude',
            description = 'Sets the I/Q pulse amplitude using the LoadRectFunction()',
            typeStr     = 'Int16[np]',
            units       = 'counts',
            value       = 10000,
        ))

        self.add(pr.LocalVariable(
            name        = 'TestPulseAmplitude',
            description = 'Sets the I/Q pulse amplitude using the LoadRectFunction()',
            typeStr     = 'Int16[np]',
            units       = 'counts',
            value       = 30000,
        ))

        @self.command()
        def LoadRectFunction():
            click.secho(f'{self.path}.LoadRectFunction()', fg='green')
            I = np.zeros(shape=self.length, dtype=np.int32, order='C')
            Q = np.zeros(shape=self.length, dtype=np.int32, order='C')

            # Generate the waveform
            for i in range(self.length):
                if (i < self.RectPulseDuration.value()):
                    I[i] = self.RectPulseAmplitude.value()
                    Q[i] = self.RectPulseAmplitude.value()
                else:
                    I[i] = 0
                    Q[i] = 0

            # Write the waveforms to hardware
            for x in range(self.DacSigGen.numCh//2):
                self.DacSigGen.Waveform[2*x+0].set(I)
                self.DacSigGen.Waveform[2*x+1].set(Q)

            # Update the BufferLength register to be normalized to smplPerCycle (zero inclusive)
            self.DacSigGen.BufferLength.set((self.length//self.DacSigGen.smplPerCycle)-1)

            # Toggle flags (if flags already active)
            self.DacSigGen.RefreshDacFsm()

        @self.command()
        def LoadTriangleFunction():
            click.secho(f'{self.path}.LoadTriangleFunction()', fg='green')
            I = np.zeros(shape=self.length, dtype=np.int32, order='C')
            Q = np.zeros(shape=self.length, dtype=np.int32, order='C')

            # Generate the waveform
            for i in range(self.length):
                if (i < self.RectPulseDuration.value()):
                    I[i] = i*100
                    Q[i] = 1000
                else:
                    I[i] = 0
                    Q[i] = 0

            # Write the waveforms to hardware
            for x in range(self.DacSigGen.numCh//2):
                self.DacSigGen.Waveform[2*x+0].set(I)
                self.DacSigGen.Waveform[2*x+1].set(Q)

            # Update the BufferLength register to be normalized to smplPerCycle (zero inclusive)
            self.DacSigGen.BufferLength.set((self.length//self.DacSigGen.smplPerCycle)-1)

            # Toggle flags (if flags already active)
            self.DacSigGen.RefreshDacFsm()

        @self.command()
        def LoadTestFunction():
            click.secho(f'{self.path}.LoadTestFunction()', fg='green')
            I = np.zeros(shape=self.length, dtype=np.int32, order='C')
            Q = np.zeros(shape=self.length, dtype=np.int32, order='C')

            A = self.TestPulseAmplitude.value()
            B = 100 # decay time
            C = 200 # Rise time

            # Generate the waveform
            for i in range(self.length):
                T = float(i)
                I[i] = A*np.exp(-1.0*T/B)*(1-np.exp(-1.0*T/C))
                Q[i] = A*np.exp(-1.0*T/B)*(1-np.exp(-1.0*T/C))

            # Write the waveforms to hardware
            for x in range(self.DacSigGen.numCh//2):
                self.DacSigGen.Waveform[2*x+0].set(I)
                self.DacSigGen.Waveform[2*x+1].set(Q)

            # Update the BufferLength register to be normalized to smplPerCycle (zero inclusive)
            self.DacSigGen.BufferLength.set((self.length//self.DacSigGen.smplPerCycle)-1)

            # Toggle flags (if flags already active)
            self.DacSigGen.RefreshDacFsm()
