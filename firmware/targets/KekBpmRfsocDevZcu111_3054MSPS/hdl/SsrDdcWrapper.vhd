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
      dspClk        : in  sl;
      dspRst        : in  sl;
      ncoConfig     : in  slv(31 downto 0);
      fineDelay     : in  Slv4Array(3 downto 0);
      adcIn         : in  Slv192Array(3 downto 0);
      selectdirect  : in  sl;
      ampOut        : out Slv192Array(3 downto 0));
end SsrDdcWrapper;

architecture mapping of SsrDdcWrapper is

   component ssr_ddc_0
      port (
         enablenco    : in  std_logic_vector (0 to 0);
         selectdirect : in  std_logic_vector (0 to 0);
         adcin0_0     : in  std_logic_vector (11 downto 0);
         adcin0_1     : in  std_logic_vector (11 downto 0);
         adcin0_2     : in  std_logic_vector (11 downto 0);
         adcin0_3     : in  std_logic_vector (11 downto 0);
         adcin0_4     : in  std_logic_vector (11 downto 0);
         adcin0_5     : in  std_logic_vector (11 downto 0);
         adcin0_6     : in  std_logic_vector (11 downto 0);
         adcin0_7     : in  std_logic_vector (11 downto 0);
         adcin0_8     : in  std_logic_vector (11 downto 0);
         adcin0_9     : in  std_logic_vector (11 downto 0);
         adcin0_10    : in  std_logic_vector (11 downto 0);
         adcin0_11    : in  std_logic_vector (11 downto 0);
         adcin1_0     : in  std_logic_vector (11 downto 0);
         adcin1_1     : in  std_logic_vector (11 downto 0);
         adcin1_2     : in  std_logic_vector (11 downto 0);
         adcin1_3     : in  std_logic_vector (11 downto 0);
         adcin1_4     : in  std_logic_vector (11 downto 0);
         adcin1_5     : in  std_logic_vector (11 downto 0);
         adcin1_6     : in  std_logic_vector (11 downto 0);
         adcin1_7     : in  std_logic_vector (11 downto 0);
         adcin1_8     : in  std_logic_vector (11 downto 0);
         adcin1_9     : in  std_logic_vector (11 downto 0);
         adcin1_10    : in  std_logic_vector (11 downto 0);
         adcin1_11    : in  std_logic_vector (11 downto 0);
         adcin2_0     : in  std_logic_vector (11 downto 0);
         adcin2_1     : in  std_logic_vector (11 downto 0);
         adcin2_2     : in  std_logic_vector (11 downto 0);
         adcin2_3     : in  std_logic_vector (11 downto 0);
         adcin2_4     : in  std_logic_vector (11 downto 0);
         adcin2_5     : in  std_logic_vector (11 downto 0);
         adcin2_6     : in  std_logic_vector (11 downto 0);
         adcin2_7     : in  std_logic_vector (11 downto 0);
         adcin2_8     : in  std_logic_vector (11 downto 0);
         adcin2_9     : in  std_logic_vector (11 downto 0);
         adcin2_10    : in  std_logic_vector (11 downto 0);
         adcin2_11    : in  std_logic_vector (11 downto 0);
         adcin3_0     : in  std_logic_vector (11 downto 0);
         adcin3_1     : in  std_logic_vector (11 downto 0);
         adcin3_2     : in  std_logic_vector (11 downto 0);
         adcin3_3     : in  std_logic_vector (11 downto 0);
         adcin3_4     : in  std_logic_vector (11 downto 0);
         adcin3_5     : in  std_logic_vector (11 downto 0);
         adcin3_6     : in  std_logic_vector (11 downto 0);
         adcin3_7     : in  std_logic_vector (11 downto 0);
         adcin3_8     : in  std_logic_vector (11 downto 0);
         adcin3_9     : in  std_logic_vector (11 downto 0);
         adcin3_10    : in  std_logic_vector (11 downto 0);
         adcin3_11    : in  std_logic_vector (11 downto 0);
         ncoconfig_0  : in  std_logic_vector (31 downto 0);
         ncoconfig_1  : in  std_logic_vector (31 downto 0);
         ncoconfig_2  : in  std_logic_vector (31 downto 0);
         ncoconfig_3  : in  std_logic_vector (31 downto 0);
         ncoconfig_4  : in  std_logic_vector (31 downto 0);
         ncoconfig_5  : in  std_logic_vector (31 downto 0);
         ncoconfig_6  : in  std_logic_vector (31 downto 0);
         ncoconfig_7  : in  std_logic_vector (31 downto 0);
         ncoconfig_8  : in  std_logic_vector (31 downto 0);
         ncoconfig_9  : in  std_logic_vector (31 downto 0);
         ncoconfig_10 : in  std_logic_vector (31 downto 0);
         ncoconfig_11 : in  std_logic_vector (31 downto 0);
         clk          : in  std_logic;
         ampout0_0    : out std_logic_vector (15 downto 0);
         ampout0_1    : out std_logic_vector (15 downto 0);
         ampout0_2    : out std_logic_vector (15 downto 0);
         ampout0_3    : out std_logic_vector (15 downto 0);
         ampout0_4    : out std_logic_vector (15 downto 0);
         ampout0_5    : out std_logic_vector (15 downto 0);
         ampout0_6    : out std_logic_vector (15 downto 0);
         ampout0_7    : out std_logic_vector (15 downto 0);
         ampout0_8    : out std_logic_vector (15 downto 0);
         ampout0_9    : out std_logic_vector (15 downto 0);
         ampout0_10   : out std_logic_vector (15 downto 0);
         ampout0_11   : out std_logic_vector (15 downto 0);
         ampout1_0    : out std_logic_vector (15 downto 0);
         ampout1_1    : out std_logic_vector (15 downto 0);
         ampout1_2    : out std_logic_vector (15 downto 0);
         ampout1_3    : out std_logic_vector (15 downto 0);
         ampout1_4    : out std_logic_vector (15 downto 0);
         ampout1_5    : out std_logic_vector (15 downto 0);
         ampout1_6    : out std_logic_vector (15 downto 0);
         ampout1_7    : out std_logic_vector (15 downto 0);
         ampout1_8    : out std_logic_vector (15 downto 0);
         ampout1_9    : out std_logic_vector (15 downto 0);
         ampout1_10   : out std_logic_vector (15 downto 0);
         ampout1_11   : out std_logic_vector (15 downto 0);
         ampout2_0    : out std_logic_vector (15 downto 0);
         ampout2_1    : out std_logic_vector (15 downto 0);
         ampout2_2    : out std_logic_vector (15 downto 0);
         ampout2_3    : out std_logic_vector (15 downto 0);
         ampout2_4    : out std_logic_vector (15 downto 0);
         ampout2_5    : out std_logic_vector (15 downto 0);
         ampout2_6    : out std_logic_vector (15 downto 0);
         ampout2_7    : out std_logic_vector (15 downto 0);
         ampout2_8    : out std_logic_vector (15 downto 0);
         ampout2_9    : out std_logic_vector (15 downto 0);
         ampout2_10   : out std_logic_vector (15 downto 0);
         ampout2_11   : out std_logic_vector (15 downto 0);
         ampout3_0    : out std_logic_vector (15 downto 0);
         ampout3_1    : out std_logic_vector (15 downto 0);
         ampout3_2    : out std_logic_vector (15 downto 0);
         ampout3_3    : out std_logic_vector (15 downto 0);
         ampout3_4    : out std_logic_vector (15 downto 0);
         ampout3_5    : out std_logic_vector (15 downto 0);
         ampout3_6    : out std_logic_vector (15 downto 0);
         ampout3_7    : out std_logic_vector (15 downto 0);
         ampout3_8    : out std_logic_vector (15 downto 0);
         ampout3_9    : out std_logic_vector (15 downto 0);
         ampout3_10   : out std_logic_vector (15 downto 0);
         ampout3_11   : out std_logic_vector (15 downto 0)
         );
   end component;

   signal enableNco : sl                      := '0';
   signal direct    : sl                      := '0';
   signal nco       : slv(31 downto 0)        := (others => '0');
   signal adc0      : Slv16Array(11 downto 0) := (others => (others => '0'));
   signal adc1      : Slv16Array(11 downto 0) := (others => (others => '0'));
   signal adc2      : Slv16Array(11 downto 0) := (others => (others => '0'));
   signal adc3      : Slv16Array(11 downto 0) := (others => (others => '0'));
   signal amp0      : Slv16Array(11 downto 0) := (others => (others => '0'));
   signal amp1      : Slv16Array(11 downto 0) := (others => (others => '0'));
   signal amp2      : Slv16Array(11 downto 0) := (others => (others => '0'));
   signal amp3      : Slv16Array(11 downto 0) := (others => (others => '0'));
   signal ampSig    : Slv192Array(3 downto 0) := (others => (others => '0'));
   signal ampDly    : Slv192Array(3 downto 0) := (others => (others => '0'));
   signal ampVec    : Slv512Array(3 downto 0) := (others => (others => '0'));

begin

   -- Help with making timing
   process(dspClk)
   begin
      if rising_edge(dspClk) then
         enableNco <= not(dspRst)  after TPD_G;
         nco       <= ncoConfig    after TPD_G;
         direct    <= selectdirect after TPD_G;
         for i in 0 to 11 loop
            adc0(i) <= adcIn(0)(i*16+15 downto i*16) after TPD_G;
            adc1(i) <= adcIn(1)(i*16+15 downto i*16) after TPD_G;
            adc2(i) <= adcIn(2)(i*16+15 downto i*16) after TPD_G;
            adc3(i) <= adcIn(3)(i*16+15 downto i*16) after TPD_G;
         end loop;
      end if;
   end process;

   U_SsrDdc : ssr_ddc_0
      port map (
         -- Clock
         clk          => dspClk,
         -- select DDC or direct
         selectdirect(0) => direct,
         -- NCO Interface
         enableNco(0) => enableNco,
         ncoconfig_0  => nco,
         ncoconfig_1  => nco,
         ncoconfig_2  => nco,
         ncoconfig_3  => nco,
         ncoconfig_4  => nco,
         ncoconfig_5  => nco,
         ncoconfig_6  => nco,
         ncoconfig_7  => nco,
         ncoconfig_8  => nco,
         ncoconfig_9  => nco,
         ncoconfig_10 => nco,
         ncoconfig_11 => nco,
         -- ADC[0]
         adcin0_0     => adc0(0)(15 downto 4),
         adcin0_1     => adc0(1)(15 downto 4),
         adcin0_2     => adc0(2)(15 downto 4),
         adcin0_3     => adc0(3)(15 downto 4),
         adcin0_4     => adc0(4)(15 downto 4),
         adcin0_5     => adc0(5)(15 downto 4),
         adcin0_6     => adc0(6)(15 downto 4),
         adcin0_7     => adc0(7)(15 downto 4),
         adcin0_8     => adc0(8)(15 downto 4),
         adcin0_9     => adc0(9)(15 downto 4),
         adcin0_10    => adc0(10)(15 downto 4),
         adcin0_11    => adc0(11)(15 downto 4),
         -- ADC[1]
         adcin1_0     => adc1(0)(15 downto 4),
         adcin1_1     => adc1(1)(15 downto 4),
         adcin1_2     => adc1(2)(15 downto 4),
         adcin1_3     => adc1(3)(15 downto 4),
         adcin1_4     => adc1(4)(15 downto 4),
         adcin1_5     => adc1(5)(15 downto 4),
         adcin1_6     => adc1(6)(15 downto 4),
         adcin1_7     => adc1(7)(15 downto 4),
         adcin1_8     => adc1(8)(15 downto 4),
         adcin1_9     => adc1(9)(15 downto 4),
         adcin1_10    => adc1(10)(15 downto 4),
         adcin1_11    => adc1(11)(15 downto 4),
         -- ADC[2]
         adcin2_0     => adc2(0)(15 downto 4),
         adcin2_1     => adc2(1)(15 downto 4),
         adcin2_2     => adc2(2)(15 downto 4),
         adcin2_3     => adc2(3)(15 downto 4),
         adcin2_4     => adc2(4)(15 downto 4),
         adcin2_5     => adc2(5)(15 downto 4),
         adcin2_6     => adc2(6)(15 downto 4),
         adcin2_7     => adc2(7)(15 downto 4),
         adcin2_8     => adc2(8)(15 downto 4),
         adcin2_9     => adc2(9)(15 downto 4),
         adcin2_10    => adc2(10)(15 downto 4),
         adcin2_11    => adc2(11)(15 downto 4),
         -- ADC[3]
         adcin3_0     => adc3(0)(15 downto 4),
         adcin3_1     => adc3(1)(15 downto 4),
         adcin3_2     => adc3(2)(15 downto 4),
         adcin3_3     => adc3(3)(15 downto 4),
         adcin3_4     => adc3(4)(15 downto 4),
         adcin3_5     => adc3(5)(15 downto 4),
         adcin3_6     => adc3(6)(15 downto 4),
         adcin3_7     => adc3(7)(15 downto 4),
         adcin3_8     => adc3(8)(15 downto 4),
         adcin3_9     => adc3(9)(15 downto 4),
         adcin3_10    => adc3(10)(15 downto 4),
         adcin3_11    => adc3(11)(15 downto 4),
         -- AMP[0]
         ampout0_0    => amp0(0),
         ampout0_1    => amp0(1),
         ampout0_2    => amp0(2),
         ampout0_3    => amp0(3),
         ampout0_4    => amp0(4),
         ampout0_5    => amp0(5),
         ampout0_6    => amp0(6),
         ampout0_7    => amp0(7),
         ampout0_8    => amp0(8),
         ampout0_9    => amp0(9),
         ampout0_10   => amp0(10),
         ampout0_11   => amp0(11),
         -- AMP[1]
         ampout1_0    => amp1(0),
         ampout1_1    => amp1(1),
         ampout1_2    => amp1(2),
         ampout1_3    => amp1(3),
         ampout1_4    => amp1(4),
         ampout1_5    => amp1(5),
         ampout1_6    => amp1(6),
         ampout1_7    => amp1(7),
         ampout1_8    => amp1(8),
         ampout1_9    => amp1(9),
         ampout1_10   => amp1(10),
         ampout1_11   => amp1(11),
         -- AMP[2]
         ampout2_0    => amp2(0),
         ampout2_1    => amp2(1),
         ampout2_2    => amp2(2),
         ampout2_3    => amp2(3),
         ampout2_4    => amp2(4),
         ampout2_5    => amp2(5),
         ampout2_6    => amp2(6),
         ampout2_7    => amp2(7),
         ampout2_8    => amp2(8),
         ampout2_9    => amp2(9),
         ampout2_10   => amp2(10),
         ampout2_11   => amp2(11),
         -- AMP[3]
         ampout3_0    => amp3(0),
         ampout3_1    => amp3(1),
         ampout3_2    => amp3(2),
         ampout3_3    => amp3(3),
         ampout3_4    => amp3(4),
         ampout3_5    => amp3(5),
         ampout3_6    => amp3(6),
         ampout3_7    => amp3(7),
         ampout3_8    => amp3(8),
         ampout3_9    => amp3(9),
         ampout3_10   => amp3(10),
         ampout3_11   => amp3(11));

   GEN_VEC_A :
   for i in 11 downto 0 generate
      ampSig(0)(i*16+15 downto i*16) <= amp0(i);
      ampSig(1)(i*16+15 downto i*16) <= amp1(i);
      ampSig(2)(i*16+15 downto i*16) <= amp2(i);
      ampSig(3)(i*16+15 downto i*16) <= amp3(i);
   end generate GEN_VEC_A;

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
