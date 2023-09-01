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

rogue.Version.minVersion('6.0.0')

class Root(pr.Root):
    def __init__(self,
            ip          = '10.0.0.10', # ETH Host Name (or IP address)
            top_level   = '',
            defaultFile = 'config/defaults.yml',
            lmkConfig   = 'config/lmk/HexRegisterValues.txt',
            lmxConfig   = 'config/lmx/HexRegisterValues.txt',
            zmqSrvEn    = True,  # Flag to include the ZMQ server
            rateDropEn  = True,  # Flag to include the rate dropper for live display
            **kwargs):

        # Pass custom value to parent via super function
        super().__init__(**kwargs)

        #################################################################
        if zmqSrvEn:
            self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='*', port=0)
            self.addInterface(self.zmqServer)
        #################################################################

        # Local Variables
        self.top_level   = top_level
        if self.top_level != '':
            self.defaultFile = f'{top_level}/{defaultFile}'
            self.lmkConfig   = f'{top_level}/{lmkConfig}'
            self.lmxConfig   = f'{top_level}/{lmxConfig}'
        else:
            self.defaultFile = defaultFile
            self.lmkConfig   = lmkConfig
            self.lmxConfig   = lmxConfig

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

        # Add RfSoC4x2 PS hardware control
        self.add(rfsoc_hw.Hardware(
            memBase    = self.memMap,
        ))

        # Added the RFSoC HW device
        self.add(rfsoc.RFSoC(
            memBase    = self.memMap,
            offset     = 0x04_0000_0000, # Full 40-bit address space
            expand     = True,
        ))

        ##################################################################################
        ##                              Data Path
        ##################################################################################

        # Create rogue stream objects
        if ip != None:
            self.ringBuffer = stream.TcpClient(ip,10000)
        else:
            self.ringBuffer = rogue.hardware.axi.AxiStreamDma('/dev/axi_stream_dma_0', 0, True)
        self.waveform = rfsoc.StreamProcessor(name='Waveform')
        self.add(self.waveform)

        # Connect the rogue stream to guiDisplay
        self.ringBuffer >> self.dataWriter.getChannel(0)
        if rateDropEn:
            self.rateDrop = stream.RateDrop(True,1.0)
            self.ringBuffer >> self.rateDrop >> self.waveform
        else:
            self.ringBuffer >> self.waveform

        ##################################################################################

        self.epics = pyrogue.protocols.epicsV4.EpicsPvServer(
            base      = 'rfsoc_ioc',
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
        dacSigGen = self.RFSoC.Application.DacSigGen

        # Issue a reset to the user logic
        self.RFSoC.AxiSocCore.AxiVersion.UserRst()

        # Update all SW remote registers
        self.ReadAll()

        # Load the Default YAML file
        print(f'Loading path={self.defaultFile} Default Configuration File...')
        self.LoadConfig(self.defaultFile)
        self.ReadAll()

        # Initialize the LMK/LMX Clock chips
        self.Hardware.InitClock(lmkConfig=self.lmkConfig,lmxConfig=[self.lmxConfig])

        # Wait for DSP Clock to be stable after initializing LMK/LMX Clock chips
        while(self.RFSoC.AxiSocCore.AxiVersion.DspReset.get()):
            time.sleep(0.01)

        # Initialize the RF Data Converter
        self.RFSoC.RfDataConverter.Init(dynamicNco=True)

        # Wait for DSP Clock to be stable after changing NCO value
        while(self.RFSoC.AxiSocCore.AxiVersion.DspReset.get()):
            time.sleep(0.01)

        # Load the waveform data into DacSigGen
        self.RFSoC.Application.DacSigGenLoader.LoadRectFunction()

        # Update all SW remote registers
        self.CountReset()
        self.ReadAll()

    ##################################################################################
