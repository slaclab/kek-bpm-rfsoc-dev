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

        #define ABORTISSUE_CHARGE_THRESHOLD_UV 0x500/**< charge_threshold_uv */
        self.add(pr.RemoteVariable(
            name         = 'ChargeThreshold_UV',
            description  = 'Buckets whose charge exceeds this ADC count are considered bunches',
            offset       = 0x500,
            bitSize      = 32,
            bitOffset    = 0,
            base         = pr.Float,
            mode         = 'RW',
        ))

        #define ABORTISSUE_CHARGE_THRESHOLD_DV 0x504/**< charge_threshold_dv */
        self.add(pr.RemoteVariable(
            name         = 'ChargeThreshold_DV',
            description  = 'Buckets whose charge exceeds this ADC count are considered bunches',
            offset       = 0x504,
            bitSize      = 32,
            bitOffset    = 0,
            base         = pr.Float,
            mode         = 'RW',
        ))

        #define ABORTISSUE_ABORT_THRESHOLD 0x508/**< abort_threshold */
        self.add(pr.RemoteVariable(
            name         = 'AbortThreshold',
            description  = 'Triggers when the moving average exceeds x times the moving standard deviation',
            offset       = 0x508,
            bitSize      = 32,
            bitOffset    = 0,
            base         = pr.Float,
            mode         = 'RW',
        ))

        #define ABORTISSUE_ABORT_ON 0x50C/**< abort_on */
        self.add(pr.RemoteVariable(
            name         = 'AbortON',
            description  = 'When this is 1, the abort notification system is turned on',
            offset       = 0x50C,
            bitSize      = 1,
            mode         = 'RW',
            enum        = {
                0x0: 'Abort OFF',
                0x1: 'Abort ON',
            },
        ))

        #define ABORTISSUE_MA_RESET 0x510/**< ma_reset */
        self.add(pr.RemoteVariable(
            name         = 'MAReset',
            description  = 'While this is set to 1, 0 is input to the FIFO and the MA will be reset',
            offset       = 0x510,
            bitSize      = 1,
            mode         = 'RW',
            enum        = {
                0x0: 'Running',
                0x1: 'Reset',
            },
        ))

        #define ABORTISSUE_STORED_THRESHOLD 0x514/**< stored_threshold */
        self.add(pr.RemoteVariable(
            name         = 'Stored Threshold',
            description  = 'When charge of all bunches in one turn exceeds this number, abort system is on',
            offset       = 0x514,
            bitSize      = 32,
            bitOffset    = 0,
            base         = pr.Float,
            mode         = 'RW',
        ))

        #define ABORTISSUE_ABORT_PREPARED 0x518/**< abort_prepared */
        self.add(pr.RemoteVariable(
            name         = 'Abort Prepared',
            description  = 'When this is 1, AbortOn and Beam is stored',
            offset       = 0x518,
            bitSize      = 1,
            mode         = 'RO',
        ))

        #define INJECTIONVETO_THRESHOLD 0x51C/**< InjectionVeto_threshold */
        self.add(pr.RemoteVariable(
            name         = 'InjectionVeto Threshold',
            description  = 'Injection Veto threshold is this number multiplied by STD',
            offset       = 0x51C,
            bitSize      = 32,
            bitOffset    = 0,
            base         = pr.Float,
            mode         = 'RW',
        ))

        #define POSITION_THRESHOLD_UV 0x520/**< Position_threshold_UV */
        self.add(pr.RemoteVariable(
            name         = 'Position Threshold UV',
            description  = 'Bunch whose position exceeds this number excluded',
            offset       = 0x520,
            bitSize      = 32,
            bitOffset    = 0,
            base         = pr.Float,
            mode         = 'RW',
        ))

        #define POSITION_THRESHOLD_DV 0x524/**< Position_threshold_DV */
        self.add(pr.RemoteVariable(
            name         = 'Position Threshold DV',
            description  = 'Bunch whose position exceeds this number excluded',
            offset       = 0x524,
            bitSize      = 32,
            bitOffset    = 0,
            base         = pr.Float,
            mode         = 'RW',
        ))
