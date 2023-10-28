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

class BpmDisplay(PyDMFrame):
    def __init__(self, parent=None, init_channel=None,dispType=''):
        PyDMFrame.__init__(self, parent, init_channel)
        self._node     = None
        self._dispType = dispType
        self.color     = ["white","red", "dodgerblue","forestgreen","yellow","magenta","turquoise","deeppink","white","red", "dodgerblue","forestgreen","yellow","magenta","turquoise","deeppink"]
        self.path      = f'{self.channel}.{self._dispType}'

    # Reset the auto-ranging
    def resetScales(self):
        self.xPosPlot.resetAutoRangeX()
        self.xPosPlot.resetAutoRangeY()
        self.yPosPlot.resetAutoRangeX()
        self.yPosPlot.resetAutoRangeY()

    def connection_changed(self, connected):
        build = (self._node is None) and (self._connected != connected and connected is True)
        super(BpmDisplay, self).connection_changed(connected)

        if not build:
            return

        self._node = nodeFromAddress(self.channel)

        vb = QVBoxLayout()
        self.setLayout(vb)

        #-----------------------------------------------------------------------------

        gb = QGroupBox('X Position')
        vb.addWidget(gb)

        fl = QFormLayout()
        fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
        fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
        fl.setLabelAlignment(Qt.AlignRight)
        gb.setLayout(fl)

        self.xPosPlot = PyDMWaveformPlot()
        self.xPosPlot.setLabel("bottom", text='Bunch Number')
        self.xPosPlot.addChannel(
            name       = 'X Position (TBD Units)',
            x_channel  = f'{self.path}.StepsX',
            y_channel  = f'{self.path}.Xpos',
            color      = 'white',
            symbol     = 'o',
            symbolSize = 3,
        )
        fl.addWidget(self.xPosPlot)

        #-----------------------------------------------------------------------------

        gb = QGroupBox('Y Position')
        vb.addWidget(gb)

        fl = QFormLayout()
        fl.setRowWrapPolicy(QFormLayout.DontWrapRows)
        fl.setFormAlignment(Qt.AlignHCenter | Qt.AlignTop)
        fl.setLabelAlignment(Qt.AlignRight)
        gb.setLayout(fl)

        self.yPosPlot = PyDMWaveformPlot()
        self.yPosPlot.setLabel("bottom", text='Bunch Number')
        self.yPosPlot.addChannel(
            name       = 'Y Position (TBD Units)',
            x_channel  = f'{self.path}.StepsY',
            y_channel  = f'{self.path}.Ypos',
            color      = 'white',
            symbol     = 'o',
            symbolSize = 3,
        )
        fl.addWidget(self.yPosPlot)

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

        #-----------------------------------------------------------------------------
