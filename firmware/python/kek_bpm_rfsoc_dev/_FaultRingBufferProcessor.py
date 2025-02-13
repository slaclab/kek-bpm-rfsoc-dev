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

# Class for streaming RX
class FaultRingBufferProcessor(pr.DataReceiver):
    # Init method must call the parent class init
    def __init__( self,
            hidden      = True,
            **kwargs):
        pr.Device.__init__(self, hidden=hidden, **kwargs)
        ris.Slave.__init__(self)
        pr.DataReceiver.__init__(self, enableOnStart=True, hideData=True, hidden=hidden, **kwargs)

        # Not saving config/state to YAML
        guiGroups = ['NoStream','NoState','NoConfig']

        # Remove data variable from stream and server
        self.Data.addToGroup('NoServe')
        self.Data.addToGroup('NoStream')
        self.Data.addToGroup('NoStatus')

        # Configurable variables
        self._maxDispSize  = 2**9 # Note: This is only the max display size (not total in buffer)
        self._timeBin  = (1.0E+9/509.0E+6) # Units of ns

        # Calculate the time x-axis arrays
        timeSteps = -1.0*np.linspace(self._timeBin*(self._maxDispSize-1), 0, num=self._maxDispSize)

        self.add(pr.LocalVariable(
            name        = 'Time',
            description = 'Time steps (ns)',
            typeStr     = 'Float[np]',
            value       = timeSteps,
            hidden      = True,
            groups      = guiGroups,
        ))

        for i in range(4):
            self.add(pr.LocalVariable(
                name        = f'WaveformData[{i}]',
                description = 'Data Frame Container',
                typeStr     = 'Int16[np]',
                value       = np.zeros(shape=self._maxDispSize, dtype=np.int16, order='C'),
                hidden      = True,
                groups      = guiGroups,
            ))

        self.add(pr.LocalVariable(
            name   = 'NewDataReady',
            value  = False,
            groups = guiGroups,
        ))

        self._waveformData = [None for _ in range(4)]

    # Method which updates the waveform PV from external function
    def UpdateWaveform(self):
        # Reset the flag
        self.NewDataReady.set(False)

    # Method which is called when a frame is received
    def process(self,frame):
        with self.root.updateGroup():
            # Convert the frame data into a numpy 16-bit integer array
            dat = frame.getNumpy(0, frame.getPayload()).view(np.int16)

            # Reshape the array into (4, N) format
            self._waveformData = dat.reshape(-1, 4).T  # Transpose to get (4, N) shape

            for i in range(4):
                # Keep only the last self._maxDispSize columns for each channel
                self.WaveformData[i].set(self._waveformData[i, -self._maxDispSize:], write=True)

            # Set the flag
            self.NewDataReady.set(True)
