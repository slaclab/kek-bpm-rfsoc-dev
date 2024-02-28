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
         dac1_clk_p      : in  std_logic;
         dac1_clk_n      : in  std_logic;
         clk_dac1        : out std_logic;
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
         vout01_p        : out std_logic;
         vout01_n        : out std_logic;
         vout02_p        : out std_logic;
         vout02_n        : out std_logic;
         vout03_p        : out std_logic;
         vout03_n        : out std_logic;
         vout10_p        : out std_logic;
         vout10_n        : out std_logic;
         vout11_p        : out std_logic;
         vout11_n        : out std_logic;
         vout12_p        : out std_logic;
         vout12_n        : out std_logic;
         vout13_p        : out std_logic;
         vout13_n        : out std_logic;
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
         s01_axis_tdata  : in  std_logic_vector(95 downto 0);
         s01_axis_tvalid : in  std_logic;
         s01_axis_tready : out std_logic;
         s02_axis_tdata  : in  std_logic_vector(95 downto 0);
         s02_axis_tvalid : in  std_logic;
         s02_axis_tready : out std_logic;
         s03_axis_tdata  : in  std_logic_vector(95 downto 0);
         s03_axis_tvalid : in  std_logic;
         s03_axis_tready : out std_logic;
         s1_axis_aresetn : in  std_logic;
         s1_axis_aclk    : in  std_logic;
         s10_axis_tdata  : in  std_logic_vector(95 downto 0);
         s10_axis_tvalid : in  std_logic;
         s10_axis_tready : out std_logic;
         s11_axis_tdata  : in  std_logic_vector(95 downto 0);
         s11_axis_tvalid : in  std_logic;
         s11_axis_tready : out std_logic;
         s12_axis_tdata  : in  std_logic_vector(95 downto 0);
         s12_axis_tvalid : in  std_logic;
         s12_axis_tready : out std_logic;
         s13_axis_tdata  : in  std_logic_vector(95 downto 0);
         s13_axis_tvalid : in  std_logic;
         s13_axis_tready : out std_logic
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
         adc0_clk_p    => adcClkP(0),
         adc0_clk_n    => adcClkN(0),
         adc2_clk_p    => adcClkP(2),
         adc2_clk_n    => adcClkN(2),
         dac0_clk_p    => dacClkP(0),
         dac0_clk_n    => dacClkN(0),
         dac1_clk_p    => dacClkP(1),
         dac1_clk_n    => dacClkN(1),
         -- AXI-Lite Ports
         s_axi_aclk    => axilClk,
         s_axi_aresetn => axilRstL,
         s_axi_awaddr  => axilWriteMaster.awaddr(17 downto 0),
         s_axi_awvalid => axilWriteMaster.awvalid,
         s_axi_awready => axilWriteSlave.awready,
         s_axi_wdata   => axilWriteMaster.wdata,
         s_axi_wstrb   => axilWriteMaster.wstrb,
         s_axi_wvalid  => axilWriteMaster.wvalid,
         s_axi_wready  => axilWriteSlave.wready,
         s_axi_bresp   => axilWriteSlave.bresp,
         s_axi_bvalid  => axilWriteSlave.bvalid,
         s_axi_bready  => axilWriteMaster.bready,
         s_axi_araddr  => axilReadMaster.araddr(17 downto 0),
         s_axi_arvalid => axilReadMaster.arvalid,
         s_axi_arready => axilReadSlave.arready,
         s_axi_rdata   => axilReadSlave.rdata,
         s_axi_rresp   => axilReadSlave.rresp,
         s_axi_rvalid  => axilReadSlave.rvalid,
         s_axi_rready  => axilReadMaster.rready,

         -- Misc. Ports
         sysref_in_p     => sysRefP,
         sysref_in_n     => sysRefN,
         user_sysref_adc => adcSysRef,
         user_sysref_dac => dacSysRef,

         -- ADC Ports
         vin0_01_p => adcP(0),
         vin0_01_n => adcN(0),
         vin0_23_p => adcP(1),
         vin0_23_n => adcN(1),
         vin2_01_p => adcP(4),
         vin2_01_n => adcN(4),
         vin2_23_p => adcP(5),
         vin2_23_n => adcN(5),
         -- DAC Ports
         vout00_p  => dacP(0),
         vout00_n  => dacN(0),
         vout01_p  => dacP(1),
         vout01_n  => dacN(1),
         vout02_p  => dacP(2),
         vout02_n  => dacN(2),
         vout03_p  => dacP(3),
         vout03_n  => dacN(3),
         vout10_p  => dacP(4),
         vout10_n  => dacN(4),
         vout11_p  => dacP(5),
         vout11_n  => dacN(5),
         vout12_p  => dacP(6),
         vout12_n  => dacN(6),
         vout13_p  => dacP(7),
         vout13_n  => dacN(7),

         -- ADC[3:0] AXI Stream Interface
         m0_axis_aresetn => adcResetL,
         m0_axis_aclk    => adcClock,

         m00_axis_tdata  => adcData(0),
         m00_axis_tvalid => open,
         m00_axis_tready => '1',

         m02_axis_tdata  => adcData(1),
         m02_axis_tvalid => open,
         m02_axis_tready => '1',

         m2_axis_aresetn => adcResetL,
         m2_axis_aclk    => adcClock,
         m20_axis_tdata  => adcData(2),
         m20_axis_tvalid => open,
         m20_axis_tready => '1',

         m22_axis_tdata  => adcData(3),
         m22_axis_tvalid => open,
         m22_axis_tready => '1',

         -- DAC[3:0] AXI Stream Interface
         s0_axis_aresetn => dacResetL,
         s0_axis_aclk    => dacClock,
         s00_axis_tdata  => (others => '0'),  -- Unused
         s00_axis_tvalid => '1',
         s00_axis_tready => open,
         s01_axis_tdata  => (others => '0'),  -- Unused
         s01_axis_tvalid => '1',
         s01_axis_tready => open,
         s02_axis_tdata  => (others => '0'),  -- Unused
         s02_axis_tvalid => '1',
         s02_axis_tready => open,
         s03_axis_tdata  => (others => '0'),  -- Unused
         s03_axis_tvalid => '1',
         s03_axis_tready => open,

         -- DAC[7:4] AXI Stream Interface
         s1_axis_aresetn => dacResetL,
         s1_axis_aclk    => dacClock,
         s10_axis_tdata  => dacData(0),
         s10_axis_tvalid => '1',
         s10_axis_tready => open,
         s11_axis_tdata  => dacData(1),
         s11_axis_tvalid => '1',
         s11_axis_tready => open,
         s12_axis_tdata  => dacData(0),
         s12_axis_tvalid => '1',
         s12_axis_tready => open,
         s13_axis_tdata  => dacData(1),
         s13_axis_tvalid => '1',
         s13_axis_tready => open);

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
         NUM_CLOCKS_G      => 2,
         -- MMCM attributes
         CLKIN_PERIOD_G    => 1.964,
         DIVCLK_DIVIDE_G   => 2,
         CLKFBOUT_MULT_G   => 4,
         CLKOUT0_DIVIDE_G  => 2,
         CLKOUT1_DIVIDE_G  => 4)
      port map(
         -- Clock Input
         clkIn     => refClk,
         rstIn     => axilRst,
         -- Clock Outputs
         clkOut(0) => adcClock,         -- 509.0 MHz
         clkOut(1) => dspClock,         -- 254.5 MHz
         -- Reset Outputs
         rstOut(0) => dummySig(0),
         rstOut(1) => dspReset);

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

   GEN_ADC :
   for i in NUM_ADC_CH_C-1 downto 0 generate
      U_Gearbox : entity surf.AsyncGearbox
         generic map (
            TPD_G              => TPD_G,
            SLAVE_WIDTH_G      => 128,
            MASTER_WIDTH_G     => 256,
            EN_EXT_CTRL_G      => false,
            -- Async FIFO generics
            FIFO_MEMORY_TYPE_G => "block",
            FIFO_ADDR_WIDTH_G  => 8)
         port map (
            -- Slave Interface
            slaveClk    => adcClock,
            slaveRst    => adcReset,
            slaveData   => adcData(i),
            slaveValid  => '1',
            slaveReady  => open,
            -- Master Interface
            masterClk   => dspClock,
            masterRst   => dspReset,
            masterData  => dspAdc(i),
            masterValid => open,
            masterReady => '1');
   end generate GEN_ADC;

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
