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

class PosCalc(pr.Device):
    def __init__(self,**kwargs):
        super().__init__(**kwargs)

        #define POSCALC_CODEVERSION 0x0/**< codeversion */
        self.add(pr.RemoteVariable(
            name         = 'Version',
            description  = 'Version Number',
            offset       = 0x000,
            bitSize      = 32,
            mode         = 'RO',
        ))

        #define POSCALC_SCRATCHPAD 0xffc/**< scratchpad */
        self.add(pr.RemoteVariable(
            name         = 'ScratchPad',
            description  = 'Register to test reads and writes',
            offset       = 0xFFC,
            bitSize      = 32,
            mode         = 'RW',
            hidden       = True,
        ))

        #define POSCALC_GAIN_D 0x30c/**< gain_d */
        #define POSCALC_GAIN_C 0x308/**< gain_c */
        #define POSCALC_GAIN_B 0x304/**< gain_b */
        #define POSCALC_GAIN_A 0x300/**< gain_a */
        self.addRemoteVariables(
            name         = 'AmpGainCorrect',
            description  = 'Amplitude Gain Correction',
            offset       = 0x300,
            bitSize      = 32,
            bitOffset    = 0,
            base         = pr.Float,
            mode         = 'RW',
            number       = 4,
            stride       = 4,
        )

        #define POSCALC_COEFFICIENT_X9 0x124/**< coefficient_x9 */
        #define POSCALC_COEFFICIENT_X8 0x120/**< coefficient_x8 */
        #define POSCALC_COEFFICIENT_X7 0x11c/**< coefficient_x7 */
        #define POSCALC_COEFFICIENT_X6 0x118/**< coefficient_x6 */
        #define POSCALC_COEFFICIENT_X5 0x114/**< coefficient_x5 */
        #define POSCALC_COEFFICIENT_X4 0x110/**< coefficient_x4 */
        #define POSCALC_COEFFICIENT_X3 0x10c/**< coefficient_x3 */
        #define POSCALC_COEFFICIENT_X2 0x108/**< coefficient_x2 */
        #define POSCALC_COEFFICIENT_X1 0x104/**< coefficient_x1 */
        #define POSCALC_COEFFICIENT_X 0x100/**< coefficient_x */
        self.addRemoteVariables(
            name         = 'xCoeff',
            description  = 'Coefficients for x',
            offset       = 0x100,
            bitSize      = 32,
            bitOffset    = 0,
            base         = pr.Float,
            disp         = '{:0.2e}', # Display 2 digits after the decimal, and e for scientific notation
            mode         = 'RW',
            number       = 10,
            stride       = 4,
        )

        #define POSCALC_COEFFICIENT_Y9 0x224/**< coefficient_y9 */
        #define POSCALC_COEFFICIENT_Y8 0x220/**< coefficient_y8 */
        #define POSCALC_COEFFICIENT_Y7 0x21c/**< coefficient_y7 */
        #define POSCALC_COEFFICIENT_Y6 0x218/**< coefficient_y6 */
        #define POSCALC_COEFFICIENT_Y5 0x214/**< coefficient_y5 */
        #define POSCALC_COEFFICIENT_Y4 0x210/**< coefficient_y4 */
        #define POSCALC_COEFFICIENT_Y3 0x20c/**< coefficient_y3 */
        #define POSCALC_COEFFICIENT_Y2 0x208/**< coefficient_y2 */
        #define POSCALC_COEFFICIENT_Y1 0x204/**< coefficient_y1 */
        #define POSCALC_COEFFICIENT_Y 0x200/**< coefficient_y */
        self.addRemoteVariables(
            name         = 'yCoeff',
            description  = 'Coefficients for Y',
            offset       = 0x200,
            bitSize      = 32,
            bitOffset    = 0,
            base         = pr.Float,
            disp         = '{:0.2e}', # Display 2 digits after the decimal, and e for scientific notation
            mode         = 'RW',
            number       = 10,
            stride       = 4,
        )
