#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# This file is part of the 'kek_bpm_rfsoc_dev'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'kek_bpm_rfsoc_dev', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------
import setupLibPaths

import kek_bpm_rfsoc_bor as bor
import kek_bpm_rfsoc_stripline as stripline

import os
import sys
import argparse
import importlib
import rogue
import pyrogue
import axi_soc_ultra_plus_core.rfsoc_utility.pydm

if __name__ == "__main__":

#################################################################

    # Set the argument parser
    parser = argparse.ArgumentParser()

    # Convert str to bool
    argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']

    # Add arguments
    parser.add_argument(
        "--ip",
        type     = str,
        required = True,
        help     = "ETH Host Name (or IP address)",
    )

    parser.add_argument(
        "--appType",
        type     = str,
        required = False,
        default  = 'bor',
        help     = "Sets the application type (bor or stripline)",
    )

    parser.add_argument(
        "--boardType",
        type     = str,
        required = True,
        help     = "Sets board type (zcu111 or zcu208 or rfsoc4x2)",
    )

    parser.add_argument(
        "--chMask",
        type     = lambda x: int(x,0), # "auto_int" function for hex arguments
        required = False,
        default  = 0xF,
        help     = "4-bit bitmask for seleting BPM channels",
    )

    parser.add_argument(
        "--guiType",
        type     = str,
        required = False,
        default  = 'PyDM',
        help     = "Sets the GUI type (PyDM or None)",
    )

    # Get the arguments
    args = parser.parse_args()

    #################################################################

    if (args.appType == 'bor'):
        bpmRoot = bor.Root

    elif (args.appType == 'stripline'):
        bpmRoot = stripline.Root

    else:
        raise ValueError( f'Invalid Application type = {args.appType}' )

    #################################################################

    with bpmRoot(
        ip         = args.ip,
        chMask     = args.chMask,
        boardType  = args.boardType,
    ) as root:

        ######################
        # Development PyDM GUI
        ######################
        if (args.guiType == 'PyDM'):
            top_level = os.path.realpath(__file__).split('software')[0]
            axi_soc_ultra_plus_core.rfsoc_utility.pydm.runPyDM(
                serverList = root.zmqServer.address,
                ui         = f'{top_level}/firmware/python/kek_bpm_rfsoc_{args.appType}/gui/GuiTop.py',
                sizeX      = 800,
                sizeY      = 800,
            )

        #################
        # No GUI
        #################
        elif (args.guiType == 'None'):
            print("Running without GUI...")
            pyrogue.waitCntrlC()

        ####################
        # Undefined GUI type
        ####################
        else:
            raise ValueError( f'Invalid GUI type = {args.guiType}' )

    #################################################################
