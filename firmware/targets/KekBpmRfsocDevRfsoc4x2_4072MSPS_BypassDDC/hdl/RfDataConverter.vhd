-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: RfDataConverter Module
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
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
use surf.SsiPkg.all;

library work;
use work.AppPkg.all;

library axi_soc_ultra_plus_core;
use axi_soc_ultra_plus_core.AxiSocUltraPlusPkg.all;

library unisim;
use unisim.vcomponents.all;

entity RfDataConverter is
   generic (
      TPD_G            : time             := 1 ns;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- RF DATA CONVERTER Ports
      adcClkP         : in  slv(1 downto 0);
      adcClkN         : in  slv(1 downto 0);
      adcP            : in  slv(7 downto 0);
      adcN            : in  slv(7 downto 0);
      dacClkP         : in  slv(1 downto 0);
      dacClkN         : in  slv(1 downto 0);
      dacP            : out slv(7 downto 0);
      dacN            : out slv(7 downto 0);
      sysRefP         : in  sl;
      sysRefN         : in  sl;
      plClkP          : in  sl;
      plClkN          : in  sl;
      plSysRefP       : in  sl;
      plSysRefN       : in  sl;
      -- ADC Interface (dspClk domain)
      dspClk          : out sl;
      dspRst          : out sl;
      dspAdc          : out Slv256Array(NUM_ADC_CH_C-1 downto 0);
      dspRunCntrl     : in  sl;
      -- DAC Interface (dacClk domain)
      dacClk          : out sl;
      dacRst          : out sl;
      dspDacI         : in  Slv48Array(NUM_DAC_CH_C-1 downto 0);
      dspDacQ         : in  Slv48Array(NUM_DAC_CH_C-1 downto 0);
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType);
end RfDataConverter;

architecture mapping of RfDataConverter is

   component RfDataConverterIpCore
      port (
         adc0_clk_p      : in  std_logic;
         adc0_clk_n      : in  std_logic;
         clk_adc0        : out std_logic;
         adc2_clk_p      : in  std_logic;
         adc2_clk_n      : in  std_logic;
         clk_adc2        : out std_logic;
         dac0_clk_p      : in  std_logic;
         dac0_clk_n      : in  std_logic;
         clk_dac0        : out std_logic;
         dac2_clk_p      : in  std_logic;
         dac2_clk_n      : in  std_logic;
         clk_dac2        : out std_logic;
         s_axi_aclk      : in  std_logic;
         s_axi_aresetn   : in  std_logic;
         s_axi_awaddr    : in  std_logic_vector(17 downto 0);
         s_axi_awvalid   : in  std_logic;
         s_axi_awready   : out std_logic;
         s_axi_wdata     : in  std_logic_vector(31 downto 0);
         s_axi_wstrb     : in  std_logic_vector(3 downto 0);
         s_axi_wvalid    : in  std_logic;
         s_axi_wready    : out std_logic;
         s_axi_bresp     : out std_logic_vector(1 downto 0);
         s_axi_bvalid    : out std_logic;
         s_axi_bready    : in  std_logic;
         s_axi_araddr    : in  std_logic_vector(17 downto 0);
         s_axi_arvalid   : in  std_logic;
         s_axi_arready   : out std_logic;
         s_axi_rdata     : out std_logic_vector(31 downto 0);
         s_axi_rresp     : out std_logic_vector(1 downto 0);
         s_axi_rvalid    : out std_logic;
         s_axi_rready    : in  std_logic;
         irq             : out std_logic;
         sysref_in_p     : in  std_logic;
         sysref_in_n     : in  std_logic;
         user_sysref_adc : in  std_logic;
         user_sysref_dac : in  std_logic;
         vin0_01_p       : in  std_logic;
         vin0_01_n       : in  std_logic;
         vin0_23_p       : in  std_logic;
         vin0_23_n       : in  std_logic;
         vin2_01_p       : in  std_logic;
         vin2_01_n       : in  std_logic;
         vin2_23_p       : in  std_logic;
         vin2_23_n       : in  std_logic;
         vout00_p        : out std_logic;
         vout00_n        : out std_logic;
         vout20_p        : out std_logic;
         vout20_n        : out std_logic;
         m0_axis_aresetn : in  std_logic;
         m0_axis_aclk    : in  std_logic;
         m00_axis_tdata  : out std_logic_vector(127 downto 0);
         m00_axis_tvalid : out std_logic;
         m00_axis_tready : in  std_logic;
         m02_axis_tdata  : out std_logic_vector(127 downto 0);
         m02_axis_tvalid : out std_logic;
         m02_axis_tready : in  std_logic;
         m2_axis_aresetn : in  std_logic;
         m2_axis_aclk    : in  std_logic;
         m20_axis_tdata  : out std_logic_vector(127 downto 0);
         m20_axis_tvalid : out std_logic;
         m20_axis_tready : in  std_logic;
         m22_axis_tdata  : out std_logic_vector(127 downto 0);
         m22_axis_tvalid : out std_logic;
         m22_axis_tready : in  std_logic;
         s0_axis_aresetn : in  std_logic;
         s0_axis_aclk    : in  std_logic;
         s00_axis_tdata  : in  std_logic_vector(95 downto 0);
         s00_axis_tvalid : in  std_logic;
         s00_axis_tready : out std_logic;
         s2_axis_aresetn : in  std_logic;
         s2_axis_aclk    : in  std_logic;
         s20_axis_tdata  : in  std_logic_vector(95 downto 0);
         s20_axis_tvalid : in  std_logic;
         s20_axis_tready : out std_logic
         );
   end component;

   signal plClk    : sl := '0';
   signal refClk   : sl := '0';
   signal axilRstL : sl := '0';

   signal dspClock  : sl := '0';
   signal dspReset  : sl := '1';
   signal dspResetL : sl := '0';

   signal adcClock  : sl := '0';
   signal adcReset  : sl := '1';
   signal adcResetL : sl := '0';

   signal dacClock  : sl := '0';
   signal dacReset  : sl := '1';
   signal dacResetL : sl := '0';

   signal adcData : Slv128Array(NUM_ADC_CH_C-1 downto 0);
   signal adcRaw  : Slv128Array(NUM_ADC_CH_C-1 downto 0);

   signal plSysRefRaw : sl := '0';
   signal adcSysRef   : sl := '0';
   signal dacSysRef   : sl := '0';
   signal dummySig    : slv(1 downto 0);

   signal dacData : Slv96Array(NUM_DAC_CH_C-1 downto 0) := (others => (others => '0'));

begin

   U_plSysRefRaw : IBUFDS
      port map (
         I  => plSysRefP,
         IB => plSysRefN,
         O  => plSysRefRaw);

   U_adcSysRef : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => adcClock,
         dataIn  => plSysRefRaw,
         dataOut => adcSysRef);

   U_dacSysRef : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => dacClock,
         dataIn  => plSysRefRaw,
         dataOut => dacSysRef);

   U_IpCore : RfDataConverterIpCore
      port map (
         -- Clock Ports
         adc0_clk_p      => adcClkP(0),
         adc0_clk_n      => adcClkN(0),
         adc2_clk_p      => adcClkP(1),
         adc2_clk_n      => adcClkN(1),
         dac0_clk_p      => dacClkP(0),
         dac0_clk_n      => dacClkN(0),
         dac2_clk_p      => dacClkP(1),
         dac2_clk_n      => dacClkN(1),
         -- AXI-Lite Ports
         s_axi_aclk      => axilClk,
         s_axi_aresetn   => axilRstL,
         s_axi_awaddr    => axilWriteMaster.awaddr(17 downto 0),
         s_axi_awvalid   => axilWriteMaster.awvalid,
         s_axi_awready   => axilWriteSlave.awready,
         s_axi_wdata     => axilWriteMaster.wdata,
         s_axi_wstrb     => axilWriteMaster.wstrb,
         s_axi_wvalid    => axilWriteMaster.wvalid,
         s_axi_wready    => axilWriteSlave.wready,
         s_axi_bresp     => axilWriteSlave.bresp,
         s_axi_bvalid    => axilWriteSlave.bvalid,
         s_axi_bready    => axilWriteMaster.bready,
         s_axi_araddr    => axilReadMaster.araddr(17 downto 0),
         s_axi_arvalid   => axilReadMaster.arvalid,
         s_axi_arready   => axilReadSlave.arready,
         s_axi_rdata     => axilReadSlave.rdata,
         s_axi_rresp     => axilReadSlave.rresp,
         s_axi_rvalid    => axilReadSlave.rvalid,
         s_axi_rready    => axilReadMaster.rready,
         -- Misc. Ports
         sysref_in_p     => sysRefP,
         sysref_in_n     => sysRefN,
         user_sysref_adc => adcSysRef,
         user_sysref_dac => dacSysRef,
         -- ADC Ports
         vin0_01_p       => adcP(0),
         vin0_01_n       => adcN(0),
         vin0_23_p       => adcP(1),
         vin0_23_n       => adcN(1),
         vin2_01_p       => adcP(2),
         vin2_01_n       => adcN(2),
         vin2_23_p       => adcP(3),
         vin2_23_n       => adcN(3),
         -- DAC Ports
         vout00_p        => dacP(0),
         vout00_n        => dacN(0),
         vout20_p        => dacP(1),
         vout20_n        => dacN(1),
         -----------------------------------------
         -- Reserve Order to match PCB silkscreen:
         -----------------------------------------
         -- ADC_A = CH[0] = ADC_VIN_I23_226
         -- ADC_B = CH[1] = ADC_VIN_I01_226
         -- ADC_C = CH[2] = ADC_VIN_I23_224
         -- ADC_D = CH[3] = ADC_VIN_I01_224
         -----------------------------------------
         -- ADC[1:0] AXI Stream Interface (ADC_VIN_TILE224)
         m0_axis_aresetn => adcResetL,
         m0_axis_aclk    => adcClock,
         m00_axis_tdata  => adcRaw(3),
         m00_axis_tvalid => open,
         m00_axis_tready => '1',
         m02_axis_tdata  => adcRaw(2),
         m02_axis_tvalid => open,
         m02_axis_tready => '1',
         -- ADC[3:2] AXI Stream Interface (ADC_VIN_TILE226)
         m2_axis_aresetn => adcResetL,
         m2_axis_aclk    => adcClock,
         m20_axis_tdata  => adcRaw(1),
         m20_axis_tvalid => open,
         m20_axis_tready => '1',
         m22_axis_tdata  => adcRaw(0),
         m22_axis_tvalid => open,
         m22_axis_tready => '1',
         -----------------------------------------
         -- Reserve Order to match PCB silkscreen:
         -----------------------------------------
         -- DAC_A = CH[0] = DAC_VOUT0_230
         -- DAC_B = CH[1] = DAC_VOUT0_228
         -----------------------------------------
         -- DAC[0] AXI Stream Interface (DAC_VOUT_TILE228)
         s0_axis_aresetn => dacResetL,
         s0_axis_aclk    => dacClock,
         s00_axis_tdata  => dacData(1),
         s00_axis_tvalid => '1',
         s00_axis_tready => open,
         -- DAC[1] AXI Stream Interface  (DAC_VOUT_TILE230)
         s2_axis_aresetn => dacResetL,
         s2_axis_aclk    => dacClock,
         s20_axis_tdata  => dacData(0),
         s20_axis_tvalid => '1',
         s20_axis_tready => open);

   U_IBUFDS : IBUFDS
      port map(
         I  => plClkP,
         IB => plClkN,
         O  => plClk);

   U_BUFG : BUFG
      port map(
         I => plClk,
         O => refClk);

   U_AdcPll : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G             => TPD_G,
         TYPE_G            => "PLL",
         INPUT_BUFG_G      => false,
         FB_BUFG_G         => true,
         RST_IN_POLARITY_G => '1',
         NUM_CLOCKS_G      => 1,
         -- MMCM attributes
         CLKIN_PERIOD_G    => 1.964,
         DIVCLK_DIVIDE_G   => 2,
         CLKFBOUT_MULT_G   => 4,
         CLKOUT0_DIVIDE_G  => 2)
      port map(
         -- Clock Input
         clkIn     => refClk,           -- 509 MHz
         rstIn     => axilRst,
         -- Clock Outputs
         clkOut(0) => adcClock,         -- 509 MHz
         -- Reset Outputs
         rstOut(0) => dummySig(0));

   U_DacPll : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G             => TPD_G,
         TYPE_G            => "PLL",
         INPUT_BUFG_G      => false,
         FB_BUFG_G         => true,
         RST_IN_POLARITY_G => '1',
         NUM_CLOCKS_G      => 1,
         -- MMCM attributes
         CLKIN_PERIOD_G    => 1.964,
         DIVCLK_DIVIDE_G   => 2,
         CLKFBOUT_MULT_G   => 4,
         CLKOUT0_DIVIDE_G  => 4)
      port map(
         -- Clock Input
         clkIn     => refClk,
         rstIn     => axilRst,
         -- Clock Outputs
         clkOut(0) => dacClock,         -- 254.5 MHz
         -- Reset Outputs
         rstOut(0) => dummySig(1));

   axilRstL  <= not(axilRst);
   adcResetL <= not(adcReset);
   dspResetL <= not(dspReset);
   dacResetL <= not(dacReset);

   dacClk <= dacClock;
   dacRst <= dacReset;

   dspClock <= dacClock;
   dspReset <= dummySig(1);  -- Use the stable reset back to application

   dspClk <= dspClock;
   dspRst <= dspReset;

   U_adcReset : entity surf.RstSync
      generic map(
         TPD_G          => TPD_G,
         IN_POLARITY_G  => '0',
         OUT_POLARITY_G => '1')
      port map(
         clk      => adcClock,
         asyncRst => dspRunCntrl,
         syncRst  => adcReset);

   U_dacReset : entity surf.RstSync
      generic map(
         TPD_G          => TPD_G,
         IN_POLARITY_G  => '0',
         OUT_POLARITY_G => '1')
      port map(
         clk      => dacClock,
         asyncRst => dspRunCntrl,
         syncRst  => dacReset);

   ----------------------------------------------------------------
   -- Correct for a _P/_N swap on the RFSoC 4x2 hardware on TILE224
   ----------------------------------------------------------------
   -- ADC_A = CH[0] = ADC_VIN_I23_226
   -- ADC_B = CH[1] = ADC_VIN_I01_226
   -- ADC_C = CH[2] = ADC_VIN_I23_224 (swapped in HW)
   -- ADC_D = CH[3] = ADC_VIN_I01_224 (swapped in HW)
   ----------------------------------------------------------------
   adcData(0) <= adcRaw(0);
   adcData(1) <= adcRaw(1);
   adcData(2) <= not adcRaw(2);
   adcData(3) <= not adcRaw(3);

   U_Gearbox : entity axi_soc_ultra_plus_core.Ssr8ToSsr16Gearbox
      generic map (
         TPD_G    => TPD_G,
         NUM_CH_G => NUM_ADC_CH_C)
      port map (
         -- Slave Interface
         wrClk  => adcClock,
         wrData => adcData,
         -- Master Interface
         rdClk  => dspClock,
         rdRst  => dspReset,
         rdData => dspAdc);

   process(dacClock)
   begin
      if rising_edge(dacClock) then
         for ch in NUM_DAC_CH_C-1 downto 0 loop
            for i in 2 downto 0 loop
               -- I/Q pairs being mapped into the RFDC's input vector
               dacData(ch)(15+32*i downto 0+32*i)  <= dspDacI(ch)(15+16*i downto 16*i) after TPD_G;
               dacData(ch)(31+32*i downto 16+32*i) <= dspDacQ(ch)(15+16*i downto 16*i) after TPD_G;
            end loop;
         end loop;
      end if;
   end process;

end mapping;
