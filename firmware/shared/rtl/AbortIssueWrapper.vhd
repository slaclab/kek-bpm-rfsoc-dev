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
      ampPeakIn       : in  Slv16Array(3 downto 0);
      xPos            : out slv(31 downto 0);
      yPos            : out slv(31 downto 0);
      charge          : out slv(31 downto 0);
      -- AXI-Lite Interface
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType);
end AbortIssueWrapper;

architecture mapping of AbortIssueWrapper is

   component abort_issue_0
      port (
         ain                   : in  std_logic_vector(15 downto 0);
         bin                   : in  std_logic_vector(15 downto 0);
         cin                   : in  std_logic_vector(15 downto 0);
         din                   : in  std_logic_vector(15 downto 0);
         clk                   : in  std_logic;
         poscalc_aresetn       : in  std_logic;
         poscalc_s_axi_awaddr  : in  std_logic_vector(11 downto 0);
         poscalc_s_axi_awvalid : in  std_logic;
         poscalc_s_axi_wdata   : in  std_logic_vector(31 downto 0);
         poscalc_s_axi_wstrb   : in  std_logic_vector(3 downto 0);
         poscalc_s_axi_wvalid  : in  std_logic;
         poscalc_s_axi_bready  : in  std_logic;
         poscalc_s_axi_araddr  : in  std_logic_vector(11 downto 0);
         poscalc_s_axi_arvalid : in  std_logic;
         poscalc_s_axi_rready  : in  std_logic;
         chargeout             : out std_logic_vector(31 downto 0);
         xposout               : out std_logic_vector(31 downto 0);
         yposout               : out std_logic_vector(31 downto 0);
         poscalc_s_axi_awready : out std_logic;
         poscalc_s_axi_wready  : out std_logic;
         poscalc_s_axi_bresp   : out std_logic_vector(1 downto 0);
         poscalc_s_axi_bvalid  : out std_logic;
         poscalc_s_axi_arready : out std_logic;
         poscalc_s_axi_rdata   : out std_logic_vector(31 downto 0);
         poscalc_s_axi_rresp   : out std_logic_vector(1 downto 0);
         poscalc_s_axi_rvalid  : out std_logic
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

   U_poscalc : poscalc_0
      port map (
         -- Clock
         clk                   => dspClk,
         -- Amplitude Peak Inbound Interface
         ain                   => ampPeakIn(0),
         bin                   => ampPeakIn(1),
         cin                   => ampPeakIn(2),
         din                   => ampPeakIn(3),
         -- Calculation Outbound Interface
         xposout               => xPos,
         yposout               => YPos,
         chargeout             => charge,
         -- AXI-Lite interface
         poscalc_aresetn       => dspRstL,
         poscalc_s_axi_awaddr  => axilWriteMaster.awaddr(11 downto 0),
         poscalc_s_axi_awvalid => axilWriteMaster.awvalid,
         poscalc_s_axi_awready => axilWriteSlave.awready,
         poscalc_s_axi_wdata   => axilWriteMaster.wdata,
         poscalc_s_axi_wstrb   => axilWriteMaster.wstrb,
         poscalc_s_axi_wvalid  => axilWriteMaster.wvalid,
         poscalc_s_axi_wready  => axilWriteSlave.wready,
         poscalc_s_axi_bresp   => axilWriteSlave.bresp,
         poscalc_s_axi_bvalid  => axilWriteSlave.bvalid,
         poscalc_s_axi_bready  => axilWriteMaster.bready,
         poscalc_s_axi_araddr  => axilReadMaster.araddr(11 downto 0),
         poscalc_s_axi_arvalid => axilReadMaster.arvalid,
         poscalc_s_axi_arready => axilReadSlave.arready,
         poscalc_s_axi_rdata   => axilReadSlave.rdata,
         poscalc_s_axi_rresp   => axilReadSlave.rresp,
         poscalc_s_axi_rvalid  => axilReadSlave.rvalid,
         poscalc_s_axi_rready  => axilReadMaster.rready);

end mapping;
