#-----------------------------------------------------------------------------
# This file is part of the 'axi-soc-ultra-plus-core'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'axi-soc-ultra-plus-core', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr
import numpy as np
import axi_soc_ultra_plus_core.rfsoc_utility as rfsoc_utility

# Class for streaming RX
class RingBufferProcessor(rfsoc_utility.RingBufferProcessor):
    # Init method must call the parent class init
    def __init__( self,**kwargs):
        super().__init__(**kwargs)
        self._waveformData = np.zeros(shape=self._maxSize, dtype=np.int16, order='C')

    def _start(self):
        super()._start()
        self.RxEnable.set(value=True)

    # Method which is called when a frame is received
    def process(self,frame):
        with self.root.updateGroup():
            pr.DataReceiver.process(self,frame)

            # Get data from frame
            if not(self.NewDataReady.value()):
                self._waveformData = self.Data.value()[:].view(np.int16)

            # Set the flag
            self.NewDataReady.set(True)

    # Method which updates the waveform PV from external function
    def UpdateWaveform(self):
        self.WaveformData.set(self._waveformData,write=True)
        self.NewDataReady.set(False)
