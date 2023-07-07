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
      TPD_G            : time := 1 ns;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := (others=>'0'));
   port (
      -- RF DATA CONVERTER Ports
      adcClkP         : in  slv(3 downto 0);
      adcClkN         : in  slv(3 downto 0);
      adcP            : in  slv(7 downto 0);
      adcN            : in  slv(7 downto 0);
      dacClkP         : in  slv(1 downto 0);
      dacClkN         : in  slv(1 downto 0);
      dacP            : out slv(7 downto 0);
      dacN            : out slv(7 downto 0);
      sysRefP         : in  sl;
      sysRefN         : in  sl;
      -- ADC/DAC Interface (dspClk domain)
      dspClk          : out sl;
      dspRst          : out sl;
      dspAdcI         : out Slv32Array(NUM_ADC_CH_C-1 downto 0);
      dspAdcQ         : out Slv32Array(NUM_ADC_CH_C-1 downto 0);
      dspDacI         : in  Slv32Array(NUM_DAC_CH_C-1 downto 0);
      dspDacQ         : in  Slv32Array(NUM_DAC_CH_C-1 downto 0);
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
         adc1_clk_p      : in  std_logic;
         adc1_clk_n      : in  std_logic;
         clk_adc1        : out std_logic;
         m1_axis_aclk    : in  std_logic;
         m1_axis_aresetn : in  std_logic;
         vin1_23_p       : in  std_logic;
         vin1_23_n       : in  std_logic;
         m12_axis_tdata  : out std_logic_vector (31 downto 0);
         m12_axis_tvalid : out std_logic;
         m12_axis_tready : in  std_logic;
         m13_axis_tdata  : out std_logic_vector (31 downto 0);
         m13_axis_tvalid : out std_logic;
         m13_axis_tready : in  std_logic;
         dac1_clk_p      : in  std_logic;
         dac1_clk_n      : in  std_logic;
         clk_dac1        : out std_logic;
         s1_axis_aclk    : in  std_logic;
         s1_axis_aresetn : in  std_logic;
         vout11_p        : out std_logic;
         vout11_n        : out std_logic;
         s11_axis_tdata  : in  std_logic_vector (63 downto 0);
         s11_axis_tvalid : in  std_logic;
         s11_axis_tready : out std_logic;
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
         adc1_clk_p      => adcClkP(1),
         adc1_clk_n      => adcClkN(1),
         clk_adc1        => refClk,
         dac1_clk_p      => dacClkP(1),
         dac1_clk_n      => dacClkN(1),
         clk_dac1        => open,
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
         irq             => open,
         sysref_in_p     => sysRefP,
         sysref_in_n     => sysRefN,
         -- ADC Ports
         vin1_23_p       => adcP(3),
         vin1_23_n       => adcN(3),
         -- DAC Ports
         vout11_p        => dacP(5),
         vout11_n        => dacN(5),
         -- ADC[3] AXI Stream Interface
         m1_axis_aresetn => dspResetL,
         m1_axis_aclk    => dspClock,
         m12_axis_tdata  => dspAdcI(0), -- dspAdc(0) = I (2 samples)
         m12_axis_tvalid => open,
         m12_axis_tready => '1',
         m13_axis_tdata  => dspAdcQ(0), -- dspAdc(1) = Q (2 samples)
         m13_axis_tvalid => open,
         m13_axis_tready => '1',
         -- DAC[5] AXI Stream Interface
         s1_axis_aresetn => dspResetL,
         s1_axis_aclk    => dspClock,
         s11_axis_tdata(15 downto 0)  => dspDacI(0)(15 downto 0),  -- I[1st sample)
         s11_axis_tdata(31 downto 16) => dspDacQ(0)(15 downto 0),  -- Q[1st sample)
         s11_axis_tdata(47 downto 32) => dspDacI(0)(31 downto 16),  -- I[2nd sample)
         s11_axis_tdata(63 downto 48) => dspDacQ(0)(31 downto 16),  -- Q[2nd sample)
         s11_axis_tvalid => '1',
         s11_axis_tready => open);

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
