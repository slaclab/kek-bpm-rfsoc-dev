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
      dacP            : out slv(2 downto 0);
      dacN            : out slv(2 downto 0);
      sysRefP         : in  sl;
      sysRefN         : in  sl;
      -- ADC/DAC Interface (dspClk domain)
      dspClk          : out sl;
      dspRst          : out sl;
      dspAdcI         : out Slv32Array(3 downto 0);
      dspAdcQ         : out Slv32Array(3 downto 0);
      dspDacI         : in  Slv32Array(1 downto 0);
      dspDacQ         : in  Slv32Array(1 downto 0);
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
         s_axi_aclk      : in  std_logic;
         s_axi_aresetn   : in  std_logic;
         s_axi_awaddr    : in  std_logic_vector (17 downto 0);
         s_axi_awvalid   : in  std_logic;
         s_axi_awready   : out std_logic;
         s_axi_wdata     : in  std_logic_vector (31 downto 0);
         s_axi_wstrb     : in  std_logic_vector (3 downto 0);
         s_axi_wvalid    : in  std_logic;
         s_axi_wready    : out std_logic;
         s_axi_bresp     : out std_logic_vector (1 downto 0);
         s_axi_bvalid    : out std_logic;
         s_axi_bready    : in  std_logic;
         s_axi_araddr    : in  std_logic_vector (17 downto 0);
         s_axi_arvalid   : in  std_logic;
         s_axi_arready   : out std_logic;
         s_axi_rdata     : out std_logic_vector (31 downto 0);
         s_axi_rresp     : out std_logic_vector (1 downto 0);
         s_axi_rvalid    : out std_logic;
         s_axi_rready    : in  std_logic;
         sysref_in_p     : in  std_logic;
         sysref_in_n     : in  std_logic;
         user_sysref_adc : in  std_logic;
         user_sysref_dac : in  std_logic;
         clk_adc0        : out std_logic;
         m0_axis_aclk    : in  std_logic;
         m0_axis_aresetn : in  std_logic;
         clk_adc1        : out std_logic;
         m1_axis_aclk    : in  std_logic;
         m1_axis_aresetn : in  std_logic;
         clk_adc2        : out std_logic;
         m2_axis_aclk    : in  std_logic;
         m2_axis_aresetn : in  std_logic;
         clk_adc3        : out std_logic;
         m3_axis_aclk    : in  std_logic;
         m3_axis_aresetn : in  std_logic;
         vin0_01_p       : in  std_logic;
         vin0_01_n       : in  std_logic;
         vin0_23_p       : in  std_logic;
         vin0_23_n       : in  std_logic;
         vin1_01_p       : in  std_logic;
         vin1_01_n       : in  std_logic;
         vin1_23_p       : in  std_logic;
         vin1_23_n       : in  std_logic;
         vin2_01_p       : in  std_logic;
         vin2_01_n       : in  std_logic;
         vin2_23_p       : in  std_logic;
         vin2_23_n       : in  std_logic;
         vin3_01_p       : in  std_logic;
         vin3_01_n       : in  std_logic;
         vin3_23_p       : in  std_logic;
         vin3_23_n       : in  std_logic;
         m00_axis_tdata  : out std_logic_vector (31 downto 0);
         m00_axis_tvalid : out std_logic;
         m00_axis_tready : in  std_logic;
         m01_axis_tdata  : out std_logic_vector (31 downto 0);
         m01_axis_tvalid : out std_logic;
         m01_axis_tready : in  std_logic;
         m02_axis_tdata  : out std_logic_vector (31 downto 0);
         m02_axis_tvalid : out std_logic;
         m02_axis_tready : in  std_logic;
         m03_axis_tdata  : out std_logic_vector (31 downto 0);
         m03_axis_tvalid : out std_logic;
         m03_axis_tready : in  std_logic;
         m10_axis_tdata  : out std_logic_vector (31 downto 0);
         m10_axis_tvalid : out std_logic;
         m10_axis_tready : in  std_logic;
         m11_axis_tdata  : out std_logic_vector (31 downto 0);
         m11_axis_tvalid : out std_logic;
         m11_axis_tready : in  std_logic;
         m12_axis_tdata  : out std_logic_vector (31 downto 0);
         m12_axis_tvalid : out std_logic;
         m12_axis_tready : in  std_logic;
         m13_axis_tdata  : out std_logic_vector (31 downto 0);
         m13_axis_tvalid : out std_logic;
         m13_axis_tready : in  std_logic;
         m20_axis_tdata  : out std_logic_vector (31 downto 0);
         m20_axis_tvalid : out std_logic;
         m20_axis_tready : in  std_logic;
         m21_axis_tdata  : out std_logic_vector (31 downto 0);
         m21_axis_tvalid : out std_logic;
         m21_axis_tready : in  std_logic;
         m22_axis_tdata  : out std_logic_vector (31 downto 0);
         m22_axis_tvalid : out std_logic;
         m22_axis_tready : in  std_logic;
         m23_axis_tdata  : out std_logic_vector (31 downto 0);
         m23_axis_tvalid : out std_logic;
         m23_axis_tready : in  std_logic;
         m30_axis_tdata  : out std_logic_vector (31 downto 0);
         m30_axis_tvalid : out std_logic;
         m30_axis_tready : in  std_logic;
         m31_axis_tdata  : out std_logic_vector (31 downto 0);
         m31_axis_tvalid : out std_logic;
         m31_axis_tready : in  std_logic;
         m32_axis_tdata  : out std_logic_vector (31 downto 0);
         m32_axis_tvalid : out std_logic;
         m32_axis_tready : in  std_logic;
         m33_axis_tdata  : out std_logic_vector (31 downto 0);
         m33_axis_tvalid : out std_logic;
         m33_axis_tready : in  std_logic;
         dac0_clk_p      : in  std_logic;
         dac0_clk_n      : in  std_logic;
         clk_dac0        : out std_logic;
         s0_axis_aclk    : in  std_logic;
         s0_axis_aresetn : in  std_logic;
         clk_dac1        : out std_logic;
         s1_axis_aclk    : in  std_logic;
         s1_axis_aresetn : in  std_logic;
         clk_dac2        : out std_logic;
         s2_axis_aclk    : in  std_logic;
         s2_axis_aresetn : in  std_logic;
         vout00_p        : out std_logic;
         vout00_n        : out std_logic;
         vout10_p        : out std_logic;
         vout10_n        : out std_logic;
         vout20_p        : out std_logic;
         vout20_n        : out std_logic;
         s00_axis_tdata  : in  std_logic_vector (63 downto 0);
         s00_axis_tvalid : in  std_logic;
         s00_axis_tready : out std_logic;
         s10_axis_tdata  : in  std_logic_vector (63 downto 0);
         s10_axis_tvalid : in  std_logic;
         s10_axis_tready : out std_logic;
         s20_axis_tdata  : in  std_logic_vector (63 downto 0);
         s20_axis_tvalid : in  std_logic;
         s20_axis_tready : out std_logic;
         irq             : out std_logic
         );
   end component;

   signal refClk   : sl := '0';
   signal axilRstL : sl := '0';

   signal dspClock  : sl := '0';
   signal dspReset  : sl := '1';
   signal dspResetL : sl := '0';

begin

   U_IpCore : RfDataConverterIpCore
      port map (
         -- Clock Ports
         clk_adc0                     => refClk,
         dac0_clk_p                   => dacClkP(0),
         dac0_clk_n                   => dacClkN(0),
         -- AXI-Lite Ports
         s_axi_aclk                   => axilClk,
         s_axi_aresetn                => axilRstL,
         s_axi_awaddr                 => axilWriteMaster.awaddr(17 downto 0),
         s_axi_awvalid                => axilWriteMaster.awvalid,
         s_axi_awready                => axilWriteSlave.awready,
         s_axi_wdata                  => axilWriteMaster.wdata,
         s_axi_wstrb                  => axilWriteMaster.wstrb,
         s_axi_wvalid                 => axilWriteMaster.wvalid,
         s_axi_wready                 => axilWriteSlave.wready,
         s_axi_bresp                  => axilWriteSlave.bresp,
         s_axi_bvalid                 => axilWriteSlave.bvalid,
         s_axi_bready                 => axilWriteMaster.bready,
         s_axi_araddr                 => axilReadMaster.araddr(17 downto 0),
         s_axi_arvalid                => axilReadMaster.arvalid,
         s_axi_arready                => axilReadSlave.arready,
         s_axi_rdata                  => axilReadSlave.rdata,
         s_axi_rresp                  => axilReadSlave.rresp,
         s_axi_rvalid                 => axilReadSlave.rvalid,
         s_axi_rready                 => axilReadMaster.rready,
         -- Misc. Ports
         sysref_in_p                  => sysRefP,
         sysref_in_n                  => sysRefN,
         user_sysref_adc              => '0',
         user_sysref_dac              => '0',
         -- ADC Ports
         vin0_01_p                    => adcP(0),
         vin0_01_n                    => adcN(0),
         vin0_23_p                    => adcP(1),
         vin0_23_n                    => adcN(1),
         vin1_01_p                    => adcP(2),
         vin1_01_n                    => adcN(2),
         vin1_23_p                    => adcP(3),
         vin1_23_n                    => adcN(3),
         vin2_01_p                    => adcP(4),
         vin2_01_n                    => adcN(4),
         vin2_23_p                    => adcP(5),
         vin2_23_n                    => adcN(5),
         vin3_01_p                    => adcP(6),
         vin3_01_n                    => adcN(6),
         vin3_23_p                    => adcP(7),
         vin3_23_n                    => adcN(7),
         -- DAC Ports
         vout00_p                     => dacP(0),
         vout00_n                     => dacN(0),
         vout10_p                     => dacP(1),
         vout10_n                     => dacN(1),
         vout20_p                     => dacP(2),
         vout20_n                     => dacN(2),
         -----------------------------------------
         -- Reserve Order to match PCB silkscreen:
         -----------------------------------------
         -- ADC_A = CH[0] = ADC_VIN_I23_226
         -- ADC_B = CH[1] = ADC_VIN_I01_226
         -- ADC_C = CH[2] = ADC_VIN_I23_224
         -- ADC_D = CH[3] = ADC_VIN_I01_224
         -----------------------------------------
         -- ADC[1:0] AXI Stream Interface (ADC_VIN_TILE224)
         m0_axis_aresetn              => dspResetL,
         m0_axis_aclk                 => dspClock,
         m00_axis_tdata               => dspAdcI(3),  -- dspAdc(3) = I (2 samples)
         m00_axis_tvalid              => open,
         m00_axis_tready              => '1',
         m01_axis_tdata               => dspAdcQ(3),  -- dspAdc(3) = Q (2 samples)
         m01_axis_tvalid              => open,
         m01_axis_tready              => '1',
         m02_axis_tdata               => dspAdcI(2),  -- dspAdc(2) = I (2 samples)
         m02_axis_tvalid              => open,
         m02_axis_tready              => '1',
         m03_axis_tdata               => dspAdcQ(2),  -- dspAdc(2) = Q (2 samples)
         m03_axis_tvalid              => open,
         m03_axis_tready              => '1',
         -- Unused TILE but needed for CLK source from TILE228 distribution (ADC_VIN_TILE225)
         m1_axis_aresetn              => dspResetL,
         m1_axis_aclk                 => dspClock,
         m10_axis_tdata               => open,
         m10_axis_tvalid              => open,
         m10_axis_tready              => '1',
         m11_axis_tdata               => open,
         m11_axis_tvalid              => open,
         m11_axis_tready              => '1',
         m12_axis_tdata               => open,
         m12_axis_tvalid              => open,
         m12_axis_tready              => '1',
         m13_axis_tdata               => open,
         m13_axis_tvalid              => open,
         m13_axis_tready              => '1',
         -- ADC[3:2] AXI Stream Interface (ADC_VIN_TILE226)
         m2_axis_aresetn              => dspResetL,
         m2_axis_aclk                 => dspClock,
         m20_axis_tdata               => dspAdcI(1),  -- dspAdc(1) = I (2 samples)
         m20_axis_tvalid              => open,
         m20_axis_tready              => '1',
         m21_axis_tdata               => dspAdcQ(1),  -- dspAdc(1) = Q (2 samples)
         m21_axis_tvalid              => open,
         m21_axis_tready              => '1',
         m22_axis_tdata               => dspAdcI(0),  -- dspAdc(0) = I (2 samples)
         m22_axis_tvalid              => open,
         m22_axis_tready              => '1',
         m23_axis_tdata               => dspAdcQ(0),  -- dspAdc(0) = Q (2 samples)
         m23_axis_tvalid              => open,
         m23_axis_tready              => '1',
         -- Unused TILE but needed for CLK source from TILE228 distribution (ADC_VIN_TILE227)
         m3_axis_aresetn              => dspResetL,
         m3_axis_aclk                 => dspClock,
         m30_axis_tdata               => open,
         m30_axis_tvalid              => open,
         m30_axis_tready              => '1',
         m31_axis_tdata               => open,
         m31_axis_tvalid              => open,
         m31_axis_tready              => '1',
         m32_axis_tdata               => open,
         m32_axis_tvalid              => open,
         m32_axis_tready              => '1',
         m33_axis_tdata               => open,
         m33_axis_tvalid              => open,
         m33_axis_tready              => '1',
         -----------------------------------------
         -- Reserve Order to match PCB silkscreen:
         -----------------------------------------
         -- DAC_A = CH[0] = DAC_VOUT0_230
         -- DAC_B = CH[1] = DAC_VOUT0_228
         -----------------------------------------
         -- DAC[0] AXI Stream Interface (DAC_VOUT_TILE228)
         s0_axis_aresetn              => dspResetL,
         s0_axis_aclk                 => dspClock,
         s00_axis_tdata(15 downto 0)  => dspDacI(1)(15 downto 0),  -- I[1st sample)
         s00_axis_tdata(31 downto 16) => dspDacQ(1)(15 downto 0),  -- Q[1st sample)
         s00_axis_tdata(47 downto 32) => dspDacI(1)(31 downto 16),  -- I[2nd sample)
         s00_axis_tdata(63 downto 48) => dspDacQ(1)(31 downto 16),  -- Q[2nd sample)
         s00_axis_tvalid              => '1',
         s00_axis_tready              => open,
         -- Unused TILE but needed for CLK source from TILE228 distribution
         s1_axis_aresetn              => dspResetL,
         s1_axis_aclk                 => dspClock,
         s10_axis_tdata               => (others => '0'),
         s10_axis_tvalid              => '1',
         s10_axis_tready              => open,
         -- DAC[1] AXI Stream Interface  (DAC_VOUT_TILE230)
         s2_axis_aresetn              => dspResetL,
         s2_axis_aclk                 => dspClock,
         s20_axis_tdata(15 downto 0)  => dspDacI(0)(15 downto 0),  -- I[1st sample)
         s20_axis_tdata(31 downto 16) => dspDacQ(0)(15 downto 0),  -- Q[1st sample)
         s20_axis_tdata(47 downto 32) => dspDacI(0)(31 downto 16),  -- I[2nd sample)
         s20_axis_tdata(63 downto 48) => dspDacQ(0)(31 downto 16),  -- Q[2nd sample)
         s20_axis_tvalid              => '1',
         s20_axis_tready              => open);

   U_Pll : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G             => TPD_G,
         TYPE_G            => "PLL",
         INPUT_BUFG_G      => false,
         FB_BUFG_G         => true,
         RST_IN_POLARITY_G => '1',
         NUM_CLOCKS_G      => 1,
         -- MMCM attributes
         CLKIN_PERIOD_G    => 3.929,    -- 254.5 MHz
         CLKFBOUT_MULT_G   => 4,        -- 1018 MHz = 4 x 254.5MHz
         CLKOUT0_DIVIDE_G  => 4)        -- 254.5 MHz = 1018MHz/4
      port map(
         -- Clock Input
         clkIn     => refClk,
         rstIn     => axilRst,
         -- Clock Outputs
         clkOut(0) => dspClock,
         -- Reset Outputs
         rstOut(0) => dspReset);

   axilRstL  <= not(axilRst);
   dspResetL <= not(dspReset);

   dspClk <= dspClock;
   dspRst <= dspReset;

end mapping;
