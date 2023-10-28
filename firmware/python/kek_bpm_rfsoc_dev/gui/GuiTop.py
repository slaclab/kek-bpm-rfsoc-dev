#-----------------------------------------------------------------------------
# This file is part of the 'kek_bpm_rfsoc_dev'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'kek_bpm_rfsoc_dev', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import os
from pydm import Display
from qtpy.QtWidgets import (QVBoxLayout, QTabWidget)

from pyrogue.pydm.widgets import DebugTree
from pyrogue.pydm.widgets import SystemWindow

Channel = 'rogue://0/root'

import axi_soc_ultra_plus_core.rfsoc_utility.gui as guiBase
import kek_bpm_rfsoc_dev.gui                     as guiUser

class GuiTop(Display):
    def __init__(self, parent=None, args=[], macros=None):
        super(GuiTop, self).__init__(parent=parent, args=args, macros=None)

        self.setStyleSheet("*[dirty='true']\
                           {background-color: orange;}")

        self.sizeX  = None
        self.sizeY  = None
        self.title  = None

        for a in args:
            if 'sizeX=' in a:
                self.sizeX = int(a.split('=')[1])
            if 'sizeY=' in a:
                self.sizeY = int(a.split('=')[1])
            if 'title=' in a:
                self.title = a.split('=')[1]

        if self.title is None:
            self.title = "Rogue Server: {}".format(os.getenv('ROGUE_SERVERS'))

        if self.sizeX is None:
            self.sizeX = 800
        if self.sizeY is None:
            self.sizeY = 1000

        self.setWindowTitle(self.title)

        vb = QVBoxLayout()
        self.setLayout(vb)

        self.tab = QTabWidget()
        vb.addWidget(self.tab)

        # System Window (Tab Index=0)
        sys = SystemWindow(parent=None, init_channel=Channel)
        self.tab.addTab(sys,'System')

        # Debug Tree (Tab Index=1)
        var = DebugTree(parent=None, init_channel=Channel)
        self.tab.addTab(var,'Debug Tree')

        # ADC Live Display (Tab Index=2)
        adcDisplay = guiUser.FaultDisplay(parent=None, init_channel=Channel, dispType='AdcDisp', numCh=4)
        self.tab.addTab(adcDisplay,'ADC Live')

        # AMP Live Display (Tab Index=3)
        dacDisplay = guiUser.FaultDisplay(parent=None, init_channel=Channel, dispType='AmpDisp', numCh=4)
        self.tab.addTab(dacDisplay,'AMP Live')

        # ADC Fault Display (Tab Index=4)
        adcDisplay = guiUser.FaultDisplay(parent=None, init_channel=Channel, dispType='AdcFault', numCh=4)
        self.tab.addTab(adcDisplay,'ADC Fault')

        # AMP Fault Display (Tab Index=5)
        dacDisplay = guiUser.FaultDisplay(parent=None, init_channel=Channel, dispType='AmpFault', numCh=4)
        self.tab.addTab(dacDisplay,'AMP Fault')

        # Set the default Tab view
        self.tab.setCurrentIndex(1)

        # Resize the window
        self.resize(self.sizeX, self.sizeY)

    def ui_filepath(self):
        # No UI file is being used
        return None
