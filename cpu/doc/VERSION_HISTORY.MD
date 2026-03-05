

# Version 1.5.0

Updated CPU version with pipeline stages for control and data paths. Currently there is no hazard detection and control implemented. Therefore, each instruction runs to the end of the pipeline before the next instruction is executed. Therefore the clocks per instruction remains the same, i.e., 5 clock cycles.

Due to the additional pipeline stages, the critical path was reduced improving the theoretical maximum clock frequency to 20.73 MHz.

## Delta to previous version:

- Added pipeline stages for control and data paths.
- No hazard detection and control implemented.

## Performance:

- **CPI (Cycles Per Instruction)**: 5
- **IPC (Instructions Per Cycle)**: 0.2

- **Clock frequency**: 20.73 MHz
- **Resource utilization**:
- **CPI (Cycles Per Instruction)**: 5
- **IPC (Instructions Per Cycle)**: 0.2
- **Clock frequency**: 14.31 MHz
- **Resource utilization**:
 
| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| ICESTORM_LC | 2841 | 5280 | 53% |
| ICESTORM_RAM | 6 | 30 | 20% |
| SB_IO | 4 | 96 | 4% |
| SB_GB | 6 | 8 | 75% |
| ICESTORM_PLL | 0 | 1 | 0% |
| SB_WARMBOOT | 0 | 1 | 0% |
| ICESTORM_DSP | 0 | 8 | 0% |
| ICESTORM_HFOSC | 0 | 1 | 0% |
| ICESTORM_LFOSC | 0 | 1 | 0% |
| SB_I2C | 0 | 2 | 0% |
| SB_SPI | 0 | 2 | 0% |
| IO_I3C | 0 | 2 | 0% |
| SB_LEDDA_IP | 0 | 1 | 0% |
| SB_RGBA_DRV | 0 | 1 | 0% |
| ICESTORM_SPRAM | 2 | 4 | 50% |

- **Benchmark scores**: 
Measured at 12 MHz.

| Benchmark | Score |
|-----------|-------|
| Dhrystone | 5773 Dhrystone/s |
| DMIPS | 3.285 DMIPS |
| DMIPS/MHz | 0.27375 DMIPS/MHz |
| Coremark | 3 Interations/Sec |
| Coremark/MHz | 0.25 Interations/Sec/MHz |
| Whetstone | 62.5 KIPS |
| Whetstone/MHz | 5.45 KIPS/MHz |

- **Architecture compatability**: Update to ICE40 FPGA broke RSIC-V Architectural test suite testbench (Test suite does not fit into FPGA RAM)

# Version 1.0.0

First version of the CPU. Full RV32I instruction set with support for basic arithmetic, control flow, and memory operations. No support for floating-point or vector instructions. Intentially simple design. Due to the used synchronous memory (EBR and SPRAM of the ice40up5k), each instruction takes 5 clock cycles to complete. However, not all control signals and data are pipelined. Therefore, the maximum clock frequency is 14.31 MHz.

The CPU was tested against the RISC-V Architectural test suite in simulation using verilator (the test suite does not fit into FPGA RAM). Additionally, the CPU was tested in an ICE40up5k FPGA (using icebreaker board) against 3 different benchmarks: Dhrystone, Whetstone, and Coremark.

The result can be seen below.

## Delta to previous version:

N/A - No previous version exists.

## Performance:

- **CPI (Cycles Per Instruction)**: 5
- **IPC (Instructions Per Cycle)**: 0.2
- **Clock frequency**: 14.31 MHz
- **Resource utilization**:
 
| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| ICESTORM_LC | 2356 | 5280 | 44% |
| ICESTORM_RAM | 6 | 30 | 20% |
| SB_IO | 4 | 96 | 4% |
| SB_GB | 7 | 8 | 87% |
| ICESTORM_PLL | 0 | 1 | 0% |
| SB_WARMBOOT | 0 | 1 | 0% |
| ICESTORM_DSP | 0 | 8 | 0% |
| ICESTORM_HFOSC | 0 | 1 | 0% |
| ICESTORM_LFOSC | 0 | 1 | 0% |
| SB_I2C | 0 | 2 | 0% |
| SB_SPI | 0 | 2 | 0% |
| IO_I3C | 0 | 2 | 0% |
| SB_LEDDA_IP | 0 | 1 | 0% |
| SB_RGBA_DRV | 0 | 1 | 0% |
| ICESTORM_SPRAM | 2 | 4 | 50% |

- **Benchmark scores**: 
Measured at 12 MHz.

| Benchmark | Score |
|-----------|-------|
| Dhrystone | 5773 Dhrystone/s |
| DMIPS | 3.285 DMIPS |
| DMIPS/MHz | 0.27375 DMIPS/MHz |
| Coremark | 3 Interations/Sec |
| Coremark/MHz | 0.25 Interations/Sec/MHz |
| Whetstone | 62.5 KIPS |
| Whetstone/MHz | 5.45 KIPS/MHz |

- **Architecture compatability**: Update to ICE40 FPGA broke RSIC-V Architectural test suite testbench (Test suite does not fit into FPGA RAM)