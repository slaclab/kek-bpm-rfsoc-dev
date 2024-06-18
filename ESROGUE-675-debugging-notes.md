
Error that I am running into with custom build:

```bash
root@KekBpmRfsocDevZcu1114072MSPSBypassDDC:~# rfdc-test
RFdc Selftest Example Test
metal: debug:     added page size 4096 @/tmp
metal: debug:     registered platform bus
metal: debug:     registered pci bus
metal: info:      metal_linux_dev_open: checking driver vfio-platform,490000000.usp_rf_data_converter,(null)
metal: debug:     bound device 490000000.usp_rf_data_converter to driver uio_pdrv_genirq
metal: debug:     opened platform:490000000.usp_rf_data_converter as /dev/uio4
metal: debug:     metal_uio_read_map_attr():79 offset = 0
metal: debug:     metal_uio_read_map_attr():79 addr = 0x490000000
metal: debug:     metal_uio_read_map_attr():79 size = 0x40000
metal: error:                                                                                     ���� not found
metal: error:     vice t���� Selftest Example Test failedal_linux_dev_open: udev_device platform:�

root@KekBpmRfsocDevZcu1114072MSPSBypassDDC:~# ls /dev/uio*
/dev/uio0  /dev/uio1  /dev/uio2  /dev/uio3
```

Note: I observed the same behavior with the aes-stream-driver loaded and not loaded.

##############################################################################################################

Running the xilinx reference design and stock application (`establish a baseline`):

```bash
xilinx-zcu111-20232:/home/petalinux# ls /dev/uio*
/dev/uio0  /dev/uio1  /dev/uio2  /dev/uio3

xilinx-zcu111-20232:/home/petalinux# rfdc-selftest
RFdc Selftest Example Test
metal: info:      metal_linux_dev_open: checking driver vfio-platform,b0080000.usp_rf_data_converter,uio_pdrv_genirq
metal: info:      metal_linux_dev_open: checking driver uio_pdrv_genirq,b0080000.usp_rf_data_converter,uio_pdrv_genirq
metal: info:      metal_linux_dev_open: driver uio_pdrv_genirq bound to b0080000.usp_rf_data_converter
metal: info:      metal_uio_dev_open: No IRQ for device b0080000.usp_rf_data_converter.
metal: info:      metal_linux_dev_open: checking driver vfio-platform,b0080000.usp_rf_data_converter,(null)
metal: info:      metal_uio_dev_open: No IRQ for device b0080000.usp_rf_data_converter.
metal: info:      metal_linux_dev_open: checking driver vfio-platform,b0080000.usp_rf_data_converter,(null)
metal: info:      metal_uio_dev_open: No IRQ for device b0080000.usp_rf_data_converter.
metal: info:      metal_linux_dev_open: checking driver vfio-platform,b0080000.usp_rf_data_converter,(null)
metal: info:      metal_uio_dev_open: No IRQ for device b0080000.usp_rf_data_converter.
Successfully ran Selftest Example Test

xilinx-zcu111-20232:/home/petalinux# ls /dev/uio*
/dev/uio0  /dev/uio1  /dev/uio2  /dev/uio3  /dev/uio4
```

##############################################################################################################

After rebooting (remove uio4 and config), running the custom rfdc-test app on the reference ZCU111 petalinux design:

```bash
xilinx-zcu111-20232:/home/petalinux# ls /dev/uio*
/dev/uio0  /dev/uio1  /dev/uio2  /dev/uio3

xilinx-zcu111-20232:/home/petalinux# rfdc-test
RFdc Selftest Example Test
metal: debug:     added page size 4096 @/tmp
metal: debug:     registered platform bus
metal: debug:     registered pci bus
metal: info:      metal_linux_dev_open: checking driver vfio-platform,b0080000.usp_rf_data_converter,(null)
metal: debug:     bound device b0080000.usp_rf_data_converter to driver uio_pdrv_genirq
metal: debug:     opened platform:b0080000.usp_rf_data_converter as /dev/uio4
metal: debug:     metal_uio_read_map_attr():79 offset = 0
metal: debug:     metal_uio_read_map_attr():79 addr = 0xb0080000
metal: debug:     metal_uio_read_map_attr():79 size = 0x40000
metal: info:      metal_uio_dev_open: No IRQ for device b0080000.usp_rf_data_converter.
metal: info:      metal_linux_dev_open: checking driver vfio-platform,b0080000.usp_rf_data_converter,(null)
metal: debug:     bound device b0080000.usp_rf_data_converter to driver uio_pdrv_genirq
metal: debug:     opened platform:b0080000.usp_rf_data_converter as /dev/uio4
metal: debug:     metal_uio_read_map_attr():79 offset = 0
metal: debug:     metal_uio_read_map_attr():79 addr = 0xb0080000
metal: debug:     metal_uio_read_map_attr():79 size = 0x40000
metal: info:      metal_uio_dev_open: No IRQ for device b0080000.usp_rf_data_converter.
metal: info:      metal_linux_dev_open: checking driver vfio-platform,b0080000.usp_rf_data_converter,(null)
metal: debug:     bound device b0080000.usp_rf_data_converter to driver uio_pdrv_genirq
metal: debug:     opened platform:b0080000.usp_rf_data_converter as /dev/uio4
metal: debug:     metal_uio_read_map_attr():79 offset = 0
metal: debug:     metal_uio_read_map_attr():79 addr = 0xb0080000
metal: debug:     metal_uio_read_map_attr():79 size = 0x40000
metal: info:      metal_uio_dev_open: No IRQ for device b0080000.usp_rf_data_converter.
metal: info:      metal_linux_dev_open: checking driver vfio-platform,b0080000.usp_rf_data_converter,(null)
metal: debug:     bound device b0080000.usp_rf_data_converter to driver uio_pdrv_genirq
metal: debug:     opened platform:b0080000.usp_rf_data_converter as /dev/uio4
metal: debug:     metal_uio_read_map_attr():79 offset = 0
metal: debug:     metal_uio_read_map_attr():79 addr = 0xb0080000
metal: debug:     metal_uio_read_map_attr():79 size = 0x40000
metal: info:      metal_uio_dev_open: No IRQ for device b0080000.usp_rf_data_converter.
Successfully ran Selftest Example Test

xilinx-zcu111-20232:/home/petalinux# ls /dev/uio*
/dev/uio0  /dev/uio1  /dev/uio2  /dev/uio3  /dev/uio4
```


##############################################################################################################

Updated the Xilinx reference design FW to use base offset of 0x490000000 (make sure there is not a 64-bit address bug here).

```bash
xilinx-zcu111-20232:/home/petalinux# rfdc-test
RFdc Selftest Example Test
metal: debug:     added page size 4096 @/tmp
metal: debug:     registered platform bus
metal: debug:     registered pci bus
metal: info:      metal_linux_dev_open: checking driver vfio-platform,490000000.usp_rf_data_converter,(null)
metal: debug:     bound device 490000000.usp_rf_data_converter to driver uio_pdrv_genirq
metal: debug:     opened platform:490000000.usp_rf_data_converter as /dev/uio4
metal: debug:     metal_uio_read_map_attr():79 offset = 0
metal: debug:     metal_uio_read_map_attr():79 addr = 0x490000000
metal: debug:     metal_uio_read_map_attr():79 size = 0x40000
metal: info:      metal_uio_dev_open: No IRQ for device 490000000.usp_rf_data_converter.
metal: info:      metal_linux_dev_open: checking driver vfio-platform,490000000.usp_rf_data_converter,(null)
metal: debug:     bound device 490000000.usp_rf_data_converter to driver uio_pdrv_genirq
metal: debug:     opened platform:490000000.usp_rf_data_converter as /dev/uio4
metal: debug:     metal_uio_read_map_attr():79 offset = 0
metal: debug:     metal_uio_read_map_attr():79 addr = 0x490000000
metal: debug:     metal_uio_read_map_attr():79 size = 0x40000
metal: info:      metal_uio_dev_open: No IRQ for device 490000000.usp_rf_data_converter.
metal: info:      metal_linux_dev_open: checking driver vfio-platform,490000000.usp_rf_data_converter,(null)
metal: debug:     bound device 490000000.usp_rf_data_converter to driver uio_pdrv_genirq
metal: debug:     opened platform:490000000.usp_rf_data_converter as /dev/uio4
metal: debug:     metal_uio_read_map_attr():79 offset = 0
metal: debug:     metal_uio_read_map_attr():79 addr = 0x490000000
metal: debug:     metal_uio_read_map_attr():79 size = 0x40000
metal: info:      metal_uio_dev_open: No IRQ for device 490000000.usp_rf_data_converter.
metal: info:      metal_linux_dev_open: checking driver vfio-platform,490000000.usp_rf_data_converter,(null)
metal: debug:     bound device 490000000.usp_rf_data_converter to driver uio_pdrv_genirq
metal: debug:     opened platform:490000000.usp_rf_data_converter as /dev/uio4
metal: debug:     metal_uio_read_map_attr():79 offset = 0
metal: debug:     metal_uio_read_map_attr():79 addr = 0x490000000
metal: debug:     metal_uio_read_map_attr():79 size = 0x40000
metal: info:      metal_uio_dev_open: No IRQ for device 490000000.usp_rf_data_converter.
Successfully ran Selftest Example Test

xilinx-zcu111-20232:/home/petalinux# ls /dev/uio*
/dev/uio0  /dev/uio1  /dev/uio2  /dev/uio3  /dev/uio4
```bash

##############################################################################################################






























