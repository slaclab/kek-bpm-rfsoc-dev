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
    def __init__(self,**kwargs):
        super().__init__(**kwargs)

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
            value  = True,
            hidden = True,
        ))

        @self.command(description  = 'Force a DAC signal generator trigger from software',hidden=True)
        def getWaveformBurst():
            if self.EnableSoftTrig.get():
                self.LiveDispTrig()

        self.add(pr.LocalVariable(
            name         = 'GetWaveformBurst',
            mode         = 'RO',
            localGet     = self.getWaveformBurst,
            pollInterval = 1,
            hidden       = True,
        ))

        # self.add(pr.RemoteVariable(
            # name         = 'NcoConfig',
            # description  = """
                # I = (desired output Frequency * Sampling time *2^(Frequency Resolution))
                # """,
            # offset       = 0x8,
            # bitSize      = 32,
            # mode         = 'RW',
            # # hidden       = True,
        # ))

        # # Sampling time *2^(Frequency Resolution))
        # self._ncoConstant = 1/float(2**32) # units of MHz/count

        # self.add(pr.LinkVariable( # Software Variable
            # name         = 'NcoFreqMHz',
            # description  = 'frequency for local VCO',
            # mode         = "RW",
            # units        = "MHz",
            # disp         = '{:1.3f}',
            # typeStr      = 'Float',
            # value        = 2000.0,
            # linkedGet    = lambda: float(self.NcoConfig.value())*self._ncoConstant,
            # linkedSet    = lambda value, write: self.NcoConfig.set( int(value/self._ncoConstant) ),
            # dependencies = [self.NcoConfig],
        # ))