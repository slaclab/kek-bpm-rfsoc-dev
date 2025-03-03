-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Application Module
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
use surf.SsiPkg.all;

library work;
use work.AppPkg.all;

library axi_soc_ultra_plus_core;
use axi_soc_ultra_plus_core.AxiSocUltraPlusPkg.all;

entity Application is
   generic (
      TPD_G            : time := 1 ns;
      AXIL_BASE_ADDR_G : slv(31 downto 0));
   port (
      -- DDR AXI4 Interface
      ddrClk          : in    sl;
      ddrRst          : in    sl;
      ddrReady        : in    sl;
      ddrWriteMaster  : out   AxiWriteMasterType;
      ddrWriteSlave   : in    AxiWriteSlaveType;
      ddrReadMaster   : out   AxiReadMasterType;
      ddrReadSlave    : in    AxiReadSlaveType;
      -- PMOD Ports
      pmod            : inout Slv8Array(1 downto 0);
      -- DMA Interface (dmaClk domain)
      dmaClk          : in    sl;
      dmaRst          : in    sl;
      dmaIbMaster     : out   AxiStreamMasterType;
      dmaIbSlave      : in    AxiStreamSlaveType;
      -- ADC Interface (dspClk domain)
      dspClk          : in    sl;
      dspRst          : in    sl;
      dspAdc          : in    Slv256Array(NUM_ADC_CH_C-1 downto 0);
      dspRunCntrl     : out   sl;
      -- DAC Interface (dacClk domain)
      dacClk          : in    sl;
      dacRst          : in    sl;
      dspDacI         : out   Slv48Array(NUM_DAC_CH_C-1 downto 0);
      dspDacQ         : out   Slv48Array(NUM_DAC_CH_C-1 downto 0);
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType);
end Application;

architecture mapping of Application is

   constant SW_TRIG_INDEX_C    : natural := 0;
   constant DAC_SIG_INDEX_C    : natural := 1;
   constant RING_INDEX_C       : natural := 2;  -- 2:5
   constant POSCALC_INDEX_C    : natural := 6;
   constant NUM_AXIL_MASTERS_C : natural := 7;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 28, 24);

   signal dspReadMaster  : AxiLiteReadMasterType;
   signal dspReadSlave   : AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
   signal dspWriteMaster : AxiLiteWriteMasterType;
   signal dspWriteSlave  : AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;

   signal dspReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal dspReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal dspWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal dspWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal adc : Slv256Array(NUM_ADC_CH_C-1 downto 0) := (others => (others => '0'));
   signal amp : Slv256Array(NUM_ADC_CH_C-1 downto 0) := (others => (others => '0'));

   signal dacI : Slv48Array(NUM_DAC_CH_C-1 downto 0) := (others => (others => '0'));
   signal dacQ : Slv48Array(NUM_DAC_CH_C-1 downto 0) := (others => (others => '0'));

   signal dummmyVec : Slv16Array(3 downto 0) := (others => (others => '0'));

   signal sigGenTrig  : slv(1 downto 0);
   signal ncoConfig   : slv(31 downto 0);
   signal fineDelay   : Slv4Array(3 downto 0);
   signal courseDelay : Slv4Array(3 downto 0);
   signal muxSelect   : sl;

   signal xPos       : slv(31 downto 0);
   signal yPos       : slv(31 downto 0);
   signal charge     : slv(31 downto 0);
   signal calcResult : slv(95 downto 0);

   signal axisMasters : AxiStreamMasterArray(1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal axisSlaves  : AxiStreamSlaveArray(1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal dspReset : sl;

   signal dataValid : slv(7 downto 0);

   signal memWriteMaster : AxiWriteMasterType;
   signal memWriteSlave  : AxiWriteSlaveType;
   signal memReadMaster  : AxiReadMasterType;
   signal memReadSlave   : AxiReadSlaveType;

begin

   U_dspReset : entity surf.RstPipeline
      generic map(
         TPD_G     => TPD_G,
         INV_RST_G => false)
      port map(
         clk    => dspClk,
         rstIn  => dspRst,
         rstOut => dspReset);

   GEN_VEC :
   for i in 3 downto 0 generate
      U_adc : entity surf.SlvDelay
         generic map(
            TPD_G        => TPD_G,
            SRL_EN_G     => true,
            DELAY_G      => 16,
            REG_OUTPUT_G => true,
            WIDTH_G      => 256)
         port map (
            clk   => dspClk,
            delay => courseDelay(i),
            din   => dspAdc(i),
            dout  => adc(i));
   end generate GEN_VEC;

   process(dacClk)
   begin
      -- Help with making timing
      if rising_edge(dacClk) then
         dspDacI <= dacI after TPD_G;
         dspDacQ <= dacQ after TPD_G;
      end if;
   end process;

   U_AxiLiteAsync : entity surf.AxiLiteAsync
      generic map (
         TPD_G           => TPD_G,
         COMMON_CLK_G    => false,
         NUM_ADDR_BITS_G => 32)
      port map (
         -- Slave Interface
         sAxiClk         => axilClk,
         sAxiClkRst      => axilRst,
         sAxiReadMaster  => axilReadMaster,
         sAxiReadSlave   => axilReadSlave,
         sAxiWriteMaster => axilWriteMaster,
         sAxiWriteSlave  => axilWriteSlave,
         -- Master Interface
         mAxiClk         => dspClk,
         mAxiClkRst      => dspReset,
         mAxiReadMaster  => dspReadMaster,
         mAxiReadSlave   => dspReadSlave,
         mAxiWriteMaster => dspWriteMaster,
         mAxiWriteSlave  => dspWriteSlave);

   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => dspClk,
         axiClkRst           => dspReset,
         sAxiWriteMasters(0) => dspWriteMaster,
         sAxiWriteSlaves(0)  => dspWriteSlave,
         sAxiReadMasters(0)  => dspReadMaster,
         sAxiReadSlaves(0)   => dspReadSlave,
         mAxiWriteMasters    => dspWriteMasters,
         mAxiWriteSlaves     => dspWriteSlaves,
         mAxiReadMasters     => dspReadMasters,
         mAxiReadSlaves      => dspReadSlaves);

   U_DacSigGen : entity axi_soc_ultra_plus_core.SigGen
      generic map (
         TPD_G              => TPD_G,
         NUM_CH_G           => (2*NUM_DAC_CH_C),  -- I/Q pairs
         RAM_ADDR_WIDTH_G   => 9,
         SAMPLE_PER_CYCLE_G => 4,  -- SAMPLE_PER_CYCLE_G must be power of 2 for memMap(), only using lower 3 samples
         AXIL_BASE_ADDR_G   => AXIL_CONFIG_C(DAC_SIG_INDEX_C).baseAddr)
      port map (
         -- DAC Interface (dspClk domain)
         dspClk => dacClk,
         dspRst => dacRst,

         dspDacOut0(47 downto 0)  => dacI(0),
         dspDacOut0(63 downto 48) => dummmyVec(0),

         dspDacOut1(47 downto 0)  => dacQ(0),
         dspDacOut1(63 downto 48) => dummmyVec(1),

         dspDacOut2(47 downto 0)  => dacI(1),
         dspDacOut2(63 downto 48) => dummmyVec(2),

         dspDacOut3(47 downto 0)  => dacQ(1),
         dspDacOut3(63 downto 48) => dummmyVec(3),

         -- AXI-Lite Interface (axilClk domain)
         axilClk         => dspClk,
         axilRst         => dspReset,
         axilReadMaster  => dspReadMasters(DAC_SIG_INDEX_C),
         axilReadSlave   => dspReadSlaves(DAC_SIG_INDEX_C),
         axilWriteMaster => dspWriteMasters(DAC_SIG_INDEX_C),
         axilWriteSlave  => dspWriteSlaves(DAC_SIG_INDEX_C));

   U_DownSampleAdc : entity work.DownSampleAdc
      generic map (
         TPD_G => TPD_G)
      port map (
         dspClk    => dspClk,
         dspRst    => dspReset,
         adcIn     => adc,
         fineDelay => fineDelay,
         ampOut    => amp,
         validOut  => dataValid,
         muxSelect => muxSelect);

--   U_PosCalc : entity work.PosCalcWrapper
--      generic map (
--         TPD_G => TPD_G)
--      port map (
--         -- DSP Interface
--         dspClk          => dspClk,
--         dspRst          => dspReset,
--         ampPeakIn(0)    => amp(0)(15 downto 0),
--         ampPeakIn(1)    => amp(1)(15 downto 0),
--         ampPeakIn(2)    => amp(2)(15 downto 0),
--         ampPeakIn(3)    => amp(3)(15 downto 0),
--         xPos            => xPos,
--         yPos            => yPos,
--         charge          => charge,
--         -- AXI-Lite Interface
--         axilReadMaster  => dspReadMasters(POSCALC_INDEX_C),
--         axilReadSlave   => dspReadSlaves(POSCALC_INDEX_C),
--         axilWriteMaster => dspWriteMasters(POSCALC_INDEX_C),
--         axilWriteSlave  => dspWriteSlaves(POSCALC_INDEX_C));

--   calcResult <= charge & yPos & xPos;

   U_ReadoutCtrl : entity work.ReadoutCtrl
      generic map (
         TPD_G             => TPD_G,
         COURSE_DLY_INIT_G => (0 => x"0", 1 => x"0", 2 => x"1", 3 => x"1"))
      port map (
         -- PMOD Ports
         pmod            => pmod,
         -- DSP Interface
         dspClk          => dspClk,
         dspRst          => dspReset,
         sigGenTrig      => sigGenTrig,
         ncoConfig       => ncoConfig,
         dspRunCntrl     => dspRunCntrl,
         fineDelay       => fineDelay,
         courseDelay     => courseDelay,
         muxSelect       => muxSelect,
         -- AXI-Lite Interface
         axilReadMaster  => dspReadMasters(SW_TRIG_INDEX_C),
         axilReadSlave   => dspReadSlaves(SW_TRIG_INDEX_C),
         axilWriteMaster => dspWriteMasters(SW_TRIG_INDEX_C),
         axilWriteSlave  => dspWriteSlaves(SW_TRIG_INDEX_C));

   -------------------------------
   -- sigGenTrig(0) - Live Display
   -------------------------------
   -- Use this one!
   U_RingBufferLive : entity axi_soc_ultra_plus_core.AppRingBufferEngine
      generic map (
         TPD_G              => TPD_G,
         TDEST_ROUTES_G     => (
            0               => x"00",
            1               => x"01",
            2               => x"02",
            3               => x"03",
            4               => x"04",
            5               => x"05",
            6               => x"06",
            7               => x"07",
            8               => x"FF",
            9               => x"FF",
            10              => x"FF",
            11              => x"FF",
            12              => x"FF",
            13              => x"FF",
            14              => x"FF",
            15              => x"FF"),
         NUM_CH_G           => 8,
         SAMPLE_PER_CYCLE_G => 16,
         RAM_ADDR_WIDTH_G   => 9,
         MEMORY_TYPE_G      => "block",
         COMMON_CLK_G       => true,    -- true if dataClk=axilClk
         AXIL_BASE_ADDR_G   => AXIL_CONFIG_C(RING_INDEX_C+0).baseAddr)
      port map (
         -- AXI-Stream Interface (axisClk domain)
         axisClk         => dmaClk,
         axisRst         => dmaRst,
         axisMaster      => axisMasters(0),
         axisSlave       => axisSlaves(0),
         -- DATA Interface (dataClk domain)
         dataClk         => dspClk,
         dataRst         => dspReset,
         dataValid       => dataValid(7 downto 0),
         data0           => amp(0),
         data1           => amp(1),
         data2           => amp(2),
         data3           => amp(3),
         data4           => adc(0),
         data5           => adc(1),
         data6           => adc(2),
         data7           => adc(3),
         extTrigIn       => sigGenTrig(0),
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => dspClk,
         axilRst         => dspReset,
         axilReadMaster  => dspReadMasters(RING_INDEX_C+0),
         axilReadSlave   => dspReadSlaves(RING_INDEX_C+0),
         axilWriteMaster => dspWriteMasters(RING_INDEX_C+0),
         axilWriteSlave  => dspWriteSlaves(RING_INDEX_C+0));

   ----------------------------------
   -- sigGenTrig(1) - Fault Buffering
   ----------------------------------
   U_RingBufferFault : entity axi_soc_ultra_plus_core.AppRingBufferEngine
      generic map (
         TPD_G              => TPD_G,
         TDEST_ROUTES_G     => (
            0               => x"08", -- Ensure no conflict with live buffer destinations
            1               => x"09",
            2               => x"0A",
            3               => x"0B",
            4               => x"FF", -- Set unused to FF
            5               => x"FF",
            6               => x"FF",
            7               => x"FF",
            8               => x"FF",
            9               => x"FF",
            10              => x"FF",
            11              => x"FF",
            12              => x"FF",
            13              => x"FF",
            14              => x"FF",
            15              => x"FF"),
         NUM_CH_G           => 4, -- 4 ADC channels
         SAMPLE_PER_CYCLE_G => 16, -- each clock 16 samples received from ADC
         RAM_ADDR_WIDTH_G   => 9, -- Determines buffer size
         MEMORY_TYPE_G      => "block",
         COMMON_CLK_G       => true,    -- true if dataClk=axilClk
         AXIL_BASE_ADDR_G   => AXIL_CONFIG_C(RING_INDEX_C+1).baseAddr)
      port map (
         -- AXI-Stream Interface (axisClk domain)
         axisClk         => dmaClk,
         axisRst         => dmaRst,
         axisMaster      => axisMasters(1),
         axisSlave       => axisSlaves(1),
         -- DATA Interface (dataClk domain)
         dataClk         => dspClk,
         dataRst         => dspReset,
         dataValid       => dataValid(3 downto 0), -- Match NUM_CH_G
         data0           => adc(0),
         data1           => adc(1),
         data2           => adc(2),
         data3           => adc(3),
         extTrigIn       => sigGenTrig(1),
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => dspClk,
         axilRst         => dspReset,
         axilReadMaster  => dspReadMasters(RING_INDEX_C+1),
         axilReadSlave   => dspReadSlaves(RING_INDEX_C+1),
         axilWriteMaster => dspWriteMasters(RING_INDEX_C+1),
         axilWriteSlave  => dspWriteSlaves(RING_INDEX_C+1));

   U_Mux : entity surf.AxiStreamMux
      generic map (
         TPD_G         => TPD_G,
         NUM_SLAVES_G  => 2,
         MODE_G        => "PASSTHROUGH",
         PIPE_STAGES_G => 1)
      port map (
         -- Clock and reset
         axisClk      => dmaClk,
         axisRst      => dmaRst,
         -- Slaves
         sAxisMasters => axisMasters,
         sAxisSlaves  => axisSlaves,
         -- Master
         mAxisMaster  => dmaIbMaster,
         mAxisSlave   => dmaIbSlave);

end mapping;
