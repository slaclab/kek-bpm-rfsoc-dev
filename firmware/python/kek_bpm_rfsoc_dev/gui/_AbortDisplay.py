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
from pydm.widgets import PyDMWaveformPlot, PyDMSpinbox, PyDMPushButton, PyDMLabel

from qtpy.QtCore import Qt
from qtpy.QtWidgets import QVBoxLayout, QHBoxLayout, QFormLayout, QGroupBox, QDoubleSpinBox, QLabel

from pyrogue.pydm.data_plugins.rogue_plugin import nodeFromAddress
from pyrogue.pydm.widgets import PyRogueLineEdit

import pyrogue as pr

class AbortDisplay(PyDMFrame):
    def __init__(self, parent=None, init_channel=None,dispType=''):
        PyDMFrame.__init__(self, parent, init_channel)
        self._node     = None
        self._dispType = dispType
        self.color     = ["white","red", "dodgerblue","forestgreen","yellow","magenta","turquoise","deeppink","white","red", "dodgerblue","forestgreen","yellow","magenta","turquoise","deeppink"]
        self.path      = [f'{self.channel}.{self._dispType}[{i}]' for i in range(2)]

    # Reset the auto-ranging
    def resetScales(self):
        self.posPlot.resetAutoRangeX()
        self.posPlot.resetAutoRangeY()

    def connection_changed(self, connected):
        build = (self._node is None) and (self._connected != connected and connected is True)
        super(AbortDisplay, self).connection_changed(connected)

        if not build:
            return

        self._node = nodeFromAddress(self.channel)

        vb = QVBoxLayout()
        self.setLayout(vb)

        #-----------------------------------------------------------------------------

        gb = QGroupBox('UV Position - white, DV Position - red, UV MA - yellow, DV MA - turquoise, abort Flag - magenta')
        vb.addWidget(gb)

        fl = QFormLayout()
        fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
        fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
        fl.setLabelAlignment(Qt.AlignRight)
        gb.setLayout(fl)

        self.posPlot = PyDMWaveformPlot()
        self.posPlot.setLabel("bottom", text='Time (ns)')
        self.posPlot.addChannel(
            name       = 'Position',
            x_channel  = f'{self.path[1]}.Time',
            y_channel  = f'{self.path[1]}.Position_UV',
            color      = 'white',
            symbol     = 'o',
            symbolSize = 3,
        )
        self.posPlot.addChannel(
            name       = 'Position',
            x_channel  = f'{self.path[1]}.Time',
            y_channel  = f'{self.path[1]}.Position_DV',
            color      = 'red',
            symbol     = 'o',
            symbolSize = 3,
        )
        self.posPlot.addChannel(
            name       = 'Position',
            x_channel  = f'{self.path[0]}.Time',
            y_channel  = f'{self.path[0]}.MovingAverage_UV',
            color      = 'yellow',
            symbol     = 'o',
            symbolSize = 3,
        )
        self.posPlot.addChannel(
            name       = 'Position',
            x_channel  = f'{self.path[0]}.Time',
            y_channel  = f'{self.path[0]}.MovingAverage_DV',
            color      = 'turquoise',
            symbol     = 'o',
            symbolSize = 3,
        )
        self.posPlot.addChannel(
            name       = 'Position',
            x_channel  = f'{self.path[0]}.Time',
            y_channel  = f'{self.path[0]}.AbortFlag',
            color      = 'magenta',
            symbol     = 'o',
            symbolSize = 3,
        )
        fl.addWidget(self.posPlot)

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
