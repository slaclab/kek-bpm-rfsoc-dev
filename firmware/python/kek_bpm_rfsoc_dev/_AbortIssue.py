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

class AbortIssue(pr.Device):
    def __init__(self,**kwargs):
        super().__init__(**kwargs)

        #define ABORTISSUE_CODEVERSION 0x0/**< codeversion */
        self.add(pr.RemoteVariable(
            name         = 'Version',
            description  = 'Version Number',
            offset       = 0x000,
            bitSize      = 32,
            mode         = 'RO',
        ))

        #define ABORTISSUE_SCRATCHPAD 0xffc/**< scratchpad */
        self.add(pr.RemoteVariable(
            name         = 'ScratchPad',
            description  = 'Register to test reads and writes',
            offset       = 0xFFC,
            bitSize      = 32,
            mode         = 'RW',
            hidden       = True,
        ))

        #define ABORTISSUE_CHARGE_THRESHOLD 0x500/**< charge_threshold */
        self.add(pr.RemoteVariable(
            name         = 'ChargeThreshold',
            description  = 'Buckets whose charge exceeds this ADC count are considered bunches',
            offset       = 0x500,
            bitSize      = 32,
            bitOffset    = 0,
            base         = pr.Float,
            mode         = 'RW',
        ))

        #define ABORTISSUE_ABORT_THRESHOLD 0x504/**< abort_threshold */
        self.add(pr.RemoteVariable(
            name         = 'AbortThreshold',
            description  = 'Triggers when the moving average exceeds x times the moving standard deviation',
            offset       = 0x504,
            bitSize      = 32,
            bitOffset    = 0,
            base         = pr.Float,
            mode         = 'RW',
        ))

        #define ABORTISSUE_ABORT_ON 0x508/**< abort_on */
        self.add(pr.RemoteVariable(
            name         = 'AbortON',
            description  = 'When this is 1, the abort notification system is turned on',
            offset       = 0x508,
            bitSize      = 1,
            mode         = 'RW',
            enum        = {
                0x0: 'Abort OFF',
                0x1: 'Abort ON',
            },
        ))
