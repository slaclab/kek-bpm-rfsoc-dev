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

        if zmqSrvEn:
            self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='*', port=0)
            self.addInterface(self.zmqServer)

        ##################################################################################

        self.bpmFreqMHz = float(bpmFreqMHz)

        # Check for ZONE1 operation
        if bpmFreqMHz < (3054//2):
            self.SSR = 16
            self.NcoFreqMHz = self.bpmFreqMHz
            self.sampleRate = 4.072E+9 # Units of Hz
            self.ImageName = 'KekBpmRfsocDevZcu111_4072MSPS'

        # Else ZONE2 operation
        else:
            self.SSR = 12
            self.NcoFreqMHz = 3054.0 - float(bpmFreqMHz) # ZONE2: Operation 1054MHz = 3.054MSPS - bpmFreqMHz
            self.sampleRate = 3.054E+9 # Units of Hz
            self.ImageName = 'KekBpmRfsocDevZcu111_3054MSPS'

        print( f'sampleRate={int(self.sampleRate/1E6)}MSPS, DDC.NcoFreqMHz={int(self.NcoFreqMHz)}MHz' )

        # Configuration File Paths
        self.top_level = top_level
        if self.top_level != '':
            self.configPath = f'{top_level}/config'
        else:
            self.configPath = 'config'
        self.defaultFile = f'{self.configPath}/defaults.yml'
        self.lmkConfig   = f'{self.configPath}/LmkConfig.txt'
        self.lmxConfig   = [f'{self.configPath}/LmxConfig.txt']

        # File writer
        self.dataWriter = pr.utilities.fileio.StreamWriter()
        self.add(self.dataWriter)

        ##################################################################################

        # Create rogue stream objects
        self.adcDispBuff  = [stream.TcpClient(ip,10000+2*(i+4))  for i in range(4)]
        self.ampDispBuff  = [stream.TcpClient(ip,10000+2*(i+0))  for i in range(4)]

        self.ampFaultBuff = [stream.TcpClient(ip,10000+2*(i+8)) for i in range(4)]

        self.bpmDispBuff  = stream.TcpClient(ip,10000+2*16)
        self.bpmFaultBuff = stream.TcpClient(ip,10000+2*24)

        ##################################################################################

        # Create rogue stream receivers
        self.adcDispProc = [rfsoc_utility.RingBufferProcessor(name=f'AdcDispProcessor[{i}]',sampleRate=self.sampleRate,maxSize=self.SSR*2**9) for i in range(4)]
        self.ampDispProc = [rfsoc.RingBufferProcessor(name=f'AmpDispProcessor[{i}]',sampleRate=self.sampleRate,maxSize=self.SSR*2**9,SSR=self.SSR,faultDisp=False) for i in range(4)]

        self.ampFaultProc = [rfsoc.RingBufferProcessor(name=f'AmpFaultProcessor[{i}]',sampleRate=self.sampleRate,maxSize=self.SSR*2**13,SSR=self.SSR,faultDisp=True) for i in range(4)]

        self.bpmDispProc  = rfsoc.PosCalcProcessor(name='BpmDispProc',maxSize=2**9)
        self.bpmFaultProc = rfsoc.PosCalcProcessor(name='BpmFaultProc',maxSize=2**13)

        ##################################################################################

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

            # AMP Fault Display Path
            self.ampFaultBuff[i] >> self.dataWriter.getChannel(i+12)
            self.ampFaultBuff[i] >> self.ampFaultProc[i]
            self.add(self.ampFaultProc[i])

        # PosCalc Live Display Path
        self.bpmDispBuff  >> self.dataWriter.getChannel(16)
        self.bpmDispBuff >> self.bpmDispProc
        self.add(self.bpmDispProc)

        # PosCalc Fault Display Path
        self.bpmFaultBuff  >> self.dataWriter.getChannel(24)
        self.bpmFaultBuff >> self.bpmFaultProc
        self.add(self.bpmFaultProc)


        ##################################################################################
        ##                              Register Access
        ##################################################################################

        # Check if we can ping the device and TCP socket not open
        soc_core.connectionTest(ip)

        # Start a TCP Bridge Client, Connect remote server at 'ethReg' ports 9000 & 9001.
        self.memMap = rogue.interfaces.memory.TcpClient(ip,9000)

        # Added the RFSoC HW device
        self.add(rfsoc.RFSoC(
            memBase     = self.memMap,
            sampleRate  = self.sampleRate,
            ampDispProc = [self.AmpDispProcessor[x] for x in range(4)],
            SSR         = self.SSR,
            offset      = 0x04_0000_0000, # Full 40-bit address space
            expand      = True,
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

    def start(self,**kwargs):
        super(Root, self).start(**kwargs)

        # Useful pointers
        axiVersion  = self.RFSoC.AxiSocCore.AxiVersion
        dacSigGen   = self.RFSoC.Application.DacSigGen
        rfdc        = self.RFSoC.RfDataConverter
        readoutCtrl = self.RFSoC.Application.ReadoutCtrl

        # Check for Expected FW loaded
        if axiVersion.ImageName.get() != self.ImageName:
                errMsg = f'Actual.Firmware={axiVersion.ImageName.get()} != Expected.Firmware={self.ImageName}'
                click.secho(errMsg, bg='red')
                raise ValueError(errMsg)

        print('Issuing a reset to the user logic')
        axiVersion.UserRst()
        while(axiVersion.AppReset.get() != 0):
            time.sleep(0.1)

        print('Initialize the LMK/LMX Clock chips')
        self.RFSoC.Hardware.InitClock(lmkConfig=self.lmkConfig,lmxConfig=self.lmxConfig)

        print('Wait for DSP Clock to be stable')
        while(axiVersion.DspReset.get()):
            time.sleep(0.1)

        # Enable application after LMK/LMX has been configured
        self.RFSoC.Application.enable.set(True)
        self.ReadAll()

        # Initialize the RF Data Converter
        time.sleep(2.0)
        rfdc.Init(dynamicNco=True)

        # Set the DAC's NCO frequency
        for i in range(2):
            for j in range(4):
                rfdc.dacTile[i].dacBlock[j].ncoFrequency.set(self.bpmFreqMHz) # In units of MHz

        # Wait for ADC/DAC Tile to be stable
        for i in range(2):
            while rfdc.adcTile[i].CurrentState.get() < 14:
                time.sleep(0.01)
            while rfdc.dacTile[i].CurrentState.get() < 14:
                time.sleep(0.01)

        # Set the firmware DDC's NCO value and enable run control
        readoutCtrl.NcoFreqMHz.set(self.NcoFreqMHz)
        readoutCtrl.DspRunCntrl.set(1)

        # MTS Sync the RF Data Converter
        rfdc.MtsAdcSync()
        rfdc.MtsDacSync()

        # Load the Default YAML file and refresh all remote variables
        print(f'Loading path={self.defaultFile} Default Configuration File...')
        self.LoadConfig(self.defaultFile)
        self.ReadAll()

        # Load the waveform data into DacSigGen
        dacSigGen.CsvFilePath.set(f'{self.configPath}/{dacSigGen.CsvFilePath.get()}')
        dacSigGen.LoadCsvFile()

        # Tune the amplitude delays for the firmware position calculation
        readoutCtrl.tuneAmpDelays()

    ##################################################################################
