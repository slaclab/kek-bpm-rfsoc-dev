#-----------------------------------------------------------------------------
# This file is part of the 'kek_bpm_rfsoc_dev'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'kek_bpm_rfsoc_dev', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import rogue.interfaces.stream as ris
import pyrogue as pr
import numpy as np
import math

# Class for streaming RX
class StreamProcessor(pr.DataReceiver):
    # Init method must call the parent class init
    def __init__( self,hidden=True,**kwargs):
        pr.Device.__init__(self, hidden=hidden, **kwargs)
        ris.Slave.__init__(self)
        pr.DataReceiver.__init__(self, enableOnStart=True, hideData=True, hidden=hidden, **kwargs)

        # Remove data variable from stream and server
        self.Data.addToGroup('NoServe')
        self.Data.addToGroup('NoStream')
        self.Data.addToGroup('NoStatus')

        # Configurable variables
        self._prevFrameCnt = 0
        self._maxSize  = 2**10
        smplRate = 254.5E+6

        # Init variables
        timeBin  = (1.0E+9/smplRate) # Units of ns
        freqBin = ((0.5E+3/timeBin)/float(self._maxSize//2)) # Units of MHz

        # Calculate the time/frequency x-axis arrays
        timeSteps = np.linspace(0, timeBin*(self._maxSize-1), num=self._maxSize)
        freqSteps = np.linspace(0, freqBin*((self._maxSize//2)-1), num=(self._maxSize//2))

        FftMagValue = np.zeros(shape=self._maxSize, dtype=np.float32, order='C')
        FftMagValue.fill(-140.0)

        self.add(pr.LocalVariable(
            name        = 'Time',
            description = 'Time steps (ns)',
            typeStr     = 'Float[np]',
            value       = timeSteps,
            hidden      = True,
        ))

        self.add(pr.LocalVariable(
            name        = 'Freq',
            description = 'Freq steps (MHz)',
            typeStr     = 'Float[np]',
            disp        = '',
            value       = freqSteps,
            hidden      = True,
        ))

        for i in range(1):

            self.add(pr.LocalVariable(
                name        = f'AdcI[{i}]',
                typeStr     = 'Int16[np]',
                disp        = '',
                value       = np.zeros(shape=self._maxSize, dtype=np.int16, order='C'),
                hidden      = True,
            ))

            self.add(pr.LocalVariable(
                name        = f'AdcQ[{i}]',
                typeStr     = 'Int16[np]',
                disp        = '',
                value       = np.zeros(shape=self._maxSize, dtype=np.int16, order='C'),
                hidden      = True,
            ))

            self.add(pr.LocalVariable(
                name        = f'DacI[{i}]',
                typeStr     = 'Int16[np]',
                disp        = '',
                value       = np.zeros(shape=self._maxSize, dtype=np.int16, order='C'),
                hidden      = True,
            ))

            self.add(pr.LocalVariable(
                name        = f'DacQ[{i}]',
                typeStr     = 'Int16[np]',
                disp        = '',
                value       = np.zeros(shape=self._maxSize, dtype=np.int16, order='C'),
                hidden      = True,
            ))

            self.add(pr.LocalVariable(
                name        = f'AdcMag[{i}]',
                typeStr     = 'Int16[np]',
                disp        = '',
                value       = np.zeros(shape=self._maxSize, dtype=np.int16, order='C'),
                hidden      = True,
            ))

            self.add(pr.LocalVariable(
                name        = f'DacMag[{i}]',
                typeStr     = 'Int16[np]',
                disp        = '',
                value       = np.zeros(shape=self._maxSize, dtype=np.int16, order='C'),
                hidden      = True,
            ))

    # Method which is called when a frame is received
    def process(self,frame):
        with self.root.updateGroup():
            pr.DataReceiver.process(self,frame)

            # Convert the numpy array to 16-bit values
            data = self.Data.value()[:].view(np.int16)

            # Double check the length
            if len(data) != (4*self._maxSize):
                print(f"Invalid frame size. Got {len(data)}, Exp {4*self._maxSize}")

            # Update the I/Q variables
            for x in range(1):

                with self.AdcI[x].lock, self.AdcQ[x].lock, self.DacI[x].lock, self.DacQ[x].lock:

                    # Lst[ Initial : End : IndexJump ]
                    self.AdcI[x].value()[:] = data[0::4]
                    self.AdcQ[x].value()[:] = data[1::4]
                    self.DacI[x].value()[:] = data[2::4]
                    self.DacQ[x].value()[:] = data[3::4]

                self.writeAndVerifyBlocks(force=True, variable=self.AdcI[x])
                self.writeAndVerifyBlocks(force=True, variable=self.AdcQ[x])
                self.writeAndVerifyBlocks(force=True, variable=self.DacI[x])
                self.writeAndVerifyBlocks(force=True, variable=self.DacQ[x])

                magAdc = np.abs(np.vectorize(complex)(self.AdcI[x].value(), self.AdcQ[x].value()))
                magDac = np.abs(np.vectorize(complex)(self.DacI[x].value(), self.DacQ[x].value()))

                self.AdcMag[x].set(magAdc,write=True)
                self.DacMag[x].set(magDac,write=True)
