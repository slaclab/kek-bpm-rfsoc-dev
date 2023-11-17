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

class BpmDisplay(PyDMFrame):
    def __init__(self, parent=None, init_channel=None,dispType=''):
        PyDMFrame.__init__(self, parent, init_channel)
        self._node     = None
        self._dispType = dispType
        self.color     = ["white","red", "dodgerblue","forestgreen","yellow","magenta","turquoise","deeppink","white","red", "dodgerblue","forestgreen","yellow","magenta","turquoise","deeppink"]
        self.path      = f'{self.channel}.{self._dispType}'

    # Reset the auto-ranging
    def resetScales(self):
        self.posPlot.resetAutoRangeX()
        self.posPlot.resetAutoRangeY()
        self.chargePlot.resetAutoRangeX()
        self.chargePlot.resetAutoRangeY()

    def connection_changed(self, connected):
        build = (self._node is None) and (self._connected != connected and connected is True)
        super(BpmDisplay, self).connection_changed(connected)

        if not build:
            return

        self._node = nodeFromAddress(self.channel)

        vb = QVBoxLayout()
        self.setLayout(vb)

        #-----------------------------------------------------------------------------

        gb = QGroupBox('X Position - white, Y Position - red')
        vb.addWidget(gb)

        fl = QFormLayout()
        fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
        fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
        fl.setLabelAlignment(Qt.AlignRight)
        gb.setLayout(fl)

        self.posPlot = PyDMWaveformPlot()
        self.posPlot.setLabel("bottom", text='Time (ns)')
        self.posPlot.addChannel(
            name       = 'Position (mm)',
            x_channel  = f'{self.path}.Time',
            y_channel  = f'{self.path}.Xposition',
            color      = 'white',
            symbol     = 'o',
            symbolSize = 3,
        )
        self.posPlot.addChannel(
            name       = 'Position (mm)',
            x_channel  = f'{self.path}.Time',
            y_channel  = f'{self.path}.Yposition',
            color      = 'red',
            symbol     = 'o',
            symbolSize = 3,
        )
        fl.addWidget(self.posPlot)

        #-----------------------------------------------------------------------------

        gb = QGroupBox('Bunch Charge')
        vb.addWidget(gb)

        fl = QFormLayout()
        fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
        fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
        fl.setLabelAlignment(Qt.AlignRight)
        gb.setLayout(fl)

        self.chargePlot = PyDMWaveformPlot()
        self.chargePlot.setLabel("bottom", text='Time (ns)')
        self.chargePlot.addChannel(
            name       = 'Bunch Charge (TBD Units)',
            x_channel  = f'{self.path}.Time',
            y_channel  = f'{self.path}.BunchCharge',
            color      = 'turquoise',
            symbol     = 'o',
            symbolSize = 3,
        )
        fl.addWidget(self.chargePlot)

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
