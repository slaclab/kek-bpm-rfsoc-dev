# kek-bpm-rfsoc-dev

<!--- ######################################################## -->

# Required licenses

- Vivado Licnese (v2023.1)
  - Either floating (EF-VIVADO-ENTER-FL) or node locked (EF-VIVADO-ENTER-NL)
- Model Composer Licnese (add on to Vivado)
  - Either floating (EF-MATSIM-ADDON-FL) or node locked (EF-MATSIM-ADDON-NL)
- Matlab License (R2021a)
- Petalinux (v2022.2)

<!--- ######################################################## -->

# Clone the GIT repository

Install git large filesystems (git-lfs) in your .gitconfig (1-time step per unix environment)
```bash
$ git lfs install
```
Clone the git repo with git-lfs enabled
```bash
$ git clone --recursive https://github.com/slaclab/kek-bpm-rfsoc-dev.git
```

Note: `recursive flag` used to initialize all submodules within the clone

<!--- ######################################################## -->

# ZCU111 and External Clock reference

A 509 MHz reference clock connected to ZCU111's "J109" connect is required.
Tested using a 509 MHz sine wave generator.  
Sine wave amplitude needed to be between 10 mV and 500 mV to get a LMK/LMX lock.

<img src="docs/images/ZCU111_CLK_REF.png" width="200">

<!--- ######################################################## -->

# ZCU208 and External Clock reference

A 509 MHz reference clock connected to ZCU208's J99/J100 ("DAC 229 CLK").
The 509 MHz reference must be converted from a single-end signal to a 
differential (AC-coupled) signal using a discrete balun circuit.
Use either a [TM7SSSTS5FS031C](https://www.digikey.com/en/products/detail/carlisleit/TM7SSSTS5FS031C/12420541)
or a [TM7SMSTS5MS031C](https://www.digikey.com/en/products/detail/carlisleit/TM7SMSTS5MS031C/12419925) for 
the coaxial SMA to SSMP adapter. 

<img src="docs/images/ZCU208_CLK_REF.png" width="200">

<!--- ######################################################## -->

# ZCU111 and RF Balun Daughter card for loopback testing

Assumes you are using the Xilinx XM500 daughter card.

Connect J1 and J6, J2 and J5, J3 and J8, J4 and J7 using loopback SMA cables.

<img src="docs/images/ZCU11_LOOPBACK.png" width="200">


<!--- ######################################################## -->

# ZCU208 and RF Balun Daughter card for loopback testing

Assumes you are using the Xilinx XM655 daughter card.

Connect J3 and J13, J7 and J38, J17 and J25, J40 and J33 using loopback SMA cables.

Connect P0_224/N01_224 and J1/J5, 
P2_224/N23_224 and J8/J11, 
P0_225/N01_225 and J18/J16, 
P2_225/N23_225 and J42/J41 using the ADC's breakout cable

Connect P/N_0_228 and J26/J29, 
P/N_2_228 and J31/J35, 
P/N_0_229 and J15/J14, 
P/N_2_229 and J39/J37 using the DAC's breakout cable


P2_224/N23_224 and J8/J11, 
P0_225/N01_225 and J18/J16, 
P2_225/N23_225 and J42/J41 using the ADC's breakout cable

<img src="docs/images/ZCU11_LOOPBACK.png" width="200">

<!--- ######################################################## -->

# How to generate the Model Composer IP export .ZIP files

1) Setup Model Composer Environment and Licensing (if on SLAC AFS network) else requires Xilinx & Matlab install on your local machine

```bash
# in SLAC
$ source kek-bpm-rfsoc-dev/firmware/SLAC_setup.sh
# in KEK
$ source kek-bpm-rfsoc-dev/firmware/KEK_setup.sh
```

2) Go to the simulink directory and launch model composer

```bash
$ cd kek-bpm-rfsoc-dev/firmware/shared/model_composer/SSR16_Digital_Down_Conversion
$ model_composer
```

3) Open the .SLX file

```bash
$ open('SSRDDC.slx');
```

4) Wait for few minutes .SLX file to load and pop open the simulink window

5) Right click and "open" the "Vitis Model Composer Hub"
<img src="docs/images/BuildDspCore_A.png" width="200">

6) Click on the "generate" button
<img src="docs/images/BuildDspCore_B.png" width="200">

7) Wait few minutes for the build to complete
<img src="docs/images/BuildDspCore_C.png" width="200">

8) When completed, you will see "Generate Complete" message with no ERRORS
<img src="docs/images/BuildDspCore_D.png" width="200">

The .ZIP file is dumped into the netlist/ip directory:

```bash
$ ls -lath netlist/ip/SLAC_KEK_BPM_ssr_ddc_v1_0.zip
-rw-r--r-- 1 nomaru gu 150K Nov 17 10:59 netlist/ip/SLAC_KEK_BPM_ssr_ddc_v1_0.zip
```

Create zip files for SSR12_Digital_Down_Conversion and Position_calculation in the same way.

<!--- ######################################################## -->

# How to generate the RFSoC .BIT and .XSA files

1) Setup Xilinx PATH and licensing (if on SLAC AFS network) else requires Vivado install and licensing on your local machine

```bash
# in SLAC
$ source kek-bpm-rfsoc-dev/firmware/SLAC_setup.sh
# in KEK
$ source kek-bpm-rfsoc-dev/firmware/KEK_setup.sh
```

2) Go to the target directory and make the firmware:

```bash
$ cd kek-bpm-rfsoc-dev/firmware/targets/KekBpmRfsocDevZcu111_4072MSPS/
$ make
```

3) Optional: Review the results in GUI mode

```bash
$ make gui
```

The .bit and .XSA files are dumped into the KekBpmRfsocDevZcu111_4072MSPS/image directory:

```bash
$ ls -lath KekBpmRfsocDevZcu111_4072MSPS/images/
total 47M
drwxr-xr-x 5 ruckman re 2.0K Feb  7 07:13 ..
drwxr-xr-x 2 ruckman re 2.0K Feb  4 21:15 .
-rw-r--r-- 1 ruckman re  14M Feb  4 21:15 KekBpmRfsocDevZcu111_4072MSPS-0x01000000-20220204204648-ruckman-90df89c.xsa
-rw-r--r-- 1 ruckman re  33M Feb  4 21:14 KekBpmRfsocDevZcu111_4072MSPS-0x01000000-20220204204648-ruckman-90df89c.bit
```

You can create .BIT and .XSA files for KekBpmRfsocDevZcu111_3054MSPS in the same way.

<!--- ######################################################## -->

# How to build Petalinux images

1) Generate the .bit and .xsa files (refer to `How to generate the RFSoC .BIT and .XSA files` instructions).

2) Setup Xilinx licensing and petalinux software (if on SLAC AFS network) else requires Xilinx & petalinux install on your local machine

```bash
# These setup scripts assume that you are on SLAC network
$ source kek-bpm-rfsoc-dev/firmware/SLAC_setup.sh
$ source /path/to/petalinux/2022.2/settings.sh
# in KEK
$ source kek-bpm-rfsoc-dev/firmware/KEK_setup.sh
$ source /path/to/petalinux/2022.2/settings.sh
```

3) Go to the target directory and run the `CreatePetalinuxProject.sh` script with arg pointing to path of .XSA file:

```bash
$ cd kek-bpm-rfsoc-dev/firmware/targets/KekBpmRfsocDevZcu111_4072MSPS/
$ source CreatePetalinuxProject.sh images/KekBpmRfsocDevZcu111_4072MSPS-0x01000000-20220204204648-ruckman-90df89c.xsa
```

You can build images for KekBpmRfsocDevZcu111_3054MSPS in the same way.

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
sudo cp kek-bpm-rfsoc-dev/firmware/build/petalinux/KekBpmRfsocDevZcu111_4072MSPS/images/linux/system.bit boot/.
sudo cp kek-bpm-rfsoc-dev/firmware/build/petalinux/KekBpmRfsocDevZcu111_4072MSPS/images/linux/BOOT.BIN   boot/.
sudo cp kek-bpm-rfsoc-dev/firmware/build/petalinux/KekBpmRfsocDevZcu111_4072MSPS/images/linux/image.ub   boot/.
sudo cp kek-bpm-rfsoc-dev/firmware/build/petalinux/KekBpmRfsocDevZcu111_4072MSPS/images/linux/boot.scr   boot/.
sudo sync boot/
sudo umount boot
```

3) Power down the RFSoC board

4) Confirm the DIP switches
- if ZCU111: SW6 [4:1] = 1110 (Mode Pins [3:0]). Note: Switch OFF = 1 = High; ON = 0 = Low.
- if ZCU208: SW2 [4:1] = 1110 (Mode Pins [3:0]). Note: Switch OFF = 1 = High; ON = 0 = Low.

5) Power up the RFSoC board

6) Confirm that you can ping the boot after it boots up

<!--- ######################################################## -->

# How to remote update the firmware bitstream

- Assumes the DHCP assigned IP address is 10.0.0.10

1) Using "scp" to copy your .bit file to the SD memory card on the RFSoC.  Here's an example:

```bash
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "10.0.0.10" # https://jira.slac.stanford.edu/browse/ESRFOC-54
scp KekBpmRfsocDevZcu111_4072MSPS-0x01000000-20220204204648-ruckman-90df89c.bit root@10.0.0.10:/boot/system.bit
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

- Assumes the DHCP assigned IP address is 10.0.0.10 and ZCU111 board type

1) Setup the rogue environment (if on SLAC AFS network) else install rogue (recommend Anaconda method) on your local machine

```bash
# in SLAC
$ source kek-bpm-rfsoc-dev/software/setup_env_slac.sh
# in KEK
$ conda activate rogue
```

2) Go to software directory and lauch the GUI:

```bash
$ cd kek-bpm-rfsoc-dev/software
$ python scripts/devGui.py --ip 10.0.0.10 --boardType zcu111 --bpmFreqMHz 1000
```

<!--- ######################################################## -->
