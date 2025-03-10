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

class FaultDisplay(PyDMFrame):
    def __init__(self, parent=None, init_channel=None):
        PyDMFrame.__init__(self, parent, init_channel)
        self._node     = None
        self.path      = f'{self.channel}.AmpFaultProcessor'
        self.RxEnable  = nodeFromAddress(f'{self.path}.RxEnable')

    def resetScales(self):
        # Reset the auto-ranging
        self.xPosPlot.setAutoRangeX(True)
        self.xPosPlot.resetAutoRangeX()
        self.xPosPlot.resetAutoRangeY()

    def connection_changed(self, connected):
        build = (self._node is None) and (self._connected != connected and connected is True)
        super(FaultDisplay, self).connection_changed(connected)

        if not build:
            return

        self._node = nodeFromAddress(self.channel)

        vb = QVBoxLayout()
        self.setLayout(vb)

        #-----------------------------------------------------------------------------

        gb = QGroupBox('X Position (white = + polarity, red = - polarity), Y Position (yellow = + polarity, turquoise = - polarity)')
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
            x_channel  = f'{self.path}.Time',
            y_channel  = f'{self.path}.WaveformData[0]',
            color      = "white",
            symbol     = 'o',
            symbolSize = 3,
        )
        self.xPosPlot.addChannel(
            name       = 'Counts',
            x_channel  = f'{self.path}.Time',
            y_channel  = f'{self.path}.WaveformData[1]',
            color      = "red",
            symbol     = 'o',
            symbolSize = 3,
        )
        self.xPosPlot.addChannel(
            name       = 'Counts',
            x_channel  = f'{self.path}.Time',
            y_channel  = f'{self.path}.WaveformData[2]',
            color      =  "yellow",
            symbol     = 'o',
            symbolSize = 3,
        )
        self.xPosPlot.addChannel(
            name       = 'Counts',
            x_channel  = f'{self.path}.Time',
            y_channel  = f'{self.path}.WaveformData[3]',
            color      = "turquoise",
            symbol     = 'o',
            symbolSize = 3,
        )
        fl.addWidget(self.xPosPlot)

        self.xPosPlot.setAutoRangeX(False)
        self.xPosPlot.setMinXRange(-20.0)
        self.xPosPlot.setMaxXRange(0.0)

        #-----------------------------------------------------------------------------

        gb = QGroupBox( 'AMP Fault Display Controls' )
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
