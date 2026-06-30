# Setup (Apple Silicon)

## 1. Install the toolchain (OSS CAD Suite)

1. Download the latest release from the releases page:
   <https://github.com/YosysHQ/oss-cad-suite-build/releases>

2. Follow the installation instructions on the README of the project.

3. Install missing dependencies by activating the environment (`source environment`) and running `python3 -m pip install numpy msgspec fastcrc`

4. Verify:
   ```bash
   yosys --version
   nextpnr-himbaechel --version
   gowin_pack --help
   openFPGALoader --version
   ```

## 2. Build the project

Run `make`, and the Makefile runs all the build and route commands.

## 3. Flash the board

Connect the Tang Nano 20K over USB-C, then:
```bash
# Load into SRAM (fast; lost on power cycle)
make flash

# Or write to onboard SPI flash (persists across power cycles)
make flash-spi
```

# Accessing Serial

```bash
screen /dev/cu.usbserial-20250303171 115200
```

