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

class ReadoutCtrl(pr.Device):
    def __init__(self,sampleRate=0.0,ampDispProc=None,SSR=16,**kwargs):
        super().__init__(**kwargs)

        self.smplTime = 1/sampleRate
        self.ampDispProc = ampDispProc

        self.add(pr.RemoteVariable(
            name         = 'LiveDispTrigRaw',
            description  = 'Live Display Trigger',
            offset       = 0x0,
            bitSize      = 1,
            mode         = 'WO',
            hidden       = True,
        ))

        self.add(pr.RemoteVariable(
            name         = 'SwFaultTrigRaw',
            description  = 'Software Fault Trigger',
            offset       = 0x4,
            bitSize      = 1,
            mode         = 'WO',
            hidden       = True,
        ))

        @self.command(hidden=True)
        def LiveDispTrig():
            self.LiveDispTrigRaw.set(1)

        @self.command()
        def SwFaultTrig():
            self.SwFaultTrigRaw.set(1)

        self.add(pr.LocalVariable(
            name   = 'EnableSoftTrig',
            mode   = 'RW',
            value  = False,
            hidden = True,
        ))

        @self.command(description  = 'Force a DAC signal generator trigger from software',hidden=True)
        def getWaveformBurst():
            # Check if data received from all sockets
            if self.ampDispProc[0].NewDataReady.get() and self.ampDispProc[1].NewDataReady.get() and self.ampDispProc[2].NewDataReady.get() and self.ampDispProc[3].NewDataReady.get():
                for i in range(4):
                    self.ampDispProc[i].UpdateWaveform()

            # Check if we are armed for next trigger
            armTrig = True
            for i in range(4):
                if self.ampDispProc[i].NewDataReady.get():
                    armTrig = False

            # Check if we execute software trigger
            if self.EnableSoftTrig.get() and armTrig:
                self.LiveDispTrig()

        self.add(pr.LocalVariable(
            name         = 'GetWaveformBurst',
            mode         = 'RO',
            localGet     = self.getWaveformBurst,
            pollInterval = 1,
            hidden       = True,
        ))

        self.add(pr.RemoteVariable(
            name         = 'NcoConfig',
            description  = """
                I = (desired output Frequency * Sampling time *2^(Frequency Resolution))
                """,
            offset       = 0x8,
            bitSize      = 32,
            mode         = 'RW',
            hidden       = True,
        ))

        # Sampling time *2^(Frequency Resolution))
        self._ncoConstant = 1E6*self.smplTime*4294967296.0 # Units of MHz

        self.add(pr.LinkVariable( # Software Variable
            name         = 'NcoFreqMHz',
            description  = 'frequency for local VCO',
            mode         = "RW",
            units        = "MHz",
            disp         = '{:1.6f}',
            typeStr      = 'Float',
            value        = 1054.0,
            linkedGet    = lambda: float(self.NcoConfig.value())/(self._ncoConstant),
            linkedSet    = lambda value, write: self.NcoConfig.set( int(value*self._ncoConstant) ),
            dependencies = [self.NcoConfig],
        ))

        self.add(pr.RemoteVariable(
            name         = 'DspRunCntrl',
            description  = 'used to put the Gearbox FIFOs in reset until after configuration is completed',
            offset       = 0x10,
            bitSize      = 1,
            mode         = 'RW',
            hidden       = True,
        ))

        for i in range(4):
            self.add(pr.RemoteVariable(
                name         = f'AmpDelay[{i}]',
                description  = 'Used to delay the AMP waveform after the SSR_DDC and before ring buffer',
                offset       = 0x14,
                bitSize      = 4,
                bitOffset    = 8*i,
                mode         = 'RW',
            ))
