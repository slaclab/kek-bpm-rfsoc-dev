-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: SsrDdcWrapper Module
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

entity SsrDdcWrapper is
   generic (
      TPD_G : time := 1 ns);
   port (
      dspClk       : in  sl;
      dspRst       : in  sl;
      ncoConfig    : in  slv(31 downto 0);
      fineDelay    : in  Slv4Array(3 downto 0);
      adcIn        : in  Slv192Array(3 downto 0);
      selectdirect : in  sl;
      ampOut       : out Slv192Array(3 downto 0));
end SsrDdcWrapper;

architecture mapping of SsrDdcWrapper is

   signal ampSig : Slv192Array(3 downto 0) := (others => (others => '0'));
   signal ampDly : Slv192Array(3 downto 0) := (others => (others => '0'));
   signal ampVec : Slv512Array(3 downto 0) := (others => (others => '0'));

begin

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
      ampVec(i)(383 downto 0) <= ampSig(i) & ampDly(i);
   end generate GEN_VEC_B;

   process(dspClk)
   begin
      if rising_edge(dspClk) then
         for i in 0 to 3 loop

            -- Pick off the delay from the vector
            ampOut(i) <= ampVec(i)(conv_integer(fineDelay(i))*16+191 downto conv_integer(fineDelay(i))*16) after TPD_G;

            -- Create a delayed copy for next cycle
            ampDly(i) <= ampSig(i) after TPD_G;

         end loop;
      end if;
   end process;

end mapping;
