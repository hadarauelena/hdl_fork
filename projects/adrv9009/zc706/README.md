# ADRV9009/ZC706 HDL Project

## Building the project

The parameters configurable through the `make` command, can be found below, as well as in the **system_project.tcl** file; it contains the default configuration.

```
cd projects/adrv9009/zc706
make
```

If other configurations than the default one are desired, then the parameters from the HDL project (see below) need to be changed, as well as the Linux/no-OS project configurations.

New profiles other than the default one that we provide, can be generated using the [MATLAB Filter Wizard / Profile Generator for ADRV9009](https://www.analog.com/media/en/evaluation-boards-kits/evaluation-software/ADRV9008-x-ADRV9009-profile-config-tool-filter-wizard-v2.4.zip).

The overwritable parameters from the environment:

- [TX/RX/RX_OS]_JESD_M: [TX/RX/RX_OS] number of converters per link
- [TX/RX/RX_OS]_JESD_L: [TX/RX/RX_OS] number of lanes per link
- [TX/RX/RX_OS]_JESD_S: [TX/RX/RX_OS] number of samples per converter per frame

RX_OS means RX Observation path.

### Example configurations

#### Default configuration

This specific command is equivalent to running `make` only:

```
make TX_JESD_M=4 \
TX_JESD_L=4 \
TX_JESD_S=1 \
RX_JESD_M=4 \
RX_JESD_L=2 \
RX_JESD_S=1 \
RX_OS_JESD_M=2 \
RX_OS_JESD_L=2 \
RX_OS_JESD_S=1
```

Corresponding device tree: [zynq-zc706-adv7511-adrv9009-jesd204-fsm.dts](https://github.com/analogdevicesinc/linux/blob/main/arch/arm/boot/dts/xilinx/zynq-zc706-adv7511-adrv9009-jesd204-fsm.dts)
