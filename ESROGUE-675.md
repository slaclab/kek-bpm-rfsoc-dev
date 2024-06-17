# Notes for ESROGUE-675 development

<!--- ######################################################## -->

# Clone the GIT repository

Clone the git repo with git-lfs enabled

```bash
git clone --recursive https://github.com/slaclab/kek-bpm-rfsoc-dev.git -b ESROGUE-675
```

<!--- ######################################################## -->

# How to generate the RFSoC .BIT and .XSA files

1) Setup Xilinx PATH and licensing

```bash
source kek-bpm-rfsoc-dev/firmware/SLAC_setup.sh
```

2) Go to the target directory and make the firmware:

```bash
cd kek-bpm-rfsoc-dev/firmware/targets/KekBpmRfsocDevZcu111_4072MSPS_BypassDDC/
make
```

3) Optional: Review the results in GUI mode

```bash
make gui
```

The .bit and .XSA files are dumped into the KekBpmRfsocDevZcu111_4072MSPS_BypassDDC/image directory:

```bash
ls -lath KekBpmRfsocDevZcu111_4072MSPS_BypassDDC/images/
total 47M
drwxr-xr-x 5 ruckman re 2.0K Feb  7 07:13 ..
drwxr-xr-x 2 ruckman re 2.0K Feb  4 21:15 .
-rw-r--r-- 1 ruckman re  14M Feb  4 21:15 KekBpmRfsocDevZcu111_4072MSPS_BypassDDC-0x09000000-20240617204648-ruckman-90df89c.xsa
-rw-r--r-- 1 ruckman re  33M Feb  4 21:14 KekBpmRfsocDevZcu111_4072MSPS_BypassDDC-0x09000000-20240617204648-ruckman-90df89c.bit
```

<!--- ######################################################## -->

# How to build Petalinux images

1) Generate the .bit and .xsa files (refer to `How to generate the RFSoC .BIT and .XSA files` instructions).

2) Setup Xilinx licensing and petalinux software (if on SLAC AFS network) else requires Xilinx & petalinux install on your local machine

```bash
source kek-bpm-rfsoc-dev/firmware/SLAC_setup.sh
source /u1/petalinux/2023.2/settings.sh
```

3) Go to the target directory and run the `CreatePetalinuxProject.sh` script with arg pointing to path of .XSA file:

```bash
cd kek-bpm-rfsoc-dev/firmware/targets/KekBpmRfsocDevZcu111_4072MSPS_BypassDDC/
source CreatePetalinuxProject.sh images/KekBpmRfsocDevZcu111_4072MSPS_BypassDDC-0x09000000-20240617204648-ruckman-90df89c.xsa
```

<!--- ######################################################## -->

# How to remote update the firmware bitstream

- Assumes the DHCP assigned IP address is 10.0.0.10

1) Using "scp" to copy your .bit file to the SD memory card on the RFSoC.  Here's an example:

```bash
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "10.0.0.10" # https://jira.slac.stanford.edu/browse/ESRFOC-54
scp KekBpmRfsocDevZcu111_4072MSPS_BypassDDC-0x09000000-20240617204648-ruckman-90df89c.bit root@10.0.0.10:/boot/system.bit
```

2) Send a "sync" and "reboot" command to the RFSoC to load new firmware:  Here's an example:

```bash
ssh root@10.0.0.10 '/bin/sync; /sbin/reboot'
```

<!--- ######################################################## -->

# How to run the Rogue GUI

- Assumes the DHCP assigned IP address is 10.0.0.10 and ZCU111 board type

1) Setup the rogue environment

```bash
source kek-bpm-rfsoc-dev/software/setup_env_slac.sh
```

2) Go to software directory and lauch the GUI:

```bash
cd kek-bpm-rfsoc-dev/software
python scripts/devGui.py --ip 10.0.0.10 --boardType zcu111
```

<!--- ######################################################## -->
