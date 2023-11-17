-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Readout Control Module
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library work;
use work.AppPkg.all;

entity ReadoutCtrl is
   generic (
      TPD_G             : time := 1 ns;
      COURSE_DLY_INIT_G : Slv4Array(3 downto 0));
   port (
      -- DSP Interface
      dspClk          : in  sl;
      dspRst          : in  sl;
      sigGenTrig      : out slv(1 downto 0);
      ncoConfig       : out slv(31 downto 0);
      dspRunCntrl     : out sl;
      fineDelay       : out Slv4Array(3 downto 0);
      courseDelay     : out Slv4Array(3 downto 0);
      -- AXI-Lite Interface
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end ReadoutCtrl;

architecture rtl of ReadoutCtrl is

   type RegType is record
      dspRunCntrl    : sl;
      sigGenTrig     : slv(1 downto 0);
      ncoConfig      : slv(31 downto 0);
      fineDelay      : Slv4Array(3 downto 0);
      courseDelay    : Slv4Array(3 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      dspRunCntrl    => '0',
      sigGenTrig     => (others => '0'),
      ncoConfig      => (others => '0'),
      fineDelay      => (others => x"0"),
      courseDelay    => COURSE_DLY_INIT_G,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (axilReadMaster, axilWriteMaster, dspRst, r) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobes
      v.sigGenTrig := (others => '0');

      ----------------------------------------------------------------------
      --                AXI-Lite Register Logic
      ----------------------------------------------------------------------

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      axiSlaveRegister (axilEp, x"00", 0, v.sigGenTrig(0));  -- Live Display
      axiSlaveRegister (axilEp, x"04", 0, v.sigGenTrig(1));  -- Fault Buffering
      axiSlaveRegister (axilEp, x"08", 0, v.ncoConfig);  -- 32-bits, address: [0x8:0xB]
      -- Reserved: address: [0xC:0xF]
      axiSlaveRegister (axilEp, x"10", 0, v.dspRunCntrl);
      for i in 0 to 3 loop
         axiSlaveRegister (axilEp, x"14", (8*i), v.fineDelay(i));
         axiSlaveRegister (axilEp, x"18", (8*i), v.courseDelay(i));
      end loop;

      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      ----------------------------------------------------------------------

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      sigGenTrig     <= r.sigGenTrig;
      ncoConfig      <= r.ncoConfig;
      dspRunCntrl    <= r.dspRunCntrl;
      fineDelay      <= r.fineDelay;
      courseDelay    <= r.courseDelay;

      -- Reset
      if (dspRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (dspClk) is
   begin
      if rising_edge(dspClk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
