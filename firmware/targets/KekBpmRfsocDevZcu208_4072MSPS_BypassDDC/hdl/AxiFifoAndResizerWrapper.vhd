-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: AXI FIFO + Resizer IP Core Wrapper
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
use surf.AxiPkg.all;

entity AxiFifoAndResizerWrapper is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Slaves Interface (dspClk domain)
      dspClk         : in  sl;
      dspRst         : in  sl;
      dspWriteMaster : in  AxiWriteMasterType;
      dspWriteSlave  : out AxiWriteSlaveType;
      dspReadMaster  : in  AxiReadMasterType;
      dspReadSlave   : out AxiReadSlaveType;
      -- Master Interface (ddrClk domain)
      ddrClk         : in  sl;
      ddrRst         : in  sl;
      ddrWriteMaster : out AxiWriteMasterType;
      ddrWriteSlave  : in  AxiWriteSlaveType;
      ddrReadMaster  : out AxiReadMasterType;
      ddrReadSlave   : in  AxiReadSlaveType);
end AxiFifoAndResizerWrapper;

architecture mapping of AxiFifoAndResizerWrapper is

   component AxiFifoAndResizer
      port (
         INTERCONNECT_ACLK    : in  std_logic;
         INTERCONNECT_ARESETN : in  std_logic;
         S00_AXI_ARESET_OUT_N : out std_logic;
         S00_AXI_ACLK         : in  std_logic;
         S00_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S00_AXI_AWADDR       : in  std_logic_vector(31 downto 0);
         S00_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S00_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S00_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S00_AXI_AWLOCK       : in  std_logic;
         S00_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S00_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S00_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S00_AXI_AWVALID      : in  std_logic;
         S00_AXI_AWREADY      : out std_logic;
         S00_AXI_WDATA        : in  std_logic_vector(127 downto 0);
         S00_AXI_WSTRB        : in  std_logic_vector(15 downto 0);
         S00_AXI_WLAST        : in  std_logic;
         S00_AXI_WVALID       : in  std_logic;
         S00_AXI_WREADY       : out std_logic;
         S00_AXI_BID          : out std_logic_vector(0 downto 0);
         S00_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S00_AXI_BVALID       : out std_logic;
         S00_AXI_BREADY       : in  std_logic;
         S00_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S00_AXI_ARADDR       : in  std_logic_vector(31 downto 0);
         S00_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S00_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S00_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S00_AXI_ARLOCK       : in  std_logic;
         S00_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S00_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S00_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S00_AXI_ARVALID      : in  std_logic;
         S00_AXI_ARREADY      : out std_logic;
         S00_AXI_RID          : out std_logic_vector(0 downto 0);
         S00_AXI_RDATA        : out std_logic_vector(127 downto 0);
         S00_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S00_AXI_RLAST        : out std_logic;
         S00_AXI_RVALID       : out std_logic;
         S00_AXI_RREADY       : in  std_logic;
         M00_AXI_ARESET_OUT_N : out std_logic;
         M00_AXI_ACLK         : in  std_logic;
         M00_AXI_AWID         : out std_logic_vector(3 downto 0);
         M00_AXI_AWADDR       : out std_logic_vector(31 downto 0);
         M00_AXI_AWLEN        : out std_logic_vector(7 downto 0);
         M00_AXI_AWSIZE       : out std_logic_vector(2 downto 0);
         M00_AXI_AWBURST      : out std_logic_vector(1 downto 0);
         M00_AXI_AWLOCK       : out std_logic;
         M00_AXI_AWCACHE      : out std_logic_vector(3 downto 0);
         M00_AXI_AWPROT       : out std_logic_vector(2 downto 0);
         M00_AXI_AWQOS        : out std_logic_vector(3 downto 0);
         M00_AXI_AWVALID      : out std_logic;
         M00_AXI_AWREADY      : in  std_logic;
         M00_AXI_WDATA        : out std_logic_vector(255 downto 0);
         M00_AXI_WSTRB        : out std_logic_vector(31 downto 0);
         M00_AXI_WLAST        : out std_logic;
         M00_AXI_WVALID       : out std_logic;
         M00_AXI_WREADY       : in  std_logic;
         M00_AXI_BID          : in  std_logic_vector(3 downto 0);
         M00_AXI_BRESP        : in  std_logic_vector(1 downto 0);
         M00_AXI_BVALID       : in  std_logic;
         M00_AXI_BREADY       : out std_logic;
         M00_AXI_ARID         : out std_logic_vector(3 downto 0);
         M00_AXI_ARADDR       : out std_logic_vector(31 downto 0);
         M00_AXI_ARLEN        : out std_logic_vector(7 downto 0);
         M00_AXI_ARSIZE       : out std_logic_vector(2 downto 0);
         M00_AXI_ARBURST      : out std_logic_vector(1 downto 0);
         M00_AXI_ARLOCK       : out std_logic;
         M00_AXI_ARCACHE      : out std_logic_vector(3 downto 0);
         M00_AXI_ARPROT       : out std_logic_vector(2 downto 0);
         M00_AXI_ARQOS        : out std_logic_vector(3 downto 0);
         M00_AXI_ARVALID      : out std_logic;
         M00_AXI_ARREADY      : in  std_logic;
         M00_AXI_RID          : in  std_logic_vector(3 downto 0);
         M00_AXI_RDATA        : in  std_logic_vector(255 downto 0);
         M00_AXI_RRESP        : in  std_logic_vector(1 downto 0);
         M00_AXI_RLAST        : in  std_logic;
         M00_AXI_RVALID       : in  std_logic;
         M00_AXI_RREADY       : out std_logic
         );
   end component;

   signal dspRstL : sl;

begin

   dspRstL <= not(dspRst);

   U_AxiFifoAndResizer : AxiFifoAndResizer
      port map (
         INTERCONNECT_ACLK    => dspClk,
         INTERCONNECT_ARESETN => dspRstL,
         -- SLAVE[0]
         S00_AXI_ARESET_OUT_N => open,
         S00_AXI_ACLK         => dspClk,
         S00_AXI_AWID(0)      => '0',
         S00_AXI_AWADDR       => dspWriteMaster.awaddr(31 downto 0),
         S00_AXI_AWLEN        => dspWriteMaster.awlen,
         S00_AXI_AWSIZE       => dspWriteMaster.awsize,
         S00_AXI_AWBURST      => dspWriteMaster.awburst,
         S00_AXI_AWLOCK       => dspWriteMaster.awlock(0),
         S00_AXI_AWCACHE      => dspWriteMaster.awcache,
         S00_AXI_AWPROT       => dspWriteMaster.awprot,
         S00_AXI_AWQOS        => dspWriteMaster.awqos,
         S00_AXI_AWVALID      => dspWriteMaster.awvalid,
         S00_AXI_AWREADY      => dspWriteSlave.awready,
         S00_AXI_WDATA        => dspWriteMaster.wdata(127 downto 0),
         S00_AXI_WSTRB        => dspWriteMaster.wstrb(15 downto 0),
         S00_AXI_WLAST        => dspWriteMaster.wlast,
         S00_AXI_WVALID       => dspWriteMaster.wvalid,
         S00_AXI_WREADY       => dspWriteSlave.wready,
         S00_AXI_BID          => dspWriteSlave.bid(0 downto 0),
         S00_AXI_BRESP        => dspWriteSlave.bresp,
         S00_AXI_BVALID       => dspWriteSlave.bvalid,
         S00_AXI_BREADY       => dspWriteMaster.bready,
         S00_AXI_ARID(0)      => '0',
         S00_AXI_ARADDR       => dspReadMaster.araddr(31 downto 0),
         S00_AXI_ARLEN        => dspReadMaster.arlen,
         S00_AXI_ARSIZE       => dspReadMaster.arsize,
         S00_AXI_ARBURST      => dspReadMaster.arburst,
         S00_AXI_ARLOCK       => dspReadMaster.arlock(0),
         S00_AXI_ARCACHE      => dspReadMaster.arcache,
         S00_AXI_ARPROT       => dspReadMaster.arprot,
         S00_AXI_ARQOS        => dspReadMaster.arqos,
         S00_AXI_ARVALID      => dspReadMaster.arvalid,
         S00_AXI_ARREADY      => dspReadSlave.arready,
         S00_AXI_RID          => dspReadSlave.rid(0 downto 0),
         S00_AXI_RDATA        => dspReadSlave.rdata(127 downto 0),
         S00_AXI_RRESP        => dspReadSlave.rresp,
         S00_AXI_RLAST        => dspReadSlave.rlast,
         S00_AXI_RVALID       => dspReadSlave.rvalid,
         S00_AXI_RREADY       => dspReadMaster.rready,
         -- MASTER
         M00_AXI_ARESET_OUT_N => open,
         M00_AXI_ACLK         => ddrClk,
         M00_AXI_AWID         => ddrWriteMaster.awid(3 downto 0),
         M00_AXI_AWADDR       => ddrWriteMaster.awaddr(31 downto 0),
         M00_AXI_AWLEN        => ddrWriteMaster.awlen,
         M00_AXI_AWSIZE       => ddrWriteMaster.awsize,
         M00_AXI_AWBURST      => ddrWriteMaster.awburst,
         M00_AXI_AWLOCK       => ddrWriteMaster.awlock(0),
         M00_AXI_AWCACHE      => ddrWriteMaster.awcache,
         M00_AXI_AWPROT       => ddrWriteMaster.awprot,
         M00_AXI_AWQOS        => ddrWriteMaster.awqos,
         M00_AXI_AWVALID      => ddrWriteMaster.awvalid,
         M00_AXI_AWREADY      => ddrWriteSlave.awready,
         M00_AXI_WDATA        => ddrWriteMaster.wdata(255 downto 0),
         M00_AXI_WSTRB        => ddrWriteMaster.wstrb(31 downto 0),
         M00_AXI_WLAST        => ddrWriteMaster.wlast,
         M00_AXI_WVALID       => ddrWriteMaster.wvalid,
         M00_AXI_WREADY       => ddrWriteSlave.wready,
         M00_AXI_BID          => ddrWriteSlave.bid(3 downto 0),
         M00_AXI_BRESP        => ddrWriteSlave.bresp,
         M00_AXI_BVALID       => ddrWriteSlave.bvalid,
         M00_AXI_BREADY       => ddrWriteMaster.bready,
         M00_AXI_ARID         => ddrReadMaster.arid(3 downto 0),
         M00_AXI_ARADDR       => ddrReadMaster.araddr(31 downto 0),
         M00_AXI_ARLEN        => ddrReadMaster.arlen,
         M00_AXI_ARSIZE       => ddrReadMaster.arsize,
         M00_AXI_ARBURST      => ddrReadMaster.arburst,
         M00_AXI_ARLOCK       => ddrReadMaster.arlock(0),
         M00_AXI_ARCACHE      => ddrReadMaster.arcache,
         M00_AXI_ARPROT       => ddrReadMaster.arprot,
         M00_AXI_ARQOS        => ddrReadMaster.arqos,
         M00_AXI_ARVALID      => ddrReadMaster.arvalid,
         M00_AXI_ARREADY      => ddrReadSlave.arready,
         M00_AXI_RID          => ddrReadSlave.rid(3 downto 0),
         M00_AXI_RDATA        => ddrReadSlave.rdata(255 downto 0),
         M00_AXI_RRESP        => ddrReadSlave.rresp,
         M00_AXI_RLAST        => ddrReadSlave.rlast,
         M00_AXI_RVALID       => ddrReadSlave.rvalid,
         M00_AXI_RREADY       => ddrReadMaster.rready);

end mapping;
