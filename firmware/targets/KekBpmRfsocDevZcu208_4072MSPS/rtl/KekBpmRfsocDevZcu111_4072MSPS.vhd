-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Top Level Firmware Target
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

library work;
use work.AppPkg.all;

library axi_soc_ultra_plus_core;
use axi_soc_ultra_plus_core.AxiSocUltraPlusPkg.all;

entity KekBpmRfsocDevZcu208_4072MSPS is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      -- RFMC Ports
      adcio      : inout slv(7 downto 0);
      dacio      : inout slv(7 downto 0);
      -- RF DATA CONVERTER Ports
      adcP       : in    slv(7 downto 0);
      adcN       : in    slv(7 downto 0);
      dacClk228P : in    sl;
      dacClk228N : in    sl;
      dacP       : out   slv(7 downto 0);
      dacN       : out   slv(7 downto 0);
      sysRefP    : in    sl;
      sysRefN    : in    sl;
      plSysRefP  : in    sl;
      plSysRefN  : in    sl;
      -- SYSMON Ports
      vPIn       : in    sl;
      vNIn       : in    sl);
end KekBpmRfsocDevZcu208_4072MSPS;

architecture top_level of KekBpmRfsocDevZcu208_4072MSPS is

   constant HW_INDEX_C   : natural := 0;
   constant RFDC_INDEX_C : natural := 1;
   constant APP_INDEX_C  : natural := 2;

   constant NUM_AXIL_MASTERS_C : positive := 3;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, APP_ADDR_OFFSET_C, 31, 28);

   signal dmaClk          : sl;
   signal dmaRst          : sl;
   signal dmaBuffGrpPause : slv(7 downto 0);
   signal dmaObMasters    : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaObSlaves     : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal dmaIbMasters    : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dmaIbSlaves     : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;

   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal dspClk      : sl;
   signal dspRst      : sl;
   signal dspAdc      : Slv256Array(NUM_ADC_CH_C-1 downto 0);
   signal dspRunCntrl : sl;

   signal dacClk  : sl;
   signal dacRst  : sl;
   signal dspDacI : Slv48Array(NUM_DAC_CH_C-1 downto 0);
   signal dspDacQ : Slv48Array(NUM_DAC_CH_C-1 downto 0);

begin

   -----------------------
   -- Common Platform Core
   -----------------------
   U_Core : entity axi_soc_ultra_plus_core.AxiSocUltraPlusCore
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         EXT_AXIL_MASTER_G => false,
         DMA_SIZE_G        => DMA_SIZE_C)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         -- DSP Clock and Reset Monitoring
         dspClk          => dspClk,
         dspRst          => dspRst,
         -- AUX Clock and Reset
         auxClk          => axilClk,
         auxRst          => axilRst,
         -- DMA Interfaces  (dmaClk domain)
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- Application AXI-Lite Interfaces [0x80000000:0xFFFFFFFF] (appClk domain)
         appClk          => axilClk,
         appRst          => axilRst,
         appReadMaster   => axilReadMaster,
         appReadSlave    => axilReadSlave,
         appWriteMaster  => axilWriteMaster,
         appWriteSlave   => axilWriteSlave,
         -- SYSMON Ports
         vPIn            => vPIn,
         vNIn            => vNIn);

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   --------------------
   -- RF DATA CONVERTER
   --------------------
   U_RFDC : entity work.RfDataConverter
      generic map (
         TPD_G            => TPD_G,
         AXIL_BASE_ADDR_G => AXIL_CONFIG_C(RFDC_INDEX_C).baseAddr)
      port map (
         -- RF DATA CONVERTER Ports
         adcP            => adcP,
         adcN            => adcN,
         dacClk228P      => dacClk228P,
         dacClk228N      => dacClk228N,
         dacP            => dacP,
         dacN            => dacN,
         sysRefP         => sysRefP,
         sysRefN         => sysRefN,
         plSysRefP       => plSysRefP,
         plSysRefN       => plSysRefN,
         -- ADC Interface (dspClk domain)
         dspClk          => dspClk,
         dspRst          => dspRst,
         dspAdc          => dspAdc,
         dspRunCntrl     => dspRunCntrl,
         -- DAC Interface (dacClk domain)
         dacClk          => dacClk,
         dacRst          => dacRst,
         dspDacI         => dspDacI,
         dspDacQ         => dspDacQ,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilWriteMaster => axilWriteMasters(RFDC_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(RFDC_INDEX_C),
         axilReadMaster  => axilReadMasters(RFDC_INDEX_C),
         axilReadSlave   => axilReadSlaves(RFDC_INDEX_C));

   --------------
   -- Application
   --------------
   U_App : entity work.Application
      generic map (
         TPD_G                    => TPD_G,
         FAULT_BUFF_ADDR_WIDTH_G  => 14,
         FAULT_AMP_MEMORY_TYPE_G  => "mixed",
         FAULT_CALC_MEMORY_TYPE_G => "mixed",
         AXIL_BASE_ADDR_G         => AXIL_CONFIG_C(APP_INDEX_C).baseAddr)
      port map (
         -- PMOD Ports
         pmod(0)         => adcio,  -- Mapping the ZCU111.PMOD to ZCU208.RFMC ports
         pmod(1)         => dacio,  -- Mapping the ZCU111.PMOD to ZCU208.RFMC ports
         -- DMA Interface (dmaClk domain)
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaIbMaster     => dmaIbMasters(0),
         dmaIbSlave      => dmaIbSlaves(0),
         -- ADC Interface (dspClk domain)
         dspClk          => dspClk,
         dspRst          => dspRst,
         dspAdc          => dspAdc,
         dspRunCntrl     => dspRunCntrl,
         -- DAC Interface (dacClk domain)
         dacClk          => dacClk,
         dacRst          => dacRst,
         dspDacI         => dspDacI,
         dspDacQ         => dspDacQ,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilWriteMaster => axilWriteMasters(APP_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(APP_INDEX_C),
         axilReadMaster  => axilReadMasters(APP_INDEX_C),
         axilReadSlave   => axilReadSlaves(APP_INDEX_C));

end top_level;
