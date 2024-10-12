-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: AbortIssueWrapper Module
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
use surf.AxiLitePkg.all;

entity AbortIssueWrapper is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- DSP Interface
      dspClk          : in  sl;
      dspRst          : in  sl;
      ampPeakIn       : in  Slv32Array(3 downto 0);
      abort_trigger   : out slv(31 downto 0);
      MA_UV           : out slv(31 downto 0);
      MA_DV           : out slv(31 downto 0);
      Pos_UV          : out slv(31 downto 0);
      Pos_DV          : out slv(31 downto 0);
      Std_UV          : out slv(31 downto 0);
      Std_DV          : out slv(31 downto 0);
      -- AXI-Lite Interface
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType);
end AbortIssueWrapper;

architecture mapping of AbortIssueWrapper is

   component abort_issue_0
      port (
         dv_delta_1                : in  std_logic_vector(15 downto 0);
         dv_delta_2                : in  std_logic_vector(15 downto 0);
         dv_sum_1                  : in  std_logic_vector(15 downto 0);
         dv_sum_2                  : in  std_logic_vector(15 downto 0);
         uv_delta_1                : in  std_logic_vector(15 downto 0);
         uv_delta_2                : in  std_logic_vector(15 downto 0);
         uv_sum_1                  : in  std_logic_vector(15 downto 0);
         uv_sum_2                  : in  std_logic_vector(15 downto 0);
         clk                       : in  std_logic;
         abort_issue_aresetn       : in  std_logic;
         abort_issue_s_axi_awaddr  : in  std_logic_vector(11 downto 0);
         abort_issue_s_axi_awvalid : in  std_logic;
         abort_issue_s_axi_wdata   : in  std_logic_vector(31 downto 0);
         abort_issue_s_axi_wstrb   : in  std_logic_vector(3 downto 0);
         abort_issue_s_axi_wvalid  : in  std_logic;
         abort_issue_s_axi_bready  : in  std_logic;
         abort_issue_s_axi_araddr  : in  std_logic_vector(11 downto 0);
         abort_issue_s_axi_arvalid : in  std_logic;
         abort_issue_s_axi_rready  : in  std_logic;
         abort_trigger             : out std_logic_vector(0 downto 0);
         uv_maout                  : out std_logic_vector(31 downto 0);
         dv_maout                  : out std_logic_vector(31 downto 0);
         uv_posout                 : out std_logic_vector(31 downto 0);
         dv_posout                 : out std_logic_vector(31 downto 0);
         uv_stdout                 : out std_logic_vector(31 downto 0);
         dv_stdout                 : out std_logic_vector(31 downto 0);
         uv_validout               : out std_logic_vector(0 downto 0);
         dv_validout               : out std_logic_vector(0 downto 0);
         injection_veto            : out std_logic_vector(0 downto 0);
         abort_issue_s_axi_awready : out std_logic;
         abort_issue_s_axi_wready  : out std_logic;
         abort_issue_s_axi_bresp   : out std_logic_vector(1 downto 0);
         abort_issue_s_axi_bvalid  : out std_logic;
         abort_issue_s_axi_arready : out std_logic;
         abort_issue_s_axi_rdata   : out std_logic_vector(31 downto 0);
         abort_issue_s_axi_rresp   : out std_logic_vector(1 downto 0);
         abort_issue_s_axi_rvalid  : out std_logic
         );
   end component;

   signal dspRstL  : sl;
   signal dspReset : sl;

begin

   U_dspRstL : entity surf.RstPipeline
      generic map(
         TPD_G     => TPD_G,
         INV_RST_G => true)             -- Invert RESET
      port map(
         clk    => dspClk,
         rstIn  => dspRst,
         rstOut => dspRstL);

   U_dspReset : entity surf.RstPipeline
      generic map(
         TPD_G     => TPD_G,
         INV_RST_G => false)
      port map(
         clk    => dspClk,
         rstIn  => dspRst,
         rstOut => dspReset);

   U_abort_issue : abort_issue_0
      port map (
         -- Clock
         clk                   => dspClk,
         -- Amplitude Peak Inbound Interface
         dv_delta_1                => ampPeakIn(1)(31 downto 16),
         dv_delta_2                => ampPeakIn(1)(15 downto 0),
         dv_sum_1                  => ampPeakIn(0)(31 downto 16),
         dv_sum_2                  => ampPeakIn(0)(15 downto 0),
         uv_delta_1                => ampPeakIn(3)(31 downto 16),
         uv_delta_2                => ampPeakIn(3)(15 downto 0),
         uv_sum_1                  => ampPeakIn(2)(31 downto 16),
         uv_sum_2                  => ampPeakIn(2)(15 downto 0),
         -- Calculation Outbound Interface
         abort_trigger(0)          => abort_trigger(30),--This is 2 in float32
         uv_maout                  => MA_UV,
         dv_maout                  => MA_DV,
         uv_posout                 => Pos_UV,
         dv_posout                 => Pos_DV,
         uv_stdout                 => Std_UV,
         dv_stdout                 => Std_DV,
         uv_validout(0)            => abort_trigger(0),
         dv_validout(0)            => abort_trigger(1),
         injection_veto(0)         => abort_trigger(2),
         -- AXI-Lite interface
         abort_issue_aresetn       => dspRstL,
         abort_issue_s_axi_awaddr  => axilWriteMaster.awaddr(11 downto 0),
         abort_issue_s_axi_awvalid => axilWriteMaster.awvalid,
         abort_issue_s_axi_awready => axilWriteSlave.awready,
         abort_issue_s_axi_wdata   => axilWriteMaster.wdata,
         abort_issue_s_axi_wstrb   => axilWriteMaster.wstrb,
         abort_issue_s_axi_wvalid  => axilWriteMaster.wvalid,
         abort_issue_s_axi_wready  => axilWriteSlave.wready,
         abort_issue_s_axi_bresp   => axilWriteSlave.bresp,
         abort_issue_s_axi_bvalid  => axilWriteSlave.bvalid,
         abort_issue_s_axi_bready  => axilWriteMaster.bready,
         abort_issue_s_axi_araddr  => axilReadMaster.araddr(11 downto 0),
         abort_issue_s_axi_arvalid => axilReadMaster.arvalid,
         abort_issue_s_axi_arready => axilReadSlave.arready,
         abort_issue_s_axi_rdata   => axilReadSlave.rdata,
         abort_issue_s_axi_rresp   => axilReadSlave.rresp,
         abort_issue_s_axi_rvalid  => axilReadSlave.rvalid,
         abort_issue_s_axi_rready  => axilReadMaster.rready);

end mapping;
