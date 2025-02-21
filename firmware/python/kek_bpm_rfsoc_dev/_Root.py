#-----------------------------------------------------------------------------
# This file is part of the 'kek_bpm_rfsoc_dev'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'kek_bpm_rfsoc_dev', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import time
import click

import rogue
import rogue.interfaces.stream as stream
import rogue.utilities.fileio
import rogue.hardware.axi
import rogue.interfaces.memory

import pyrogue as pr
import pyrogue.protocols
import pyrogue.utilities.fileio
import pyrogue.utilities.prbs
import pyrogue.protocols.epicsV4

import kek_bpm_rfsoc_dev                     as rfsoc
import axi_soc_ultra_plus_core.rfsoc_utility as rfsoc_utility
import axi_soc_ultra_plus_core.hardware.RealDigitalRfSoC4x2 as rfsoc_hw
import axi_soc_ultra_plus_core as soc_core

rogue.Version.minVersion('6.4.4')

class Root(pr.Root):
    def __init__(self,
            ip         = '',   # ETH Host Name (or IP address)
            top_level  = '',
            bpmFreqMHz = 0   , # 0MHz (DDC bypass), 2000 MHz, 1000 MHz or 500MHz
            zmqSrvEn   = True, # Flag to include the ZMQ server
            chMask     = 0xF,
            boardType  = None, # Either zcu111 or zcu208 or rfsoc4x2
            **kwargs):

        # Pass custom value to parent via super function
        super().__init__(**kwargs)
        self._timeout = 5000000 # 5.0 seconds default

        if zmqSrvEn:
            self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='127.0.0.1', port=0)
            self.addInterface(self.zmqServer)

        ##################################################################################

        # Intialize the local variables
        self.bpmFreqMHz = float(bpmFreqMHz)
        self.chMask = chMask
        self.boardType = boardType[0].upper() + boardType[1:].lower()
        self.MuxSelect = 0

        # Check for DDC bypass mode
        if (bpmFreqMHz == 0):
            self.SSR = 16
            self.NcoFreqMHz = self.bpmFreqMHz
            self.sampleRate = 4.072E+9 # Units of Hz
            self.ImageName  = f'KekBpmRfsocDev{self.boardType}_4072MSPS_BypassDDC'
            self.faultDepth = 2**15
        else:
            raise ValueError( 'non-zero bpmFreqMHz is no longer support' )

        print( f'sampleRate={int(self.sampleRate/1E6)}MSPS, DDC.NcoFreqMHz={int(self.NcoFreqMHz)}MHz' )

        # Configuration File Paths
        self.top_level = top_level
        if self.top_level != '':
            self.configPath = f'{top_level}/config'
        else:
            self.configPath = 'config'
        self.defaultFile = f'{self.configPath}/defaults.yml'
        self.lmkConfig   = f'{self.configPath}/{self.boardType}/LmkConfig.txt'
        self.lmxConfig   = [f'{self.configPath}/{self.boardType}/LmxConfig.txt']

        # File writer
        self.dataWriter = pr.utilities.fileio.StreamWriter()
        self.add(self.dataWriter)

        ##################################################################################

        # Create rogue stream objects
        self.adcDispBuff  = [stream.TcpClient(ip,10000+2*(i+4))  for i in range(4)]
        self.ampDispBuff  = [stream.TcpClient(ip,10000+2*(i+0))  for i in range(4)]
        self.ampFaultBuff =  stream.TcpClient(ip,10000+2*(8))

        # Used to prepend the local time into a stream
        self.ampFaultWithHdr = rfsoc.PrependLocalTime()

        ##################################################################################

        # Create rogue stream receivers
        self.adcDispProc  = [None for _ in range(4)]
        self.ampDispProc  = [None for _ in range(4)]
        self.adcDispFifo  = [None for _ in range(4)]
        self.ampDispFifo  = [None for _ in range(4)]
        for i in range(4):

            self.adcDispProc[i] = rfsoc_utility.RingBufferProcessor(
                name       = f'AdcDispProcessor[{i}]',
                sampleRate = self.sampleRate,
                maxSize    = self.SSR*2**9,
            )

            self.ampDispProc[i] = rfsoc.RingBufferProcessor(
                name       = f'AmpDispProcessor[{i}]',
                sampleRate = self.sampleRate,
                maxSize    = self.SSR*2**9,
                SSR        = self.SSR,
                faultDisp  = False,
            )

            self.adcDispFifo[i] = pr.interfaces.stream.Fifo(
                name        = f'AdcDispFifo[{i}]',
                description = 'Fifo to prevent back pressuring stream',
                maxDepth    = 1, # Drop if more than 1 frame in FIFO
                trimSize    = 0, # No triming
                noCopy      = False, # Create copy of buffer
                )

            self.ampDispFifo[i] = pr.interfaces.stream.Fifo(
                name        = f'AmpDispFifo[{i}]',
                description = 'Fifo to prevent back pressuring stream',
                maxDepth    = 1, # Drop if more than 1 frame in FIFO
                trimSize    = 0, # No triming
                noCopy      = False, # Create copy of buffer
                )

        self.ampFaultProc = rfsoc.FaultRingBufferProcessor(
            name   = 'AmpFaultProcessor',
            hidden = True,
        )

        ##################################################################################

        # Connect the rogue stream arrays
        for i in range(4):

            # ADC Live Display Path
            self.adcDispBuff[i] >> self.adcDispFifo[i] >> self.adcDispProc[i]
            self.add(self.adcDispProc[i])

            # AMP Live Display Path
            self.ampDispBuff[i] >> self.ampDispFifo[i] >> self.ampDispProc[i]
            self.add(self.ampDispProc[i])

        # AMP Fault Display Path
        self.ampFaultBuff >> self.ampFaultWithHdr >> self.dataWriter.getChannel(i+12)
        self.ampFaultBuff >> self.ampFaultProc
        self.add(self.ampFaultProc)

        ##################################################################################
        ##                              Register Access
        ##################################################################################

        # Check if we can ping the device and TCP socket not open
        soc_core.connectionTest(ip)

        # Start a TCP Bridge Client, Connect remote server at 'ethReg' ports 9000 & 9001.
        self.memMap = rogue.interfaces.memory.TcpClient(ip,9000)

        # Add RfSoC4x2 PS hardware control
        if (self.boardType == 'Rfsoc4x2'):
            self.expectedHardware = 'RealDigitalRfSoC4x2'
            self.add(rfsoc_hw.Hardware(
                memBase    = self.memMap,
            ))
        else:
            self.expectedHardware = f'Xilinx{self.boardType}'

        # Added the RFSoC HW device
        self.add(rfsoc.RFSoC(
            memBase     = self.memMap,
            sampleRate  = self.sampleRate,
            ampDispProc = [self.AmpDispProcessor[x] for x in range(4)],
            SSR         = self.SSR,
            offset      = 0x04_0000_0000, # Full 40-bit address space
            expand      = True,
            boardType   = self.boardType,
        ))

        ##################################################################################
        ##                              EPICS Access
        ##################################################################################

        self.epics = pyrogue.protocols.epicsV4.EpicsPvServer(
            base      = 'kek_bpm_rfsoc_demo_ioc',
            root      = self,
            pvMap     = None,
            incGroups = None,
            excGroups = None,
        )
        self.addProtocol(self.epics)

        ##################################################################################
        ##                 Auto-close/open datafile for fault event support
        ##################################################################################
        self.add(pr.LocalVariable(
            name   = 'EnableAutoReopen',
            mode   = 'RW',
            value  = False, # FALSE by default to prevent breaking any of the juypter notebooks that collect multiple waveforms in the fault event path
            hidden = False,
        ))

        self.add(pr.LocalVariable(
            name        = 'EnableFaultTrigTimer',
            description = 'Used to enable the periodic fault triggering from software',
            mode        = 'RW',
            value       = False, # FALSE by default
        ))

        self.add(pr.LocalVariable(
            name        = 'FaultTrigTimerSize',
            description = 'Number of seconds between software fault triggers',
            mode        = 'RW',
            value       = 60,
            units       = 'seconds',
        ))

        self.add(pr.LocalVariable(
            name        = 'FaultTrigTimerValue',
            description = 'periodic fault trigger timer value',
            mode        = 'RO',
            value       = 0,
            units       = 'seconds',
        ))

        @self.command(hidden=True)
        def getFaultEventStatus():
            # Check if periodic fault triggering from software is enabled
            if self.EnableFaultTrigTimer.get() and (self.FaultTrigTimerSize.get() > 0):
                # Increment the timer
                self.FaultTrigTimerValue.set(self.FaultTrigTimerValue.get()+1)
                # Check for timeout
                if (self.FaultTrigTimerValue.get() >= self.FaultTrigTimerSize.get()):
                    # Reset the timer
                    self.FaultTrigTimerValue.set(0)
                    # Issue the software fault trigger
                    self.RFSoC.Application.ReadoutCtrl.SwFaultTrig()
            else:
                # Reset the timer
                self.FaultTrigTimerValue.set(0)

            # Check if there is new data in the fault event path
            newData = self.ampFaultProc.Updated.get()

            # Check if this mode is enable
            if (self.EnableAutoReopen.get()) and newData:

                # Check if a file is already open
                if self.dataWriter._isOpen():

                    # Close file
                    print( f'Closing {self.dataWriter.DataFile.get()}' )
                    self.dataWriter._close()

                    # Confirm file is not open
                    while self.dataWriter._isOpen():
                        time.sleep(0.01)

                # Rename the file
                self.dataWriter.AutoName()
                print( f'Opening {self.dataWriter.DataFile.get()}' )
                self.dataWriter._open()

                # Reset the flags
                self.ampFaultProc.Updated.set(0)

            # Check if MuxSelect changed
            if (self.MuxSelect != self.RFSoC.Application.ReadoutCtrl.MuxSelect.value()):
                self.MuxSelect = self.RFSoC.Application.ReadoutCtrl.MuxSelect.value()
                for i in range(4):
                    if (self.MuxSelect == 0):
                        self.ampDispProc[i].Time.set(self.ampDispProc[i]._timeStepsFine)
                    else:
                        self.ampDispProc[i].Time.set(self.ampDispProc[i]._timeStepsCourse)

        self.add(pr.LocalVariable(
            name         = 'GetFaultEventStatus',
            mode         = 'RO',
            localGet     = self.getFaultEventStatus,
            pollInterval = 1, # periodically check the fault status once a second
            hidden       = True,
        ))

    ##################################################################################

    def start(self,**kwargs):
        super(Root, self).start(**kwargs)

        # Useful pointers
        axiVersion  = self.RFSoC.AxiSocCore.AxiVersion
        dacSigGen   = self.RFSoC.Application.DacSigGen
        rfdc        = self.RFSoC.RfDataConverter
        readoutCtrl = self.RFSoC.Application.ReadoutCtrl

        # Check for Expected HW Platform
        if (self.expectedHardware in axiVersion.HW_TYPE_C.getDisp()) != True:
                errMsg = f'Actual.Hardware={axiVersion.HW_TYPE_C.getDisp()} != Expected.Hardware={self.expectedHardware}'
                click.secho(errMsg, bg='red')
                self.stop()
                raise ValueError(errMsg)

        # Check for Expected FW loaded
        if self.ImageName != axiVersion.ImageName.get():
                errMsg = f'Actual.Firmware={axiVersion.ImageName.get()} != Expected.Firmware={self.ImageName}'
                click.secho(errMsg, bg='red')
                self.stop()
                raise ValueError(errMsg)

        print('Issuing a reset to the user logic')
        axiVersion.UserRst()
        while(axiVersion.AppReset.get() != 0):
            time.sleep(0.1)

        if self.boardType == 'Zcu111':
            print('Initialize the LMK/LMX Clock chips')
            self.RFSoC.Hardware.InitClock(lmkConfig=self.lmkConfig,lmxConfig=self.lmxConfig)

        if self.boardType == 'Rfsoc4x2':
            print('Initialize the LMK/LMX Clock chips')
            self.Hardware.InitClock(lmkConfig=self.lmkConfig,lmxConfig=self.lmxConfig)

        print('Wait for DSP Clock to be stable')
        while(axiVersion.DspReset.get()):
            time.sleep(0.1)

        # Enable application after LMK/LMX has been configured
        self.RFSoC.Application.enable.set(True)
        self.ReadAll()

        # Initialize the RF Data Converter
        time.sleep(2.0)
        print('Initialize RFDC')
        rfdc.Init()

        # Wait for ADC/DAC Tile to be stable
        for i in range(4):
            if self.RFSoC.enAdcTile[i]:
                while rfdc.adcTile[i].CurrentState.get() < 14:
                    time.sleep(0.01)
            if self.RFSoC.enDacTile[i]:
                while rfdc.dacTile[i].CurrentState.get() < 14:
                    time.sleep(0.01)

        # Enable run control
        readoutCtrl.DspRunCntrl.set(1)

        # MTS Sync the RF Data Converter
        # Note: MTS sync is not working and currently broken
        # https://jira.slac.stanford.edu/browse/ESROGUE-675
        # rfdc.MtsAdcSync()
        # rfdc.MtsDacSync()

        # Load the Default YAML file and refresh all remote variables
        print(f'Loading path={self.defaultFile} Default Configuration File...')
        self.LoadConfig(self.defaultFile)
        self.ReadAll()

        # Load the waveform data into DacSigGen
        dacSigGen.CsvFilePath.set(f'{self.configPath}/{dacSigGen.CsvFilePath.get()}')
        dacSigGen.LoadCsvFile()

        # Check if bypassing DDC (direct sampling)
        if self.NcoFreqMHz==0:
            readoutCtrl.SelectDirect.setDisp('Direct sampling')
        else:
            readoutCtrl.SelectDirect.setDisp('DDC')

        # Tune the amplitude delays for the firmware position calculation
        readoutCtrl.tuneAmpDelays(self.chMask)

        # Enable the fault ring buffer
        self.RFSoC.Application.AxiRingBuffer.EnableMode.set(1)

    ##################################################################################
