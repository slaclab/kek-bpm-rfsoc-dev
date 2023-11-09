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
import axi_soc_ultra_plus_core as soc_core
import axi_soc_ultra_plus_core.hardware.RealDigitalRfSoC4x2 as rfsoc_hw

rogue.Version.minVersion('6.1.1')

class Root(pr.Root):
    def __init__(self,
            ip         = '',   # ETH Host Name (or IP address)
            top_level  = '',
            bpmFreqMHz = 2000, # 2000 MHz, 1000 MHz or 500MHz
            zmqSrvEn   = True, # Flag to include the ZMQ server
            **kwargs):

        # Pass custom value to parent via super function
        super().__init__(**kwargs)

        self.bpmFreqMHz = float(bpmFreqMHz)

        # Check for ZONE1 operation
        if bpmFreqMHz < (3054//2):
            self.NcoFreqMHz = self.bpmFreqMHz
            self.sampleRate = 4.072E+9 # Units of Hz
            lmxAdcFile = 'LmxConfig4072MSPS.txt'
        # Else ZONE2 operation
        else:
            self.NcoFreqMHz = 3054.0 - float(bpmFreqMHz) # ZONE2: Operation 1054MHz = 3.054MSPS - bpmFreqMHz
            self.sampleRate = 3.054E+9 # Units of Hz
            lmxAdcFile = 'LmxConfig3054MSPS.txt'
        print( f'sampleRate={int(self.sampleRate/1E6)}MSPS, DDC.NcoFreqMHz={int(self.NcoFreqMHz)}MHz' )

        #################################################################
        if zmqSrvEn:
            self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='*', port=0)
            self.addInterface(self.zmqServer)
        #################################################################

        # Local Variables
        self.top_level = top_level
        if self.top_level != '':
            self.configPath = f'{top_level}/config'
        else:
            self.configPath = 'config'
        self.defaultFile = f'{self.configPath}/defaults.yml'
        self.lmkConfig   = f'{self.configPath}/LmkConfig.txt'
        self.lmxConfig   = [f'{self.configPath}/LmxConfig6108MSPS.txt',f'{self.configPath}/{lmxAdcFile}',f'{self.configPath}/{lmxAdcFile}']

        # File writer
        self.dataWriter = pr.utilities.fileio.StreamWriter()
        self.add(self.dataWriter)

        ##################################################################################
        ##                              Register Access
        ##################################################################################

        # Check if we can ping the device and TCP socket not open
        soc_core.connectionTest(ip)

        # Start a TCP Bridge Client, Connect remote server at 'ethReg' ports 9000 & 9001.
        self.memMap = rogue.interfaces.memory.TcpClient(ip,9000)

        # Added the RFSoC HW device
        self.add(rfsoc.RFSoC(
            memBase    = self.memMap,
            sampleRate = self.sampleRate,
            offset     = 0x04_0000_0000, # Full 40-bit address space
            expand     = True,
        ))

        ##################################################################################
        ##                              Data Path
        ##################################################################################

        # Create rogue stream objects
        self.adcDispBuff  = [stream.TcpClient(ip,10000+2*(i+4))  for i in range(4)]
        self.ampDispBuff  = [stream.TcpClient(ip,10000+2*(i+0))  for i in range(4)]

        # self.adcFaultBuff = [stream.TcpClient(ip,10000+2*(i+12))  for i in range(4)]
        self.ampFaultBuff = [stream.TcpClient(ip,10000+2*(i+8)) for i in range(4)]

        self.adcDispProc = [rfsoc_utility.RingBufferProcessor(name=f'AdcDispProcessor[{i}]',sampleRate=self.sampleRate,maxSize=16*2**9) for i in range(4)]
        self.ampDispProc = [rfsoc.RingBufferProcessor(name=f'AmpDispProcessor[{i}]',sampleRate=self.sampleRate,maxSize=16*2**9) for i in range(4)]

        # self.adcFaultProc = [rfsoc_utility.RingBufferProcessor(name=f'AdcFaultProcessor[{i}]',sampleRate=self.sampleRate,maxSize=16*2**12) for i in range(4)]
        self.ampFaultProc = [rfsoc.RingBufferProcessor(name=f'AmpFaultProcessor[{i}]',sampleRate=self.sampleRate,maxSize=16*2**12) for i in range(4)]

        # Connect the rogue stream arrays
        for i in range(4):

            # ADC Live Display Path
            self.adcDispBuff[i] >> self.dataWriter.getChannel(i+0)
            self.adcDispBuff[i] >> self.adcDispProc[i]
            self.add(self.adcDispProc[i])

            # AMP Live Display Path
            self.ampDispBuff[i] >> self.dataWriter.getChannel(i+4)
            self.ampDispBuff[i] >> self.ampDispProc[i]
            self.add(self.ampDispProc[i])

            # # ADC Fault Display Path
            # self.adcFaultBuff[i] >> self.dataWriter.getChannel(i+8)
            # self.adcFaultBuff[i] >> self.adcFaultProc[i]
            # self.add(self.adcFaultProc[i])

            # AMP Fault Display Path
            self.ampFaultBuff[i] >> self.dataWriter.getChannel(i+12)
            self.ampFaultBuff[i] >> self.ampFaultProc[i]
            self.add(self.ampFaultProc[i])

        ##################################################################################

        self.add(pr.LinkVariable(
            name         = 'NewDataDisp',
            mode         = 'RO',
            typeStr      = 'bool',
            value        = False,
            linkedGet    = lambda: self.AmpDispProcessor[0].NewDataReady.value() and self.AmpDispProcessor[1].NewDataReady.value() and self.AmpDispProcessor[2].NewDataReady.value() and self.AmpDispProcessor[3].NewDataReady.value(),
            dependencies = [self.AmpDispProcessor[i].NewDataReady for x in range(4)],
            hidden       = True,
        ))

        self.add(pr.LinkVariable(
            name         = 'NewDataFault',
            mode         = 'RO',
            typeStr      = 'bool',
            value        = False,
            linkedGet    = lambda: self.AmpFaultProcessor[0].NewDataReady.value() and self.AmpFaultProcessor[1].NewDataReady.value() and self.AmpFaultProcessor[2].NewDataReady.value() and self.AmpFaultProcessor[3].NewDataReady.value(),
            dependencies = [self.AmpFaultProcessor[i].NewDataReady for x in range(4)],
            hidden       = True,
        ))

        ##################################################################################

        self.add(rfsoc.StreamProcessor(name='BpmDispProc', waveformRx = [self.AmpDispProcessor[i]  for i in range(4)]))
        self.add(rfsoc.StreamProcessor(name='BpmFaultProc',waveformRx = [self.AmpFaultProcessor[i] for i in range(4)]))

        self.add(pr.LinkVariable(
            name         = 'MonNewDataDisp',
            mode         = 'RO',
            linkedGet    = lambda: self.BpmDispProc.gpSubProcess() if self.NewDataDisp.value() else False ,
            dependencies = [self.NewDataDisp],
            hidden       = True,
        ))

        self.add(pr.LinkVariable(
            name         = 'MonNewDataFault',
            mode         = 'RO',
            linkedGet    = lambda: self.BpmFaultProc.gpSubProcess() if self.NewDataFault.value() else False ,
            dependencies = [self.NewDataFault],
            hidden       = True,
        ))

        # Connect StreamProcessor to the file writer
        self.BpmDispProc  >> self.dataWriter.getChannel(16)
        self.BpmFaultProc >> self.dataWriter.getChannel(17)

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

    def start(self,**kwargs):
        super(Root, self).start(**kwargs)

        # Useful pointers
        axiVersion  = self.RFSoC.AxiSocCore.AxiVersion
        dacSigGen   = self.RFSoC.Application.DacSigGen
        rfdc        = self.RFSoC.RfDataConverter
        readoutCtrl = self.RFSoC.Application.ReadoutCtrl

        # Issue a reset to the user logic
        axiVersion.UserRst()
        while(axiVersion.AppReset.get() != 0):
            time.sleep(0.01)

        # Update all SW remote registers
        self.ReadAll()

        # Initialize the LMK/LMX Clock chips
        self.RFSoC.Hardware.InitClock(lmkConfig=self.lmkConfig,lmxConfig=self.lmxConfig)
        time.sleep(0.2)

        # Initialize the RF Data Converter
        rfdc.Init(dynamicNco=True)

        # Set the DAC's NCO frequency
        for i in range(2):
            for j in range(4):
                rfdc.dacTile[i].dacBlock[j].ncoFrequency.set(self.bpmFreqMHz) # In units of MHz

        # MTS Sync the RF Data Converter
        time.sleep(1.0)
        rfdc.MtsAdcSync()
        rfdc.MtsDacSync()

        # Load the Default YAML file
        print(f'Loading path={self.defaultFile} Default Configuration File...')
        self.LoadConfig(self.defaultFile)
        self.ReadAll()

        # Load the waveform data into DacSigGen
        dacSigGen.CsvFilePath.set(f'{self.configPath}/{dacSigGen.CsvFilePath.get()}')
        dacSigGen.LoadCsvFile()

        # Set the firmware DDC's NCO value and enable run control
        readoutCtrl.NcoFreqMHz.set(self.NcoFreqMHz)
        readoutCtrl.DspRunCntrl.set(1)

        # Update all SW remote registers
        self.CountReset()
        self.ReadAll()

    ##################################################################################
