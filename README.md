# kek-bpm-rfsoc-dev

<!--- ######################################################## -->

# Clone the GIT repository

```bash
$ git clone --recursive https://github.com/slaclab/kek-bpm-rfsoc-dev.git
```

Note: `recursive flag` used to initialize all submodules within the clone

<!--- ######################################################## -->

# ZCU111 and External Clock reference

A 509 MHz reference clock connected to ZCU111's "J109" connect is required.
Tested using a 509 MHz sine wave generator.  
Sine wave amplitude needed to be between 10 mV and 500 mV to get a LMK/LMX lock.

<img src="docs/images/CLK_REF.png" width="200">

<!--- ######################################################## -->

# RF Balun Daughter card

Assumes you are using the Xilinx XM500 daughter card.
Only RFMC_ADC_03_P/N and RFMC_DAC_05_P/N are implemented in firmware,
which is a "1-4GHz Channels Anaren Balun [HF]" balun path.
A loopback SMA cable between XM500.J1 and XM500.J8 is required.

<img src="docs/images/LOOPBACK.png" width="200">

<!--- ######################################################## -->

# How to generate the RFSoC .BIT and .XSA files

1) Setup Xilinx PATH and licensing (if on SLAC AFS network) else requires Vivado install and licensing on your local machine

```bash
$ source kek-bpm-rfsoc-dev/firmware/vivado_setup.sh
```

2) Go to the target directory and make the firmware:

```bash
$ cd kek-bpm-rfsoc-dev/firmware/targets/KekBpmRfsocDevZcu111/
$ make
```

3) Optional: Review the results in GUI mode

```bash
$ make gui
```

The .bit and .XSA files are dumped into the KekBpmRfsocDevZcu111/image directory:

```bash
$ ls -lath KekBpmRfsocDevZcu111/images/
total 47M
drwxr-xr-x 5 ruckman re 2.0K Feb  7 07:13 ..
drwxr-xr-x 2 ruckman re 2.0K Feb  4 21:15 .
-rw-r--r-- 1 ruckman re  14M Feb  4 21:15 KekBpmRfsocDevZcu111-0x01000000-20220204204648-ruckman-90df89c.xsa
-rw-r--r-- 1 ruckman re  33M Feb  4 21:14 KekBpmRfsocDevZcu111-0x01000000-20220204204648-ruckman-90df89c.bit
```

<!--- ######################################################## -->

# How to build Petalinux images

1) Generate the .bit and .xsa files (refer to `How to generate the RFSoC .BIT and .XSA files` instructions).

2) Setup Xilinx licensing and petalinux software (if on SLAC AFS network) else requires Xilinx & petalinux install on your local machine

```bash
# These setup scripts assume that you are on SLAC network
$ source kek-bpm-rfsoc-dev/firmware/vivado_setup.sh
$ source /path/to/petalinux/2022.2/settings.sh
```

3) Go to the target directory and run the `CreatePetalinuxProject.sh` script with arg pointing to path of .XSA file:

```bash
$ cd kek-bpm-rfsoc-dev/firmware/targets/KekBpmRfsocDevZcu111/
$ source CreatePetalinuxProject.sh images/KekBpmRfsocDevZcu111-0x01000000-20220204204648-ruckman-90df89c.xsa
```

<!--- ######################################################## -->

# How to make the SD memory card for the first time

1) Creating Two Partitions.  Refer to URL below

https://xilinx-wiki.atlassian.net/wiki/x/EYMfAQ

2) Copy For the boot images, simply copy the files to the FAT partition.
This typically will include system.bit, BOOT.BIN, image.ub, and boot.scr.  Here's an example:

Note: Assumes SD memory FAT32 is `/dev/sde1` in instructions below

```bash
sudo mkdir -p boot
sudo mount /dev/sde1 boot
sudo cp kek-bpm-rfsoc-dev/firmware/build/petalinux/KekBpmRfsocDevZcu111/images/linux/system.bit boot/.
sudo cp kek-bpm-rfsoc-dev/firmware/build/petalinux/KekBpmRfsocDevZcu111/images/linux/BOOT.BIN   boot/.
sudo cp kek-bpm-rfsoc-dev/firmware/build/petalinux/KekBpmRfsocDevZcu111/images/linux/image.ub   boot/.
sudo cp kek-bpm-rfsoc-dev/firmware/build/petalinux/KekBpmRfsocDevZcu111/images/linux/boot.scr   boot/.
sudo sync boot/
sudo umount boot
```

3) Power down the RFSoC board

4) Confirm the Mode SW6 [4:1] = 1110 (Mode Pins [3:0]). Note: Switch OFF = 1 = High; ON = 0 = Low.

5) Power up the RFSoC board

6) Confirm that you can ping the boot after it boots up

<!--- ######################################################## -->

# How to remote update the firmware bitstream

- Assumes the DHCP assigned IP address is 10.0.0.10

1) Using "scp" to copy your .bit file to the SD memory card on the RFSoC.  Here's an example:

```bash
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "10.0.0.10" # https://jira.slac.stanford.edu/browse/ESRFOC-54
scp KekBpmRfsocDevZcu111-0x01000000-20220204204648-ruckman-90df89c.bit root@10.0.0.10:/boot/system.bit
```

2) Send a "sync" and "reboot" command to the RFSoC to load new firmware:  Here's an example:

```bash
ssh root@10.0.0.10 '/bin/sync; /sbin/reboot'
```

<!--- ######################################################## -->

# How to install the Rogue With Anaconda

> https://slaclab.github.io/rogue/installing/anaconda.html

<!--- ######################################################## -->

# How to run the Rogue GUI

- Assumes the DHCP assigned IP address is 10.0.0.10

1) Setup the rogue environment (if on SLAC AFS network) else install rogue (recommend Anaconda method) on your local machine

```bash
$ source kek-bpm-rfsoc-dev/software/setup_env_slac.sh
```

2) Go to software directory and lauch the GUI:

```bash
$ cd kek-bpm-rfsoc-dev/software
$ python scripts/devGui.py --ip 10.0.0.10
```

<!--- ######################################################## -->
