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
use surf.AxiPkg.all;

library work;
use work.AppPkg.all;

library axi_soc_ultra_plus_core;
use axi_soc_ultra_plus_core.AxiSocUltraPlusPkg.all;

entity KekBpmRfsocDevRfsoc4x2_4072MSPS_BypassDDC is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      -- DDR4 Ports
      ddrClkP     : in    sl;
      ddrClkN     : in    sl;
      ddrDm       : inout slv(7 downto 0);
      ddrDqsP     : inout slv(7 downto 0);
      ddrDqsN     : inout slv(7 downto 0);
      ddrDq       : inout slv(63 downto 0);
      ddrA        : out   slv(16 downto 0);
      ddrBa       : out   slv(1 downto 0);
      ddrCsL      : out   slv(0 downto 0);
      ddrOdt      : out   slv(0 downto 0);
      ddrCke      : out   slv(0 downto 0);
      ddrCkP      : out   slv(0 downto 0);
      ddrCkN      : out   slv(0 downto 0);
      ddrBg       : out   slv(0 downto 0);
      ddrActL     : out   sl;
      ddrRstL     : out   sl;
      -- System Ports
      userLed     : out   slv(3 downto 0);
      pmod        : inout Slv8Array(1 downto 0);
      irigTrigOut : inout sl;           -- Trigger input from 1PPS SMA
      irigCompOut : inout sl;           -- Trigger input from 1PPS SMA
      -- RF DATA CONVERTER Ports
      adcClkP     : in    slv(1 downto 0);
      adcClkN     : in    slv(1 downto 0);
      adcP        : in    slv(7 downto 0);
      adcN        : in    slv(7 downto 0);
      dacClkP     : in    slv(1 downto 0);
      dacClkN     : in    slv(1 downto 0);
      dacP        : out   slv(7 downto 0);
      dacN        : out   slv(7 downto 0);
      sysRefP     : in    sl;
      sysRefN     : in    sl;
      plClkP      : in    sl;
      plClkN      : in    sl;
      plSysRefP   : in    sl;
      plSysRefN   : in    sl;
      -- SYSMON Ports
      vPIn        : in    sl;
      vNIn        : in    sl);
end KekBpmRfsocDevRfsoc4x2_4072MSPS_BypassDDC;

architecture top_level of KekBpmRfsocDevRfsoc4x2_4072MSPS_BypassDDC is

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

   signal ddrClk         : sl;
   signal ddrRst         : sl;
   signal ddrReady       : sl;
   signal ddrWriteMaster : AxiWriteMasterType;
   signal ddrWriteSlave  : AxiWriteSlaveType;
   signal ddrReadMaster  : AxiReadMasterType;
   signal ddrReadSlave   : AxiReadSlaveType;

begin

   userLed(0) <= not(axilRst);
   userLed(1) <= not(dmaRst);
   userLed(2) <= not(dspRst);
   userLed(3) <= '1';

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
         adcClkP         => adcClkP,
         adcClkN         => adcClkN,
         adcP            => adcP,
         adcN            => adcN,
         dacClkP         => dacClkP,
         dacClkN         => dacClkN,
         dacP            => dacP,
         dacN            => dacN,
         sysRefP         => sysRefP,
         sysRefN         => sysRefN,
         plClkP          => plClkP,
         plClkN          => plClkN,
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
         TPD_G            => TPD_G,
         AXIL_BASE_ADDR_G => AXIL_CONFIG_C(APP_INDEX_C).baseAddr)
      port map (
         -- DDR AXI4 Interface
         ddrClk              => ddrClk,
         ddrRst              => ddrRst,
         ddrReady            => ddrReady,
         ddrWriteMaster      => ddrWriteMaster,
         ddrWriteSlave       => ddrWriteSlave,
         ddrReadMaster       => ddrReadMaster,
         ddrReadSlave        => ddrReadSlave,
         -- PMOD Ports
         pmod(0)(5 downto 0) => pmod(0)(5 downto 0),
         pmod(0)(6)          => irigTrigOut,  -- Trigger input from 1PPS SMA
         pmod(0)(7)          => irigCompOut,  -- Trigger input from 1PPS SMA
         pmod(1)             => pmod(1),
         -- DMA Interface (dmaClk domain)
         dmaClk              => dmaClk,
         dmaRst              => dmaRst,
         dmaIbMaster         => dmaIbMasters(0),
         dmaIbSlave          => dmaIbSlaves(0),
         -- ADC Interface (dspClk domain)
         dspClk              => dspClk,
         dspRst              => dspRst,
         dspAdc              => dspAdc,
         dspRunCntrl         => dspRunCntrl,
         -- DAC Interface (dacClk domain)
         dacClk              => dacClk,
         dacRst              => dacRst,
         dspDacI             => dspDacI,
         dspDacQ             => dspDacQ,
         -- AXI-Lite Interface (axilClk domain)
         axilClk             => axilClk,
         axilRst             => axilRst,
         axilWriteMaster     => axilWriteMasters(APP_INDEX_C),
         axilWriteSlave      => axilWriteSlaves(APP_INDEX_C),
         axilReadMaster      => axilReadMasters(APP_INDEX_C),
         axilReadSlave       => axilReadSlaves(APP_INDEX_C));

   ----------------------------
   -- PL DDR4 Memory Controller
   ----------------------------
   U_PL_MEM : entity axi_soc_ultra_plus_core.MigCoreWrapper
      generic map (
         TPD_G => TPD_G)
      port map (
         extRst         => dspRst,
         -- AXI4 Interface
         ddrClk         => ddrClk,
         ddrRst         => ddrRst,
         ddrReady       => ddrReady,
         ddrWriteMaster => ddrWriteMaster,
         ddrWriteSlave  => ddrWriteSlave,
         ddrReadMaster  => ddrReadMaster,
         ddrReadSlave   => ddrReadSlave,
         ----------------
         -- Core Ports --
         ----------------
         -- DDR4 Ports
         ddrClkP        => ddrClkP,
         ddrClkN        => ddrClkN,
         ddrDm          => ddrDm,
         ddrDqsP        => ddrDqsP,
         ddrDqsN        => ddrDqsN,
         ddrDq          => ddrDq,
         ddrA           => ddrA,
         ddrBa          => ddrBa,
         ddrCsL         => ddrCsL,
         ddrOdt         => ddrOdt,
         ddrCke         => ddrCke,
         ddrCkP         => ddrCkP,
         ddrCkN         => ddrCkN,
         ddrBg          => ddrBg,
         ddrActL        => ddrActL,
         ddrRstL        => ddrRstL);

end top_level;

