#-----------------------------------------------------------------------------
# This file is part of the 'axi-soc-ultra-plus-core'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'axi-soc-ultra-plus-core', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import rogue.interfaces.stream as ris
import pyrogue as pr
import numpy as np
import math

import rogue
rogue.Version.minVersion('5.18.4')

# Class for streaming RX
class AbortIssueProcessor(pr.DataReceiver):
    # Init method must call the parent class init
    def __init__( self,
            maxSize     = 2**9,
            hidden      = True,
        **kwargs):
        pr.Device.__init__(self, hidden=hidden, **kwargs)
        ris.Slave.__init__(self)
        pr.DataReceiver.__init__(self, enableOnStart=True, hideData=True, hidden=hidden, **kwargs)

        # Configurable variables
        self._maxSize  = maxSize
        self._timeBin  = (1.0E+9/254.5E+6) # Units of ns

        self.add(pr.LocalVariable(
            name        = 'Time',
            description = 'Time steps (ns)',
            typeStr     = 'Float[np]',
            value       = np.linspace(0, self._timeBin*(self._maxSize-1), num=self._maxSize),
            hidden      = True,
        ))

        self.add(pr.LocalVariable(
            name        = 'Position_UV',
            description = 'Data Frame Container',
            typeStr     = 'Float[np]',
            value       = np.zeros(shape=self._maxSize, dtype=np.float16, order='C'),
            hidden      = True,
        ))

        self.add(pr.LocalVariable(
            name        = 'Position_DV',
            description = 'Data Frame Container',
            typeStr     = 'Float[np]',
            value       = np.zeros(shape=self._maxSize, dtype=np.float16, order='C'),
            hidden      = True,
        ))

        self.add(pr.LocalVariable(
            name        = 'MovingAverage_UV',
            description = 'Data Frame Container',
            typeStr     = 'Float[np]',
            value       = np.zeros(shape=self._maxSize, dtype=np.float16, order='C'),
            hidden      = True,
        ))

        self.add(pr.LocalVariable(
             name        = 'MovingAverage_DV',
             description = 'Data Frame Container',
             typeStr     = 'Float[np]',
             value       = np.zeros(shape=self._maxSize, dtype=np.float16, order='C'),
             hidden      = True,
         ))

        self.add(pr.LocalVariable(
             name        = 'StandardDeviation_UV',
             description = 'Data Frame Container',
             typeStr     = 'Float[np]',
             value       = np.zeros(shape=self._maxSize, dtype=np.float16, order='C'),
             hidden      = True,
         ))

        self.add(pr.LocalVariable(
             name        = 'StandardDeviation_DV',
             description = 'Data Frame Container',
             typeStr     = 'Float[np]',
             value       = np.zeros(shape=self._maxSize, dtype=np.float16, order='C'),
             hidden      = True,
         ))

        self.add(pr.LocalVariable(
             name        = 'AbortFlag',
             description = 'Data Frame Container',
             typeStr     = 'Float[np]',
             value       = np.zeros(shape=self._maxSize, dtype=np.float16, order='C'),
             hidden      = True,
         ))

        #self.add(pr.LocalVariable(
        #     name        = 'Dummy',
        #     description = 'Data Frame Container',
        #     typeStr     = 'Float[np]',
        #     value       = np.zeros(shape=self._maxSize, dtype=np.float16, order='C'),
        #     hidden      = True,
        # ))

        self.add(pr.LocalVariable(
            name  = 'NewDataReady',
            value = False,
        ))

    # Method which is called when a frame is received
    def process(self,frame):
        with self.root.updateGroup():
            pr.DataReceiver.process(self,frame)

            # Get data from frame
            data = self.Data.value()[:].view(np.float16)

            if self.name in ['AbortDispProc[0]','AbortFaultProc[0]']:
                with self.Position_UV.lock:

                    # NumPy Array Slicing - [start:end:step]
                    self.Position_UV.value()[:] = data[0:self._maxSize]

                    self.writeAndVerifyBlocks(force=True, variable=self.Position_UV)

            elif self.name in ['AbortDispProc[1]','AbortFaultProc[1]']:
                with self.Position_DV.lock:

                    # NumPy Array Slicing - [start:end:step]
                    self.Position_DV.value()[:] = data[0:self._maxSize]

                    self.writeAndVerifyBlocks(force=True, variable=self.Position_DV)

            elif self.name in ['AbortDispProc[2]','AbortFaultProc[2]']:
                with self.MovingAverage_UV.lock:

                    # NumPy Array Slicing - [start:end:step]
                    self.MovingAverage_UV.value()[:] = data[0:self._maxSize]

                    self.writeAndVerifyBlocks(force=True, variable=self.MovingAverage_UV)

            elif self.name in ['AbortDispProc[3]','AbortFaultProc[3]']:
                with self.MovingAverage_DV.lock:

                    # NumPy Array Slicing - [start:end:step]
                    self.MovingAverage_DV.value()[:] = data[0:self._maxSize]

                    self.writeAndVerifyBlocks(force=True, variable=self.MovingAverage_DV)

            elif self.name in ['AbortDispProc[4]','AbortFaultProc[4]']:
                with self.StandardDeviation_UV.lock:

                    # NumPy Array Slicing - [start:end:step]
                    self.StandardDeviation_UV.value()[:] = data[0:self._maxSize]

                    self.writeAndVerifyBlocks(force=True, variable=self.StandardDeviation_UV)

            elif self.name in ['AbortDispProc[5]','AbortFaultProc[5]']:
                with self.StandardDeviation_DV.lock:

                    # NumPy Array Slicing - [start:end:step]
                    self.StandardDeviation_DV.value()[:] = data[0:self._maxSize]

                    self.writeAndVerifyBlocks(force=True, variable=self.StandardDeviation_DV)

            elif self.name in ['AbortDispProc[6]','AbortFaultProc[6]']:
                with self.AbortFlag.lock:

                    # NumPy Array Slicing - [start:end:step]
                    self.AbortFlag.value()[:] = data[0:self._maxSize]

                    self.writeAndVerifyBlocks(force=True, variable=self.AbortFlag)


            self.NewDataReady.set(True)
