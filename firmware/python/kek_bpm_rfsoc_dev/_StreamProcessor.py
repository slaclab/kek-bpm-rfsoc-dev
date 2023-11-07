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
import rogue.interfaces.stream as ris

import numpy as np
import math
import struct

# Class for streaming RX
class StreamProcessor(pr.Device,ris.Master):
    # Init method must call the parent class init
    def __init__(self,waveformRx,**kwargs):
        pr.Device.__init__(self, **kwargs)
        ris.Master.__init__(self)

        # Pointer to the waveform receiver devices
        self.waveformRx = waveformRx

        # Local Variables
        self._xx = np.nan
        self._yy = np.nan
        self._lenXX = 0
        self._lenYY = 0

        #-----------------------------------------------------------------------------
        # Configurable variables
        #-----------------------------------------------------------------------------

        # 1 f90x220A [SKB Ante 90x220] LER normal
        # 2 f50x190(+25)SP [SKB Oval 50x44x190]
        # 3 f64      [SKB circ 64]
        # 4 122x50   [SKB race 122x50]
        # 5 65x48    [SKB race 65x48]
        # 6 60x40    [SKB race 60x4]0
        # 7 f50x190  [SKB Oval 50x44x190]
        # 8 f90      [SKB BPM90]
        # 9 SKB oval 50x44
        # 10 104x50  [KEKB 104x50]
        # 11 f80x220_Ar [Ante 80x220]
        # 12 f80     [SKB BPM80]
        # 13 SKB dumping ring
        # 14 f94     [KEKB f94 (LER)]
        # 15 f150    [KEKB f150]
        # 16 f90x220A_H24 (longer antechamger)
        # 17 f20 qc1
        # 18 f70 qc2

        self.add(pr.LocalVariable(
            name        = 'chamberType',
            description = 'BPM chamber type',
            typeStr     = 'UInt8',
            disp        = '',
            value       = 0,
            minimum     = 0,
            maximum     = 17,
            enum        = {
                0  : 'f90x220A',
                1  : 'f50x190(+25)SP',
                2  : 'f64',
                3  : '122x50',
                4  : '65x48',
                5  : '60x40',
                6  : 'f50x190',
                7  : 'f90',
                8  : 'SKB_oval_50x44',
                9  : '104x50',
                10 : 'f80x220_Ar',
                11 : 'f80',
                12 : 'SKB_dumping_ring',
                13 : 'f94',
                14 : 'f150',
                15 : 'f90x220A_H24',
                16 : 'f20',
                17 : 'f70',
            },
        ))

        self.add(pr.LocalVariable(
            name        = 'noise_threshold',
            description = 'threshold in peak search',
            typeStr     = 'UInt16',
            value       = 500,
        ))

        coeffX = np.zeros(shape=[18,10], dtype=np.float32, order='C')
        coeffY = np.zeros(shape=[18,10], dtype=np.float32, order='C')

        coeffX[0]=[-1.92E-07,9.17E-01,-3.51E-16, 9.73E-10, -6.18E-12,-2.74E-11,1.30E-04,-7.72E-19,-3.81E-04,2.18E-18]
        coeffY[0]=[9.41E-08,3.49E-16,9.45E-01,1.52E-09,1.22E-12,-1.53E-09,-3.34E-18,-3.56E-04,2.41E-18,1.32E-04]

        coeffX[1]=[4.89E-06,5.04E-01,1.25E-14,-2.00E-08,-9.36E-12,3.51E-09,7.24E-05,-1.38E-17,-2.07E-04,-2.95E-17]
        coeffY[1]=[3.30E-07,1.20E-14,5.08E-01,9.54E-10,-5.51E-11,-1.87E-09,-1.63E-17,-1.80E-04,-3.14E-17,5.98E-05]

        coeffX[2]=[-1.77E-08,6.54E-01,-4.05E-16,1.64E-10,-2.43E-13,-8.21E-11,9.28E-05,-1.17E-18,-2.59E-04,2.91E-18]
        coeffY[2]=[1.77E-08,2.93E-16,6.54E-01,8.21E-11,2.43E-13,-1.64E-10,-1.92E-18,-2.59E-04,1.20E-19,9.28E-05]

        coeffX[3]=[-8.35E-16,5.37E-01,-3.04E-16,-1.01E-17,-1.09E-17,2.83E-17,8.22E-05,-5.50E-19,-3.82E-04,2.14E-18]
        coeffY[3]=[1.52E-14,4.04E-17,8.65E-01,4.26E-18,-7.24E-18,-8.61E-17,2.79E-21,-1.94E-04,-1.64E-19,1.25E-04]

        coeffX[4]=[-1.43E-09,8.28E-01,-9.81E-17,1.80E-11,-1.14E-13,-2.30E-12,5.26E-04,2.46E-19,-5.28E-04,2.53E-19]
        coeffY[4]=[1.90E-09,4.80E-16,4.70E-01,1.25E-11,3.73E-14,-9.04E-12,-3.78E-18,1.44E-04,-2.50E-19,-3.55E-05]

        coeffX[5]=[-2.30E-09,5.94E-01,-1.83E-16,1.93E-11,7.52E-14,-7.44E-12,2.40E-04,6.45E-20,-3.90E-04,4.86E-19]
        coeffY[5]=[-2.09E-09,2.55E-17,4.45E-01,-5.37E-12,1.13E-13,8.21E-12,-4.27E-19,3.76E-05,2.62E-19,-2.96E-05]

        coeffX[6]=[4.58E-06,5.04E-01,1.18E-14,-1.88E-08,-6.19E-12,3.29E-09,7.24E-05,-1.33E-17,-2.07E-04,-2.74E-17]
        coeffY[6]=[1.21E-07,1.13E-14,5.08E-01,7.52E-10,-5.16E-11,-9.59E-10,-1.69E-17,-1.80E-04,-2.72E-17,5.98E-05]

        coeffX[7]=[-2.15E-16,9.17E-01,-5.61E-17,5.91E-17,2.75E-17,-3.36E-17,1.28E-04,3.68E-18,-3.72E-04,-1.77E-18]
        coeffY[7]=[7.94E-15,-1.56E-16,9.17E-01,-4.91E-17,1.45E-17,-8.11E-17,3.82E-18,-3.71E-04,-3.13E-18,1.28E-04]

        coeffX[8]=[3.00E-08,5.10E-01,-1.38E-16,-1.81E-10,6.04E-13,8.20E-11,8.42E-05,-3.63E-19,-1.80E-04,6.04E-19]
        coeffY[8]=[-2.77E-08,1.23E-16,4.51E-01,-7.09E-11,-6.32E-13,1.20E-10,-5.96E-19,-1.85E-04,1.49E-19,5.92E-05]

        coeffX[9]=[5.21E-15,5.59E-01,4.03E-16,-2.64E-17,1.13E-17,-3.49E-17,8.02E-05,-5.50E-19,-4.27E-04,-3.06E-18]
        coeffY[9]=[5.37E-15,2.06E-16,8.11E-01,-1.55E-17,-1.15E-17,-4.22E-17,-7.58E-19,-1.62E-04,-1.50E-19,9.38E-05]

        coeffX[10]=[9.11E-04,8.21E-01,6.77E-08,-1.24E-05,3.97E-08,5.89E-06,8.83E-05,-2.21E-11,-3.48E-04,-6.07E-10]
        coeffY[10]=[-3.76E-04,6.97E-08,8.52E-01,-1.25E-06,1.77E-08,4.89E-06,-5.11E-10,-3.25E-04,-1.62E-10,1.07E-04]

        coeffX[11]=[-7.18E-15,9.18E-01,-1.14E-15,-1.47E-17,1.34E-17,1.21E-16,1.27E-04,3.77E-18,-3.73E-04,1.16E-17]
        coeffY[11]=[5.10E-15,-5.28E-16,9.18E-01,2.04E-18,2.56E-17,-1.10E-16,2.84E-18,-3.72E-04,5.50E-18,1.27E-04]

        coeffX[12]=[-1.08E-06,3.34E-01,-2.84E-15,2.54E-09,-1.25E-10,-1.31E-09,9.59E-05,8.90E-19,-1.91E-04,2.53E-18]
        coeffY[12]=[2.23E-06,9.58E-15,3.13E-01,2.31E-09,5.96E-11,-4.30E-09,-3.91E-17,3.25E-06,3.46E-17,-3.18E-05]

        coeffX[13]=[2.37E-14,9.63E-01,4.00E-16,-6.01E-17,8.17E-18,-9.16E-17,1.37E-04,5.39E-19,-3.76E-04,-2.26E-18]
        coeffY[13]=[8.28E-15,-6.28E-16,9.63E-01,-1.31E-17,2.53E-17,-6.36E-17,4.31E-18,-3.76E-04,-1.51E-18,1.37E-04]

        coeffX[14]=[6.324E-05,1.529E+00,3.731E-09,-4.462E-07,-2.381E-14,-1.751E-07,2.150E-04,-7.140E-12,-6.185E-04,-2.362E-11]
        coeffY[14]=[-3.624E-05,3.732E-09,1.529E+00,1.969E-07,-1.295E-10,1.969E-07,-2.360E-11,-6.182E-04,-7.196E-12,2.156E-04]

        coeffX[15]=[1.984E-04,9.162E-01,-1.207E-11,-2.564E-06,-5.775E-10,1.098E-07,1.219E-04,2.340E-13,-4.081E-04,7.407E-15]
        coeffY[15]=[1.850E-04,-1.392E-11,9.705E-01,2.072E-08,-7.145E-10,-2.635E-06,-8.891E-15,-3.600E-04,3.387E-13,1.322E-04]

        coeffX[16]=[-3.37E-07,2.06E-01,2.31E-15,3.25E-09,-4.07E-12,-1.64E-09,2.95E-05,3.32E-17,-8.15E-05,-3.19E-17]
        coeffY[16]=[3.37E-07,2.32E-15,2.06E-01,1.64E-09,4.07E-12,-3.25E-09,-3.22E-17,-8.15E-05,3.37E-17,2.95E-05]

        coeffX[17]=[-3.25E-03,7.09E-01,-4.28E-09,6.65E-05,4.65E-09,-1.53E-06,1.53E-04,1.36E-10,-2.90E-04,3.89E-12]
        coeffY[17]=[-3.17E-03,-5.19E-09,7.09E-01,-4.30E-07,3.10E-09,6.42E-05,-5.74E-13,-2.87E-04,1.76E-10,1.51E-04]


        for i in range(18):

            self.add(pr.LocalVariable(
                name        = f'coeffX[{i}]',
                description = 'coefficient_x',
                typeStr     = 'Float[np]',
                value       = coeffX[i],
                mode        = 'RO',
                hidden      = True,
            ))

            self.add(pr.LocalVariable(
                name        = f'coeffY[{i}]',
                description = 'coefficient_y',
                typeStr     = 'Float[np]',
                value       = coeffY[i],
                mode        = 'RO',
                hidden      = True,
            ))

        #-----------------------------------------------------------------------------
        # Outputs
        #-----------------------------------------------------------------------------

        self.add(pr.LocalVariable(
            name        = 'Xpos',
            description = 'X position',
            typeStr     = 'Float[np]',
            disp        = '',
            value       = np.zeros(shape=1, dtype=np.float32, order='C'),
            hidden      = True,
        ))

        self.add(pr.LocalVariable(
            name        = 'Ypos',
            description = 'Y position',
            typeStr     = 'Float[np]',
            disp        = '',
            value       = np.zeros(shape=1, dtype=np.float32, order='C'),
            hidden      = True,
        ))

        self.add(pr.LocalVariable(
            name        = 'StepsX',
            description = 'X position steps for GUI display',
            typeStr     = 'Float[np]',
            disp        = '',
            value       = np.linspace(0, 0, num=1),
            hidden      = True,
        ))

        self.add(pr.LocalVariable(
            name        = 'StepsY',
            description = 'X position steps for GUI display',
            typeStr     = 'Float[np]',
            # disp        = '',
            value       = np.linspace(0, 0, num=1),
            hidden      = True,
        ))

        self.add(pr.LocalVariable(
            name        = 'XposSTD',
            typeStr     = 'Float[np]',
            # disp        = '{:1.1f}',
            units       = 'TBD',
            value       = np.nan,
        ))

        self.add(pr.LocalVariable(
            name        = 'YposSTD',
            typeStr     = 'Float[np]',
            # disp        = '{:1.1f}',
            units       = 'TBD',
            value       = np.nan,
        ))

        self.add(pr.LocalVariable(
            name        = 'XposRMS',
            typeStr     = 'Float[np]',
            # disp        = '{:1.1f}',
            units       = 'TBD',
            value       = np.nan,
        ))

        self.add(pr.LocalVariable(
            name        = 'YposRMS',
            typeStr     = 'Float[np]',
            # disp        = '{:1.1f}',
            units       = 'TBD',
            value       = np.nan,
        ))

        self.add(pr.LocalVariable(
            name        = 'EventCnt',
            description = 'Increments per gpSubProcess() execution',
            typeStr     = 'UInt32',
            value       = 0,
        ))

    # Method which is called to run BPM sub process
    def gpSubProcess(self):

        # Lock the waveform variables while processing them
        with self.waveformRx[0].WaveformData.lock, self.waveformRx[1].WaveformData.lock, self.waveformRx[2].WaveformData.lock, self.waveformRx[3].WaveformData.lock:

            # Find the peaks per waveforms
            index=np.argmin(self.waveformRx[0]._waveformData[:12])
            a_peak = self.peak_search(waveform=self.waveformRx[0]._waveformData,start_index=index)
            b_peak = self.peak_search(waveform=self.waveformRx[1]._waveformData,start_index=index)
            c_peak = self.peak_search(waveform=self.waveformRx[2]._waveformData,start_index=index)
            d_peak = self.peak_search(waveform=self.waveformRx[3]._waveformData,start_index=index)

            # Update the waveform PVs
            [self.waveformRx[i].UpdateWaveform() for i in range(4)]

            # Clear the flag from each receiver
            [self.waveformRx[i].NewDataReady.set(False) for i in range(4)]

        # Run chamber calculation
        self.poscalc(sel=self.chamberType.value() , a=a_peak , b=b_peak , c=c_peak , d=d_peak)

        # Generate the streaming frame with results
        self.ResultsFrameGen()

        # Increment the counter
        self.EventCnt.set(self.EventCnt.value()+1)

    # Method for generating a frame with the results
    def ResultsFrameGen(self):

        # event counter (UInt32)
        # length(UInt32) + Float32[array]
        # length(UInt32) + Float32[array]
        size  = 4 \
              + 4 + 4*self._lenXX \
              + 4 + 4*self._lenYY

        # Here we request a frame capable of holding size bytes
        frame = self._reqFrame(size, True)
        offset = 0

        # Write the Event counter into the frame
        ba = bytearray(struct.pack("<I", self.EventCnt.value() ))
        frame.write(ba,offset)
        offset += 4

        # Write the Xpos Length into the frame
        ba = bytearray(struct.pack("<I", self._lenXX ))
        frame.write(ba,offset)
        offset += 4

        # Write the Xpos into the frame
        for i in range(self._lenXX):
            ba = bytearray(struct.pack("<f", self._xx[i] ))
            frame.write(ba,offset)
            offset += 4

        # Write the Ypos Length into the frame
        ba = bytearray(struct.pack("<I", self._lenYY ))
        frame.write(ba,offset)
        offset += 4

        # Write the Ypos into the frame
        for i in range(self._lenYY):
            ba = bytearray(struct.pack("<f", self._yy[i] ))
            frame.write(ba,offset)
            offset += 4

        # Send the frame results
        self._sendFrame(frame)

    # Method which is called to run chamber calculation
    def poscalc(self,sel,a,b,c,d):
        h = np.divide((a-b-c+d), (a+b+c+d), out=np.zeros_like(a,dtype=np.float64), where=~((a==0)|(b==0)|(c==0)|(d==0)))
        v = np.divide((a+b-c-d), (a+b+c+d), out=np.zeros_like(a,dtype=np.float64), where=~((a==0)|(b==0)|(c==0)|(d==0)))

        # Select the X/Y coefficients
        coeffX = self.coeffX[sel].value()
        coeffY = self.coeffY[sel].value()

        # Perform the chamber calculation
        self._xx = coeffX[0] + \
            coeffX[1] * h    + coeffX[2] * v + \
            coeffX[3] * h**2 + coeffX[4] * h * v + coeffX[5] * v**2 + \
            coeffX[6] * h**3 + coeffX[7] * h**2 * v + coeffX[8] * h * v**2 + coeffX[9] * v**3
        self._yy = coeffY[0] + \
            coeffY[1] * h    + coeffY[2] * v + \
            coeffY[3] * h**2 + coeffY[4] * h * v + coeffY[5] * v**2 + \
            coeffY[6] * h**3 + coeffY[7] * h**2 * v + coeffY[8] * h * v**2 + coeffY[9] * v**3
        self._lenXX = len(self._xx)
        self._lenYY = len(self._yy)

        # Write the results to local variables
        self.Xpos.set(self._xx)
        self.Ypos.set(self._yy)
        self.StepsX.set(np.linspace(0, self._lenXX-1, num=self._lenXX))
        self.StepsY.set(np.linspace(0, self._lenYY-1, num=self._lenYY))

        # Calculate RMS and STD
        if self._lenXX>0:
            self.XposSTD.set(np.std(self._xx))
            self.XposRMS.set(np.sqrt(np.mean(self._xx**2)))
        else:
            self.XposSTD.set(np.nan)
            self.XposRMS.set(np.nan)
        if self._lenYY>0:
            self.YposSTD.set(np.std(self._yy))
            self.YposRMS.set(np.sqrt(np.mean(self._yy**2)))
        else:
            self.YposSTD.set(np.nan)
            self.YposRMS.set(np.nan)

    # Method which is called to run peak search
    def peak_search(self,waveform,start_index):
        mountain_maxima = []
        points_per_bunch = 12
        for i in range(start_index, len(waveform)-points_per_bunch+start_index, points_per_bunch):
            peak = max(waveform[i:i+points_per_bunch])
            if peak >= self.noise_threshold.value():
                mountain_maxima.append(peak)
            else:
                mountain_maxima.append(0)
        return np.array(mountain_maxima)

    # Overload the `>>` python operator for a connection for this custom master stream module
    def __rshift__(self,other):
        pr.streamConnect(self,other)
        return other

    # Overload the `<<` python operator for a connection for this custom master stream module
    def __lshift__(self,other):
        pr.streamConnect(other,self)
        return other
