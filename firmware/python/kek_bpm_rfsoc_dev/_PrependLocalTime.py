#-----------------------------------------------------------------------------
# This file is part of the 'fabulous-28nm-dev'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'fabulous-28nm-dev', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import rogue.interfaces.stream as ris
import pyrogue as pr
import time
import struct

class PrependLocalTime(ris.Master, ris.Slave):
    def __init__(self,**kwargs):
        ris.Slave.__init__(self)
        ris.Master.__init__(self)

    # Method which is called when a frame is received
    def _acceptFrame(self,frame):

        # First it is good practice to hold a lock on the frame data.
        with frame.lock():

            # Next we can get the size of the inbound frame payload
            ibSize = frame.getPayload()

            # To access the data we need to create a byte array to hold the data
            ibData = bytearray(ibSize)

            # Next we read the frame data into the byte array, from offset 0
            frame.read(ibData,0)

            # Set outbound frame payload to be 8 bytes more than inbound
            obSize = ibSize + 8

            # Here we request a new frame capable of holding `obSize` bytes
            obFrame = self._reqFrame(obSize, True)

            # Create a new byte array to hold the outbound data
            obData = bytearray(obSize)

            # Add the header ("localtime") to the outbound frame at offset 0 bytes
            hdr = bytearray(struct.pack("<d", time.time() ))
            obFrame.write(hdr,0)

            # Write the inbound frame to the outbound frame at offset 8 bytes
            obFrame.write(ibData,8)

            # Send the frame
            self._sendFrame(obFrame)

    def __rshift__(self,other):
        pr.streamConnect(self,other)
        return other

    def __lshift__(self,other):
        pr.streamConnect(other,self)
        return other
