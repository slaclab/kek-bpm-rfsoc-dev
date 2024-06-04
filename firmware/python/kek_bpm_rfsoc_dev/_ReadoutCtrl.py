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
import time

class ReadoutCtrl(pr.Device):
    def __init__(self,
            sampleRate  = 0.0,
            ampDispProc = None,
            SSR         = 16,
            boardType   = None,
        **kwargs):
        super().__init__(**kwargs)

        self.smplTime = 1/sampleRate
        self.ampDispProc = ampDispProc
        self._LiveDispTrigCnt = 0
        self._SSR = SSR

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
            hidden = False,
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
                self._LiveDispTrigCnt = self._LiveDispTrigCnt + 1

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
                name         = f'FineDelay[{i}]',
                description  = 'Used to delay the AMP waveform after the SSR_DDC and before ring buffer',
                offset       = 0x14,
                bitSize      = 4,
                bitOffset    = 8*i,
                mode         = 'RW',
                units        = 'sample',
                # hidden       = True,
            ))

        for i in range(4):
            self.add(pr.RemoteVariable(
                name         = f'CourseDelay[{i}]',
                description  = 'Used to delay the AMP waveform after the SSR_DDC and before ring buffer',
                offset       = 0x18,
                bitSize      = 4,
                bitOffset    = 8*i,
                mode         = 'RW',
                units        = f'{self._SSR} x sample',
                # hidden       = True,
            ))

        if boardType == 'Zcu111':
            intfType = 'Pmod'
            intfDict = {
                0x0: 'Pmod0Bit6',
                0x1: 'Pmod0Bit7',
                0x2: 'Pmod1Bit6',
                0x3: 'Pmod1Bit7',
            }
        else:
            intfType = 'Rfmc'
            intfDict = {
                0x0: 'AdcIo6',
                0x1: 'AdcIo7',
                0x2: 'DacIo6',
                0x3: 'DacIo7',
            }

        self.add(pr.RemoteVariable(
            name         = f'{intfType}InSel',
            description  = f'Selects the input {intfType} port to use as fault signal',
            offset       = 0x20,
            bitSize      = 2,
            bitOffset    = 16,
            enum         = intfDict,
        ))

        self.add(pr.RemoteVariable(
            name         = f'{intfType}InPolarity',
            description  = 'Sets the polarity of the fault signal',
            offset       = 0x20,
            bitSize      = 1,
            bitOffset    = 24,
            enum        = {
                0x0: 'NonInverted',
                0x1: 'Inverted',
            },
        ))

        for i in range(4):
            self.add(pr.RemoteVariable(
                name         = intfDict[i],
                description  = f'Current value of the {intfType} input pin',
                offset       = 0x24,
                bitSize      = 1,
                bitOffset    = i,
                mode         = 'RO',
                pollInterval = 1,
            ))

        self.add(pr.RemoteVariable(
            name         = f'{intfType}In',
            description  = f'{intfType}In = {intfType}InSel xor {intfType}InPolarity',
            offset       = 0x24,
            bitSize      = 1,
            bitOffset    = 4,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'FaultTrigReady',
            description  = 'Status of the fault trigger being armed',
            offset       = 0x24,
            bitSize      = 1,
            bitOffset    = 5,
            mode         = 'RO',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'FaultTrigArm',
            description  = 'Arms the fault trigger',
            offset       = 0x28,
            bitSize      = 1,
            mode         = 'WO',
        ))

        self.add(pr.RemoteVariable(
            name         = 'SelectDirect',
            description  = 'Select DDC or Direct sampling',
            offset       = 0x28,
            bitSize      = 1,
            bitOffset    = 1,
            mode         = 'RW',
            hidden       = True, # With KekBpmRfsocDevZcu111_4072MSPS_BypassDDC, we could consider removing this feature in the future
            enum        = {
                0x0: 'DDC',
                0x1: 'Direct sampling',
            },
        ))

        self.add(pr.RemoteVariable(
            name         = 'SetKeepArm',
            description  = 'Keep FaultTrigReady = 1',
            offset       = 0x28,
            bitSize      = 1,
            bitOffset    = 2,
            mode         = 'WO',
        ))

        self.add(pr.RemoteVariable(

            name         = 'MuxSelect',
            description  = 'Select raw or down sampled ADC for the ring buffer',
            offset       = 0x28,
            bitSize      = 1,
            bitOffset    = 3,
            mode         = 'RW',
            enum        = {
                0x0: 'RAW_ADC',
                0x1: 'DownSampledAdc',
            },
        ))

        self.add(pr.RemoteVariable(
            name         = "FaultTrigDlyRaw",
            description  = "Sets a delay between trigger detection and stopping the ring buffer",
            offset       = 0x2C,
            bitSize      = 15,
            mode         = "RW",
            units        = '1/254.5MHz',
        ))

        self.add(pr.LinkVariable(
            name         = "FaultTrigDly",
            description  = "FaultTrigDly in microseconds",
            mode         = "RW",
            units        = "microsec",
            disp         = '{:0.3f}',
            dependencies = [self.FaultTrigDlyRaw],
            linkedGet    = lambda: (float(self.FaultTrigDlyRaw.value()+1) * (1.0/254.5)),
            linkedSet    = lambda value, write: self.FaultTrigDlyRaw.set(int(value/(1.0/254.5))-1),
        ))

        @self.command(description  = 'Tuning the amplitude delays before the Position calculating',hidden=False)
        def tuneAmpDelays(arg):
            chMask = int(arg)
#            print(chMask)
            print('ReadoutCtrl.tuneAmpDelays()')
            peak  = [0,1,2,3]

            # retry until locked
            while max(peak) - min(peak) > 1:

                # Reset the delays
                [self.FineDelay[i].set(0) for i in range(4)]
                [self.CourseDelay[i].set(0) for i in range(4)]
                time.sleep(1)

                # Trigger 1st event and check the pattern
                cnt = self._LiveDispTrigCnt
                while cnt == self._LiveDispTrigCnt:
                    time.sleep(0.01)

                finedelay = [self.ampDispProc[i].peaksearch() % self._SSR for i in range(4)]
                intdev = [self.ampDispProc[i].peaksearch() // self._SSR for i in range(4)]
                coursedelay = [max(intdev) - intdev[i] for i in range(4)]
                print( f'peak array = {[self.ampDispProc[i].peaksearch() for i in range(4)]}' )
                print( f'setting finedelays = {finedelay}' )
                print( f'setting coursedelays = {coursedelay}' )
                [self.FineDelay[i].set(finedelay[i]) for i in range(4)]
                [self.CourseDelay[i].set(coursedelay[i]) for i in range(4)]
                time.sleep(1)
                # Trigger 2nd event and check the lock pattern (all zeros)
                cnt = self._LiveDispTrigCnt
                while cnt == self._LiveDispTrigCnt:
                    time.sleep(0.01)
                peak = [self.ampDispProc[i].peaksearch() for i in range(4)]
                for i in range(4):
                    if (chMask>>i)&0x1  != 0x1:
                        print( f'Skipping channel = {i}')
                        peak[i] = peak[0] if i!=0 else peak[3]
                print( f'Checking peak alignment = {peak}' )
