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
      -- PMOD Ports
      pmod            : inout Slv8Array(1 downto 0);
      -- DSP Interface
      dspClk          : in    sl;
      dspRst          : in    sl;
      sigGenTrig      : out   slv(1 downto 0);
      ncoConfig       : out   slv(31 downto 0);
      dspRunCntrl     : out   sl;
      fineDelay       : out   Slv4Array(3 downto 0);
      courseDelay     : out   Slv4Array(3 downto 0);
      selectdirect    : out   sl;
      muxSelect       : out   sl;
      -- AXI-Lite Interface
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType);
end ReadoutCtrl;

architecture rtl of ReadoutCtrl is

   type RegType is record
      -- Faults signals
      faultTrig      : sl;
      faultTrigArm   : sl;
      faultTrigReady : sl;
      faultTrigDlyEn : sl;
      faultTrigDly   : slv(14 downto 0);
      faultDlyCnt    : slv(14 downto 0);
      trigFaultBuf   : sl;
      -- PMOD signals
      pmodInPolarity : sl;
      pmodInBus      : slv(3 downto 0);
      pmodInSel      : slv(1 downto 0);
      pmodIn         : sl;
      pmodOut        : Slv6Array(1 downto 0);
      -- Run control
      dspRunCntrl    : sl;
      sigGenTrig     : slv(1 downto 0);
      ncoConfig      : slv(31 downto 0);
      fineDelay      : Slv4Array(3 downto 0);
      courseDelay    : Slv4Array(3 downto 0);
      selectdirect   : sl;
      muxSelect      : sl;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      -- Faults signals
      faultTrig      => '0',
      faultTrigArm   => '0',
      faultTrigReady => '0',
      faultTrigDlyEn => '0',
      faultTrigDly   => (others => '0'),
      faultDlyCnt    => (others => '0'),
      trigFaultBuf   => '0',
      -- PMOD signals
      pmodInPolarity => '0',
      pmodInBus      => (others => '0'),
      pmodInSel      => (others => '0'),
      pmodIn         => '0',
      pmodOut        => (others => (others => '0')),
      -- Run control
      dspRunCntrl    => '0',
      sigGenTrig     => (others => '0'),
      ncoConfig      => (others => '0'),
      fineDelay      => (others => x"0"),
      courseDelay    => COURSE_DLY_INIT_G,
      selectdirect   => '0',
      muxSelect      => '0',
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (axilReadMaster, axilWriteMaster, dspRst, pmod, r) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndPointType;
      variable pmodIn : sl;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobes
      v.sigGenTrig   := (others => '0');
      v.faultTrigArm := '0';
      v.faultTrig    := '0';
      v.trigFaultBuf := '0';

      ----------------------------------------------------------------------
      --                AXI-Lite Register Logic
      ----------------------------------------------------------------------

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -------------------------
      -- Map the read registers
      -------------------------

      axiSlaveRegister (axilEp, x"00", 0, v.sigGenTrig(0));  -- Live Display
      axiSlaveRegister (axilEp, x"04", 0, v.sigGenTrig(1));  -- Fault Buffering
      axiSlaveRegister (axilEp, x"08", 0, v.ncoConfig);  -- 32-bits, address: [0x8:0xB]

      -- Reserved: address: [0xC:0xF]
      axiSlaveRegister (axilEp, x"10", 0, v.dspRunCntrl);
      for i in 0 to 3 loop
         axiSlaveRegister (axilEp, x"14", (8*i), v.fineDelay(i));
         axiSlaveRegister (axilEp, x"18", (8*i), v.courseDelay(i));
      end loop;

      axiSlaveRegister (axilEp, x"20", 0, v.pmodOut(0));
      axiSlaveRegister (axilEp, x"20", 8, v.pmodOut(1));
      axiSlaveRegister (axilEp, x"20", 16, v.pmodInSel);
      axiSlaveRegister (axilEp, x"20", 24, v.pmodInPolarity);

      axiSlaveRegisterR(axilEp, x"24", 0, r.pmodInBus);
      axiSlaveRegisterR(axilEp, x"24", 4, r.pmodIn);
      axiSlaveRegisterR(axilEp, x"24", 5, r.faultTrigReady);

      axiSlaveRegister (axilEp, x"28", 0, v.faultTrigArm);
      axiSlaveRegister (axilEp, x"28", 1, v.selectdirect);
      axiSlaveRegister (axilEp, x"28", 2, v.muxSelect);

      axiSlaveRegister (axilEp, x"2C", 0, v.faultTrigDly);

      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      ----------------------------------------------------------------------

      -- PMOD input bus
      v.pmodInBus(0) := pmod(0)(6);
      v.pmodInBus(1) := pmod(0)(7);
      v.pmodInBus(2) := pmod(1)(6);
      v.pmodInBus(3) := pmod(1)(7);

      -- Select the PMOD Input and apply polarity correction
      v.pmodIn := r.pmodInBus(conv_integer(r.pmodInSel)) xor r.pmodInPolarity;

      -- Check for re-arming the fault trigger
      if (r.faultTrigArm = '1') then
         -- Set the flag
         v.faultTrigReady := '1';

      -- Check for hardware fault event
      elsif (r.faultTrigReady = '1') and (r.pmodIn = '1') then

         -- Clear the flag
         v.faultTrigReady := '0';

         -- Set the flag
         v.faultTrig := '1';

      end if;

      ----------------------------------------------------------------------
      -- Fault Buffering Trigger: Programmable Delay
      ----------------------------------------------------------------------

      -- Check for SW trigger or HW trigger event
      if (r.sigGenTrig(1) = '1') or (r.faultTrig = '1') then

         -- Reset the flag
         v.faultTrigDlyEn := '1';

         -- Preset the counter
         v.faultDlyCnt := r.faultTrigDly;

      end if;

      -- Check if enabled
      if (r.faultTrigDlyEn = '1') then

         -- Check for last delay step
         if (r.faultDlyCnt = 0) then

            -- Reset the flag
            v.faultTrigDlyEn := '0';

            -- Output the trigger
            v.trigFaultBuf := '1';

         else
            -- Decrement the counter
            v.faultDlyCnt := r.faultDlyCnt - 1;
         end if;

      end if;

      ----------------------------------------------------------------------

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      ncoConfig      <= r.ncoConfig;
      dspRunCntrl    <= r.dspRunCntrl;
      fineDelay      <= r.fineDelay;
      courseDelay    <= r.courseDelay;
      selectdirect   <= r.selectdirect;
      muxSelect      <= r.muxSelect;
      for i in 0 to 1 loop
         pmod(i)(5 downto 0) <= not(r.pmodOut(i));
      end loop;

      -- sigGenTrig(0) - Live Display
      sigGenTrig(0) <= r.sigGenTrig(0);

      -- sigGenTrig(1) - Fault Buffering
      sigGenTrig(1) <= r.trigFaultBuf;

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
