#-----------------------------------------------------------------------------
# This file is part of the 'kek_bpm_rfsoc_dev'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'kek_bpm_rfsoc_dev', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

from pydm.widgets.frame import PyDMFrame
from pydm.widgets import PyDMWaveformPlot, PyDMSpinbox, PyDMPushButton, PyDMLabel

from qtpy.QtCore import Qt
from qtpy.QtWidgets import QVBoxLayout, QHBoxLayout, QFormLayout, QGroupBox, QDoubleSpinBox, QLabel

from pyrogue.pydm.data_plugins.rogue_plugin import nodeFromAddress
from pyrogue.pydm.widgets import PyRogueLineEdit

import pyrogue as pr

class LiveDisplay(PyDMFrame):
    def __init__(self, parent=None, init_channel=None):
        PyDMFrame.__init__(self, parent, init_channel)
        self._node    = None
        self.path     = f'{init_channel}.Waveform'
        self.color    = ["white","red","lime","teal","white","red"]

    def resetScales(self):
        for i in range(len(self.timePlot)):
            self.timePlot[i].resetAutoRangeX()
            self.timePlot[i].resetAutoRangeY()

    def connection_changed(self, connected):
        build = (self._node is None) and (self._connected != connected and connected is True)
        super(LiveDisplay, self).connection_changed(connected)

        if not build:
            return

        self._node = nodeFromAddress(self.channel)

        vb = QVBoxLayout()
        self.setLayout(vb)

        #-----------------------------------------------------------------------------

        self.timePlot = [PyDMWaveformPlot() for i in range(2)]
        for i in range(1):

            gb = QGroupBox( f'ADC[{i}] I/Q Waveform: {self.color[0]}=I, {self.color[1]}=Q, {self.color[2]}=Magnitude' )
            vb.addWidget(gb)

            fl = QFormLayout()
            fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
            fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
            fl.setLabelAlignment(Qt.AlignRight)
            gb.setLayout(fl)

            self.timePlot[i].addChannel(x_channel=f'{self.path}.Time', y_channel=f'{self.path}.AdcI[{i}]',   name='Counts', color=self.color[0])
            self.timePlot[i].addChannel(x_channel=f'{self.path}.Time', y_channel=f'{self.path}.AdcQ[{i}]',   name='Counts', color=self.color[1])
            self.timePlot[i].addChannel(x_channel=f'{self.path}.Time', y_channel=f'{self.path}.AdcMag[{i}]', name='Counts', color=self.color[2])
            self.timePlot[i].setLabel("bottom", text='Time (ns)')
            fl.addWidget(self.timePlot[i])

            gb = QGroupBox( f'DAC[{i}] I/Q Waveform: {self.color[0]}=I, {self.color[1]}=Q, {self.color[2]}=Magnitude' )
            vb.addWidget(gb)

            fl = QFormLayout()
            fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
            fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
            fl.setLabelAlignment(Qt.AlignRight)
            gb.setLayout(fl)

            self.timePlot[i+1].addChannel(x_channel=f'{self.path}.Time', y_channel=f'{self.path}.DacI[{i}]',   name='Counts', color=self.color[0])
            self.timePlot[i+1].addChannel(x_channel=f'{self.path}.Time', y_channel=f'{self.path}.DacQ[{i}]',   name='Counts', color=self.color[1])
            self.timePlot[i+1].addChannel(x_channel=f'{self.path}.Time', y_channel=f'{self.path}.DacMag[{i}]', name='Counts', color=self.color[2])
            self.timePlot[i+1].setLabel("bottom", text='Time (ns)')
            fl.addWidget(self.timePlot[i+1])

        #-----------------------------------------------------------------------------

        gb = QGroupBox('Display Controls')
        vb.addWidget(gb)

        fl = QHBoxLayout()
        gb.setLayout(fl)

        rstButton = PyDMPushButton(label="Full Scale")
        rstButton.clicked.connect(self.resetScales)
        fl.addWidget(rstButton)

        #-----------------------------------------------------------------------------
        self.resetScales()
