#-----------------------------------------------------------------------------
# This file is part of the 'axi-soc-ultra-plus-core'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'axi-soc-ultra-plus-core', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

from pydm.widgets.frame import PyDMFrame
from pydm.widgets import PyDMWaveformPlot, PyDMSpinbox, PyDMPushButton

from qtpy.QtCore import Qt
from qtpy.QtWidgets import QVBoxLayout, QHBoxLayout, QFormLayout, QGroupBox, QDoubleSpinBox

from pyrogue.pydm.data_plugins.rogue_plugin import nodeFromAddress
from pyrogue.pydm.widgets import PyRogueLineEdit

import pyrogue as pr

class LiveDisplay(PyDMFrame):
    def __init__(self, parent=None, init_channel=None, dispType='Adc'):
        PyDMFrame.__init__(self, parent, init_channel)
        self._node     = None
        self._dispType = dispType
        self.color     = ["white","red", "dodgerblue","forestgreen","yellow","magenta","turquoise","deeppink","white","red", "dodgerblue","forestgreen","yellow","magenta","turquoise","deeppink"]
        self.path      = [f'{self.channel}.{self._dispType}Processor[{i}]' for i in range(4)]
        self.RxEnable  = [nodeFromAddress(self.path[i]+'.RxEnable') for i in range(4)]

    def resetScales(self):
        # Reset the auto-ranging
        self.xPosPlot.setAutoRangeX(True)
        self.xPosPlot.resetAutoRangeX()
        self.xPosPlot.resetAutoRangeY()
        # self.yPosPlot.resetAutoRangeX()
        # self.yPosPlot.resetAutoRangeY()

    def connection_changed(self, connected):
        build = (self._node is None) and (self._connected != connected and connected is True)
        super(LiveDisplay, self).connection_changed(connected)

        if not build:
            return

        self._node = nodeFromAddress(self.channel)

        # Enable processing on new channel
        for i in range(4):
            self.RxEnable[i].set(True)

        vb = QVBoxLayout()
        self.setLayout(vb)

        #-----------------------------------------------------------------------------

        gb = QGroupBox('X Position (white = + polarity, red = - polarity), X Position (yellow = + polarity, turquoise = - polarity)')
        vb.addWidget(gb)

        fl = QFormLayout()
        fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
        fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
        fl.setLabelAlignment(Qt.AlignRight)
        gb.setLayout(fl)

        self.xPosPlot = PyDMWaveformPlot()
        self.xPosPlot.setLabel("bottom", text='Time (ns)')
        self.xPosPlot.addChannel(
            name       = 'Counts',
            x_channel  = f'{self.path[0]}.Time',
            y_channel  = f'{self.path[0]}.WaveformData',
            color      = "white",
            symbol     = 'o',
            symbolSize = 3,
        )
        self.xPosPlot.addChannel(
            name       = 'Counts',
            x_channel  = f'{self.path[1]}.Time',
            y_channel  = f'{self.path[1]}.WaveformData',
            color      = "red",
            symbol     = 'o',
            symbolSize = 3,
        )
        self.xPosPlot.addChannel(
            name       = 'Counts',
            x_channel  = f'{self.path[2]}.Time',
            y_channel  = f'{self.path[2]}.WaveformData',
            color      =  "yellow",
            symbol     = 'o',
            symbolSize = 3,
        )
        self.xPosPlot.addChannel(
            name       = 'Counts',
            x_channel  = f'{self.path[3]}.Time',
            y_channel  = f'{self.path[3]}.WaveformData',
            color      = "turquoise",
            symbol     = 'o',
            symbolSize = 3,
        )
        fl.addWidget(self.xPosPlot)

        self.xPosPlot.setAutoRangeX(True)
        self.xPosPlot.setMinXRange(0.0)
        self.xPosPlot.setMaxXRange(20.0)

        #-----------------------------------------------------------------------------

        # gb = QGroupBox('Y Position (white = + polarity, red = - polarity)')
        # vb.addWidget(gb)

        # fl = QFormLayout()
        # fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
        # fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
        # fl.setLabelAlignment(Qt.AlignRight)
        # gb.setLayout(fl)

        # self.yPosPlot = PyDMWaveformPlot()
        # self.yPosPlot.setLabel("bottom", text='Time (ns)')
        # self.yPosPlot.addChannel(
            # name       = 'Counts',
            # x_channel  = f'{self.path[2]}.Time',
            # y_channel  = f'{self.path[2]}.WaveformData',
            # color      =  "white",
            # symbol     = 'o',
            # symbolSize = 3,
        # )
        # self.yPosPlot.addChannel(
            # name       = 'Counts',
            # x_channel  = f'{self.path[3]}.Time',
            # y_channel  = f'{self.path[3]}.WaveformData',
            # color      = "red",
            # symbol     = 'o',
            # symbolSize = 3,
        # )
        # fl.addWidget(self.yPosPlot)

        #-----------------------------------------------------------------------------

        gb = QGroupBox( f'{self._dispType} Display Controls')
        vb.addWidget(gb)

        fl = QFormLayout()
        fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
        fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
        fl.setLabelAlignment(Qt.AlignRight)
        gb.setLayout(fl)

        rstButton = PyDMPushButton(label="Full Scale")
        rstButton.clicked.connect(self.resetScales)
        fl.addWidget(rstButton)
        self.resetScales()

        #-----------------------------------------------------------------------------
