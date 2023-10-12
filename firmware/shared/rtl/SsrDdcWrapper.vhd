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

library surf;
use surf.StdRtlPkg.all;

entity SsrDdcWrapper is
   generic (
      TPD_G : time := 1 ns);
   port (
      dspClk    : in  sl;
      dspRst    : in  sl;
      ncoConfig : in  slv(47 downto 0);
      adcIn     : in  slv(127 downto 0);
      ampOut    : out slv(127 downto 0));
end SsrDdcWrapper;

architecture mapping of SsrDdcWrapper is

   component ssr_ddc_0
      port (
         adcin_0     : in  std_logic_vector (11 downto 0);
         adcin_1     : in  std_logic_vector (11 downto 0);
         adcin_2     : in  std_logic_vector (11 downto 0);
         adcin_3     : in  std_logic_vector (11 downto 0);
         adcin_4     : in  std_logic_vector (11 downto 0);
         adcin_5     : in  std_logic_vector (11 downto 0);
         adcin_6     : in  std_logic_vector (11 downto 0);
         adcin_7     : in  std_logic_vector (11 downto 0);
         ncoconfig_0 : in  std_logic_vector (47 downto 0);
         ncoconfig_1 : in  std_logic_vector (47 downto 0);
         ncoconfig_2 : in  std_logic_vector (47 downto 0);
         ncoconfig_3 : in  std_logic_vector (47 downto 0);
         ncoconfig_4 : in  std_logic_vector (47 downto 0);
         ncoconfig_5 : in  std_logic_vector (47 downto 0);
         ncoconfig_6 : in  std_logic_vector (47 downto 0);
         ncoconfig_7 : in  std_logic_vector (47 downto 0);
         clk         : in  std_logic;
         ampout_0    : out std_logic_vector (15 downto 0);
         ampout_1    : out std_logic_vector (15 downto 0);
         ampout_2    : out std_logic_vector (15 downto 0);
         ampout_3    : out std_logic_vector (15 downto 0);
         ampout_4    : out std_logic_vector (15 downto 0);
         ampout_5    : out std_logic_vector (15 downto 0);
         ampout_6    : out std_logic_vector (15 downto 0);
         ampout_7    : out std_logic_vector (15 downto 0);
         imagout_0   : out std_logic_vector (15 downto 0);
         imagout_1   : out std_logic_vector (15 downto 0);
         imagout_2   : out std_logic_vector (15 downto 0);
         imagout_3   : out std_logic_vector (15 downto 0);
         imagout_4   : out std_logic_vector (15 downto 0);
         imagout_5   : out std_logic_vector (15 downto 0);
         imagout_6   : out std_logic_vector (15 downto 0);
         imagout_7   : out std_logic_vector (15 downto 0);
         realout_0   : out std_logic_vector (15 downto 0);
         realout_1   : out std_logic_vector (15 downto 0);
         realout_2   : out std_logic_vector (15 downto 0);
         realout_3   : out std_logic_vector (15 downto 0);
         realout_4   : out std_logic_vector (15 downto 0);
         realout_5   : out std_logic_vector (15 downto 0);
         realout_6   : out std_logic_vector (15 downto 0);
         realout_7   : out std_logic_vector (15 downto 0)
         );
   end component;

   signal nco : slv(47 downto 0)       := (others => '0');
   signal adc : Slv16Array(7 downto 0) := (others => (others => '0'));
   signal amp : Slv16Array(7 downto 0) := (others => (others => '0'));
   signal I   : Slv16Array(7 downto 0) := (others => (others => '0'));
   signal Q   : Slv16Array(7 downto 0) := (others => (others => '0'));

   attribute dont_touch        : string;
   attribute dont_touch of adc : signal is "TRUE";
   attribute dont_touch of amp : signal is "TRUE";
   attribute dont_touch of I   : signal is "TRUE";
   attribute dont_touch of Q   : signal is "TRUE";

begin

   -- Help with making timing
   process(dspClk)
   begin
      if rising_edge(dspClk) then
         nco <= ncoConfig after TPD_G;
         for i in 0 to 7 loop

            adc(i) <= adcIn(i*16+15 downto i*16) after TPD_G;

            ampOut(i*16+15 downto i*16) <= amp(i) after TPD_G;

         end loop;
      end if;
   end process;

   U_SsrDdc : ssr_ddc_0
      port map (
         adcin_0     => adc(0)(15 downto 4),
         adcin_1     => adc(1)(15 downto 4),
         adcin_2     => adc(2)(15 downto 4),
         adcin_3     => adc(3)(15 downto 4),
         adcin_4     => adc(4)(15 downto 4),
         adcin_5     => adc(5)(15 downto 4),
         adcin_6     => adc(6)(15 downto 4),
         adcin_7     => adc(7)(15 downto 4),
         ncoconfig_0 => nco,
         ncoconfig_1 => nco,
         ncoconfig_2 => nco,
         ncoconfig_3 => nco,
         ncoconfig_4 => nco,
         ncoconfig_5 => nco,
         ncoconfig_6 => nco,
         ncoconfig_7 => nco,
         clk         => dspClk,
         ampout_0    => amp(0),
         ampout_1    => amp(1),
         ampout_2    => amp(2),
         ampout_3    => amp(3),
         ampout_4    => amp(4),
         ampout_5    => amp(5),
         ampout_6    => amp(6),
         ampout_7    => amp(7),
         imagout_0   => Q(0),
         imagout_1   => Q(1),
         imagout_2   => Q(2),
         imagout_3   => Q(3),
         imagout_4   => Q(4),
         imagout_5   => Q(5),
         imagout_6   => Q(6),
         imagout_7   => Q(7),
         realout_0   => I(0),
         realout_1   => I(1),
         realout_2   => I(2),
         realout_3   => I(3),
         realout_4   => I(4),
         realout_5   => I(5),
         realout_6   => I(6),
         realout_7   => I(7));

end mapping;
