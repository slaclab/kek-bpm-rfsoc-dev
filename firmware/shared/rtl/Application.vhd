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
      -- ADC/DAC Interface (dspClk domain)
      dspClk          : in  sl;
      dspRst          : in  sl;
      dspAdcI         : in  Slv32Array(NUM_ADC_CH_C-1 downto 0);
      dspAdcQ         : in  Slv32Array(NUM_ADC_CH_C-1 downto 0);
      dspDacI         : out Slv32Array(NUM_DAC_CH_C-1 downto 0);
      dspDacQ         : out Slv32Array(NUM_DAC_CH_C-1 downto 0);
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType);
end Application;

architecture mapping of Application is

   constant RAM_ADDR_WIDTH_C : positive := 9;

   constant RING_INDEX_C       : natural := 0;
   constant DAC_SIG_INDEX_C    : natural := 1;
   constant SW_TRIG_INDEX_C    : natural := 2;
   constant NUM_AXIL_MASTERS_C : natural := 3;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 28, 24);

   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal adcI : Slv32Array(NUM_ADC_CH_C-1 downto 0) := (others => (others => '0'));
   signal adcQ : Slv32Array(NUM_ADC_CH_C-1 downto 0) := (others => (others => '0'));
   signal dacI : Slv32Array(NUM_DAC_CH_C-1 downto 0) := (others => (others => '0'));
   signal dacQ : Slv32Array(NUM_DAC_CH_C-1 downto 0) := (others => (others => '0'));

   signal sigGenTrig : sl;

   attribute dont_touch               : string;
   attribute dont_touch of sigGenTrig : signal is "TRUE";
   attribute dont_touch of adcI       : signal is "TRUE";
   attribute dont_touch of adcQ       : signal is "TRUE";
   attribute dont_touch of dacI       : signal is "TRUE";
   attribute dont_touch of dacQ       : signal is "TRUE";

begin

   process(dspClk)
   begin
      -- Help with making timing
      if rising_edge(dspClk) then
         adcI    <= dspAdcI after TPD_G;
         adcQ    <= dspAdcQ after TPD_G;
         dspDacI <= dacI    after TPD_G;
         dspDacQ <= dacQ    after TPD_G;
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

   U_AxiStreamRingBuffer : entity surf.AxiStreamRingBuffer
      generic map (
         TPD_G               => TPD_G,
         SYNTH_MODE_G        => "xpm",
         DATA_BYTES_G        => 16,
         RAM_ADDR_WIDTH_G    => RAM_ADDR_WIDTH_C,
         -- AXI Stream Configurations
         AXI_STREAM_CONFIG_G => DMA_AXIS_CONFIG_C)
      port map (
         -- Data to store in ring buffer (dataClk domain)
         dataClk => dspClk,
         extTrig => sigGenTrig,

         -- Organize data for simpler software processing
         dataValue(15 downto 0)    => adcI(0)(15 downto 0), -- 1st I sample
         dataValue(31 downto 16)   => adcQ(0)(15 downto 0), -- 1st Q sample
         dataValue(47 downto 32)   => dacI(0)(15 downto 0), -- 1st I sample
         dataValue(63 downto 48)   => dacQ(0)(15 downto 0), -- 1st Q sample
         dataValue(79 downto 64)   => adcI(0)(31 downto 16), -- 2nd I sample
         dataValue(95 downto 80)   => adcQ(0)(31 downto 16), -- 2nd Q sample
         dataValue(111 downto 96)  => dacI(0)(31 downto 16), -- 2nd I sample
         dataValue(127 downto 112) => dacQ(0)(31 downto 16), -- 2nd Q sample

         -- AXI-Lite interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(RING_INDEX_C),
         axilReadSlave   => axilReadSlaves(RING_INDEX_C),
         axilWriteMaster => axilWriteMasters(RING_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(RING_INDEX_C),
         -- AXI-Stream Interface (axisClk domain)
         axisClk         => dmaClk,
         axisRst         => dmaRst,
         axisMaster      => dmaIbMaster,
         axisSlave       => dmaIbSlave);

   U_DacSigGen : entity axi_soc_ultra_plus_core.SigGen
      generic map (
         TPD_G              => TPD_G,
         NUM_CH_G           => (2*NUM_DAC_CH_C), -- I/Q pairs
         RAM_ADDR_WIDTH_G   => RAM_ADDR_WIDTH_C,
         SAMPLE_PER_CYCLE_G => SAMPLE_PER_CYCLE_C,
         AXIL_BASE_ADDR_G   => AXIL_CONFIG_C(DAC_SIG_INDEX_C).baseAddr)
      port map (
         -- DAC Interface (dspClk domain)
         dspClk          => dspClk,
         dspRst          => dspRst,
         dspDacOut0      => dacI(0),
         dspDacOut1      => dacQ(0),
         extTrigIn       => sigGenTrig,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(DAC_SIG_INDEX_C),
         axilReadSlave   => axilReadSlaves(DAC_SIG_INDEX_C),
         axilWriteMaster => axilWriteMasters(DAC_SIG_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(DAC_SIG_INDEX_C));

   U_SwDacTrig : entity work.SwDacTrig
      generic map (
         TPD_G => TPD_G)
      port map (
         -- DSP Interface (dspClk domain)
         dspClk          => dspClk,
         dspRst          => dspRst,
         sigGenTrig      => sigGenTrig,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(SW_TRIG_INDEX_C),
         axilReadSlave   => axilReadSlaves(SW_TRIG_INDEX_C),
         axilWriteMaster => axilWriteMasters(SW_TRIG_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(SW_TRIG_INDEX_C));

end mapping;
