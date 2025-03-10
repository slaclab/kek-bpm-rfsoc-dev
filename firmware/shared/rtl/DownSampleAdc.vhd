-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: DownSampleAdc Module
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;

entity DownSampleAdc is
   generic (
      TPD_G : time := 1 ns);
   port (
      dspClk    : in  sl;
      dspRst    : in  sl;
      fineDelay : in  Slv4Array(3 downto 0);
      adcIn     : in  Slv256Array(3 downto 0);
      muxSelect : in  sl;
      validOut  : out slv(7 downto 0);
      ampOut    : out Slv256Array(3 downto 0));
end DownSampleAdc;

architecture mapping of DownSampleAdc is

   signal ampSig   : Slv256Array(3 downto 0) := (others => (others => '0'));
   signal ampDly   : Slv256Array(3 downto 0) := (others => (others => '0'));
   signal ampVec   : Slv512Array(3 downto 0) := (others => (others => '0'));
   signal ampReg   : Slv256Array(3 downto 0) := (others => (others => '0'));
   signal ampShift : Slv256Array(3 downto 0) := (others => (others => '0'));

   signal cnt   : slv(2 downto 0) := (others => '0');
   signal valid : sl              := '1';

begin

   validOut <= x"F" & valid & valid & valid & valid;

   -- Help with making timing
   process(dspClk)
   begin
      if rising_edge(dspClk) then
         -- Bypassing the DDC
         ampSig <= adcIn after TPD_G;
      end if;
   end process;

   GEN_VEC_B :
   for i in 3 downto 0 generate
      ampVec(i) <= ampSig(i) & ampDly(i);
   end generate GEN_VEC_B;

   process(dspClk)
   begin
      if rising_edge(dspClk) then

         -- Generate the valid flag
         if (cnt = 0) then
            valid <= '1' after TPD_G;
         else
            valid <= not(muxSelect) after TPD_G;
         end if;
         cnt <= cnt + 1 after TPD_G;

         -- Check for raw data
         if (muxSelect = '0') then
            ampOut <= ampReg after TPD_G;

         -- Else use the down sampled bus
         else
            ampOut <= ampShift after TPD_G;
         end if;

         -- Loop through the ADC channels
         for i in 0 to 3 loop

            -- Update the shift register and load 1st and 8st samples to the top
            ampShift(i) <= ampReg(i)(143 downto 128) & ampReg(i)(15 downto 0) & ampShift(i)(255 downto 32);

            -- Pick off the delay from the vector
            ampReg(i) <= ampVec(i)(conv_integer(fineDelay(i))*16+255 downto conv_integer(fineDelay(i))*16) after TPD_G;

            -- Create a delayed copy for next cycle
            ampDly(i) <= ampSig(i) after TPD_G;

         end loop;
      end if;
   end process;

end mapping;
