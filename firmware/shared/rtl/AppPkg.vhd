-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Application VHDL Package
-------------------------------------------------------------------------------
-- This file is part of 'kek_bpm_rfsoc_dev'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'kek_bpm_rfsoc_dev', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

package AppPkg is

   constant NUM_ADC_CH_C     : positive := 4;
   constant NUM_DAC_CH_C     : positive := 2;

   -------------------------------------------------
   -- DMA[lane=0].inbound  = ADC/DAC ring buffers
   -------------------------------------------------
   constant DMA_SIZE_C : positive := 1;

   constant AXIL_CLK_FREQ_C   : real := 100.0E+6;               -- Units of Hz
   constant AXIL_CLK_PERIOD_C : real := (1.0/AXIL_CLK_FREQ_C);  -- Units of seconds

end package AppPkg;
