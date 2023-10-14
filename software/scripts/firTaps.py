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
# Based on https://fiiir.com/
#-----------------------------------------------------------------------------
from __future__ import print_function
from __future__ import division

import numpy as np

# Example code, computes the coefficients of a low-pass windowed-sinc filter.

# Configuration.
fS = 2  # Sampling rate.
fL = 0.25  # Cutoff frequency.
N = 39  # Filter length, must be odd.

# Compute sinc filter.
h = np.sinc(2 * fL / fS * (np.arange(N) - (N - 1) / 2))

# Apply window.
h *= np.blackman(N)

# Normalize to get unity gain.
h /= np.sum(h)

# Print the comma separated string to load into Xilinx/Model_composer
myStr = ''
for i in h:
    myStr = f'{myStr},{i}'
print(myStr)

# Applying the filter to a signal s can be as simple as writing
# s = np.convolve(s, h)