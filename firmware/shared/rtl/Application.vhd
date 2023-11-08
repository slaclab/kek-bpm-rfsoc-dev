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
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaIbMaster     : out AxiStreamMasterType;
      dmaIbSlave      : in  AxiStreamSlaveType;
      -- ADC Interface (dspClk domain)
      dspClk          : in  sl;
      dspRst          : in  sl;
      dspAdc          : in  Slv256Array(NUM_ADC_CH_C-1 downto 0);
      -- DAC Interface (dacClk domain)
      dacClk          : in  sl;
      dacRst          : in  sl;
      dspRunCntrl     : out sl;
      dspDacI         : out Slv64Array(NUM_DAC_CH_C-1 downto 0);
      dspDacQ         : out Slv64Array(NUM_DAC_CH_C-1 downto 0);
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType);
end Application;

architecture mapping of Application is

   constant SW_TRIG_INDEX_C    : natural := 0;
   constant DAC_SIG_INDEX_C    : natural := 1;
   constant RING_INDEX_C       : natural := 2;  -- 2:3
   constant NUM_AXIL_MASTERS_C : natural := 4;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 28, 24);

   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal buffReadMasters  : AxiLiteReadMasterArray(1 downto 0);
   signal buffReadSlaves   : AxiLiteReadSlaveArray(1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal buffWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal buffWriteSlaves  : AxiLiteWriteSlaveArray(1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal adc : Slv256Array(NUM_ADC_CH_C-1 downto 0) := (others => (others => '0'));
   signal amp : Slv256Array(NUM_ADC_CH_C-1 downto 0) := (others => (others => '0'));

   signal dacI : Slv64Array(NUM_DAC_CH_C-1 downto 0) := (others => (others => '0'));
   signal dacQ : Slv64Array(NUM_DAC_CH_C-1 downto 0) := (others => (others => '0'));

   signal sigGenTrig : slv(1 downto 0);
   signal ncoConfig  : slv(31 downto 0);

   signal axisMasters : AxiStreamMasterArray(1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal axisSlaves  : AxiStreamSlaveArray(1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   -- attribute dont_touch               : string;
   -- attribute dont_touch of sigGenTrig : signal is "TRUE";
   -- attribute dont_touch of adc        : signal is "TRUE";
   -- attribute dont_touch of amp        : signal is "TRUE";

begin

   process(dspClk)
   begin
      -- Help with making timing
      if rising_edge(dspClk) then
         adc <= dspAdc after TPD_G;
      end if;
   end process;

   process(dacClk)
   begin
      -- Help with making timing
      if rising_edge(dacClk) then
         dspDacI <= dacI after TPD_G;
         dspDacQ <= dacQ after TPD_G;
      end if;
   end process;

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

   U_DacSigGen : entity axi_soc_ultra_plus_core.SigGen
      generic map (
         TPD_G              => TPD_G,
         NUM_CH_G           => (2*NUM_DAC_CH_C),  -- I/Q pairs
         RAM_ADDR_WIDTH_G   => 9,
         SAMPLE_PER_CYCLE_G => 4,
         AXIL_BASE_ADDR_G   => AXIL_CONFIG_C(DAC_SIG_INDEX_C).baseAddr)
      port map (
         -- DAC Interface (dspClk domain)
         dspClk          => dacClk,
         dspRst          => dacRst,
         dspDacOut0      => dacI(0),
         dspDacOut1      => dacQ(0),
         dspDacOut2      => dacI(1),
         dspDacOut3      => dacQ(1),
         sigGenActive    => dspRunCntrl,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(DAC_SIG_INDEX_C),
         axilReadSlave   => axilReadSlaves(DAC_SIG_INDEX_C),
         axilWriteMaster => axilWriteMasters(DAC_SIG_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(DAC_SIG_INDEX_C));

   U_SsrDdc : entity work.SsrDdcWrapper
      generic map (
         TPD_G => TPD_G)
      port map (
         dspClk    => dspClk,
         dspRst    => dspRst,
         ncoConfig => ncoConfig,
         adcIn     => adc,
         ampOut    => amp);

   U_ReadoutCtrl : entity work.ReadoutCtrl
      generic map (
         TPD_G => TPD_G)
      port map (
         -- DSP Interface (dspClk domain)
         dspClk          => dspClk,
         dspRst          => dspRst,
         sigGenTrig      => sigGenTrig,
         ncoConfig       => ncoConfig,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(SW_TRIG_INDEX_C),
         axilReadSlave   => axilReadSlaves(SW_TRIG_INDEX_C),
         axilWriteMaster => axilWriteMasters(SW_TRIG_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(SW_TRIG_INDEX_C));

   ------------------------------
   -- BUFFER[0] - Live Display
   -- BUFFER[1] - Fault Buffering
   ------------------------------
   GEN_BUFFER :
   for i in 1 downto 0 generate

      U_AxiLiteAsync : entity surf.AxiLiteAsync
         generic map (
            TPD_G           => TPD_G,
            COMMON_CLK_G    => false,
            NUM_ADDR_BITS_G => 32)
         port map (
            -- Slave Interface
            sAxiClk         => axilClk,
            sAxiClkRst      => axilRst,
            sAxiReadMaster  => axilReadMasters(RING_INDEX_C+i),
            sAxiReadSlave   => axilReadSlaves(RING_INDEX_C+i),
            sAxiWriteMaster => axilWriteMasters(RING_INDEX_C+i),
            sAxiWriteSlave  => axilWriteSlaves(RING_INDEX_C+i),
            -- Master Interface
            mAxiClk         => dspClk,
            mAxiClkRst      => dspRst,
            mAxiReadMaster  => buffReadMasters(i),
            mAxiReadSlave   => buffReadSlaves(i),
            mAxiWriteMaster => buffWriteMasters(i),
            mAxiWriteSlave  => buffWriteSlaves(i));

      U_RingBuffer : entity axi_soc_ultra_plus_core.AppRingBufferEngine
         generic map (
            TPD_G              => TPD_G,
            TDEST_ROUTES_G     => (
               0               => toSlv(8*i+0, 8),
               1               => toSlv(8*i+1, 8),
               2               => toSlv(8*i+2, 8),
               3               => toSlv(8*i+3, 8),
               4               => toSlv(8*i+4, 8),
               5               => toSlv(8*i+5, 8),
               6               => toSlv(8*i+6, 8),
               7               => toSlv(8*i+7, 8),
               8               => x"FF",
               9               => x"FF",
               10              => x"FF",
               11              => x"FF",
               12              => x"FF",
               13              => x"FF",
               14              => x"FF",
               15              => x"FF"),
            NUM_CH_G           => ite(i = 0, 8, 4),
            SAMPLE_PER_CYCLE_G => 16,
            RAM_ADDR_WIDTH_G   => ite(i = 0, 9, 12),
            MEMORY_TYPE_G      => ite(i = 0, "block", "ultra"),
            COMMON_CLK_G       => true,  -- true if dataClk=axilClk
            FIFO_MEMORY_TYPE_G => "block",
            FIFO_ADDR_WIDTH_G  => 9,
            -- FIFO_MEMORY_TYPE_G  => "distributed",
            -- FIFO_ADDR_WIDTH_G   => 5,
            AXIL_BASE_ADDR_G   => AXIL_CONFIG_C(RING_INDEX_C+i).baseAddr)
         port map (
            -- AXI-Stream Interface (axisClk domain)
            axisClk         => dmaClk,
            axisRst         => dmaRst,
            axisMaster      => axisMasters(i),
            axisSlave       => axisSlaves(i),
            -- DATA Interface (dataClk domain)
            dataClk         => dspClk,
            dataRst         => dspRst,
            data0           => amp(0),
            data1           => amp(1),
            data2           => amp(2),
            data3           => amp(3),
            data4           => adc(0),
            data5           => adc(1),
            data6           => adc(2),
            data7           => adc(3),
            extTrigIn       => sigGenTrig(i),
            -- AXI-Lite Interface (axilClk domain)
            axilClk         => dspClk,
            axilRst         => dspRst,
            axilReadMaster  => buffReadMasters(i),
            axilReadSlave   => buffReadSlaves(i),
            axilWriteMaster => buffWriteMasters(i),
            axilWriteSlave  => buffWriteSlaves(i));

   end generate GEN_BUFFER;

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
