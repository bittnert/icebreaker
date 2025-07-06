# EvolveRISC

EvolveRISC is an educational RISC-V CPU implementation that evolves from a simple, easy-to-understand design into a more complex, high-performance processor through incremental improvements. This project documents the impact of various architectural optimizations on performance using standardized benchmarks.

## Project Goals

- Create a baseline RISC-V implementation that prioritizes clarity and simplicity
- Incrementally add performance improvements and features
- Measure and document the performance impact of each optimization
- Provide educational insights into CPU design trade-offs
- Serve as a reference for understanding how CPU optimizations affect real-world performance

## Current Status

The current implementation is a simple RISC-V CPU with:

- RV32I base integer instruction set support
- Multi-cycle execution model (5 cycles per instruction)
- State machine-based control flow (Fetch, Decode, Execute, Memory, Writeback)
- No pipelining (instructions execute sequentially)
- Basic memory interface
- Minimal control logic
- Prepared for future pipelining implementation

Metrics of the current implementation:

- **CPI (Cycles Per Instruction)**: 5
- **IPC (Instructions Per Cycle)**: 0.2
- **Clock frequency**: N/A (does not fit into ice40 FPGA)
- **Resource utilization**: N/A (does not fit into ice40 FPGA)
- **Benchmark scores**: N/A (not yet measured)
- **Architecture compatability**: RV32I architecture test suite, 100 % test passed (simulation only)

## Next Steps

- [ ] Add load/store unit to have different memories and peripherals
- [ ] Change main memory to use Single port SRAM instead of Embedded block RAM
- [ ] Add ROM using EBR containing bootloader to load binary into new main memory
- [ ] Add UART interface for user input and output
- [ ] Run design in FPGA (using ice40 FPGA)

## Planned Optimizations

The following optimizations will be implemented and benchmarked incrementally:

1. **Pipelining**
   - Basic 5-stage pipeline (Fetch, Decode, Execute, Memory, Writeback)
   - Pipeline hazard detection
   - Forwarding logic

2. **Branch Prediction**
   - Static branch prediction
   - 1-bit dynamic branch prediction
   - 2-bit saturating counter prediction
   - Branch target buffer (BTB)

3. **Caching**
   - Direct-mapped instruction cache
   - Set-associative instruction cache
   - Data cache implementation
   - Cache coherency protocols

4. **Instruction-Level Parallelism**
   - Superscalar execution
   - Out-of-order execution
   - Register renaming

5. **Memory Hierarchy Improvements**
   - Memory access reordering
   - Non-blocking caches
   - Prefetching mechanisms

6. **RISC-V Extensions**
   - M extension (multiplication and division)
   - C extension (compressed instructions)
   - F/D extensions (floating-point)

7. **Advanced Features**
   - SIMD instructions
   - Speculative execution
   - Multi-core support

## Benchmarks

The following benchmarks will be used to measure performance improvements:

### Synthetic Benchmarks

- **Dhrystone** - Measures integer performance
- **Whetstone** - Measures floating-point performance
- **CoreMark** - Industry-standard benchmark for embedded systems

### Algorithm-specific Benchmarks

- **Quicksort** - Memory access patterns and branching
- **Matrix Multiplication** - Computational intensity and memory bandwidth
- **FFT (Fast Fourier Transform)** - Complex arithmetic operations
- **CRC32** - Bit manipulation efficiency

### Application-oriented Benchmarks

- **JPEG Encoding/Decoding** - Real-world image processing
- **SHA-256** - Cryptographic performance
- **Zlib Compression** - Data processing capabilities

### RISC-V Specific Benchmarks

- **RISC-V Architectural Test Suite** - Compliance and correctness
- **Embench IoT** - Specifically designed for embedded RISC-V implementations

## Performance Metrics

For each optimization, the following metrics will be tracked:

- **CPI (Cycles Per Instruction)** - Efficiency of instruction execution
- **IPC (Instructions Per Cycle)** - Throughput of the processor
- **Clock frequency** - Maximum achievable frequency on target hardware
- **Resource utilization** - FPGA resources required (LUTs, FFs, BRAMs, etc.)
- **Benchmark scores** - Standardized performance metrics

## Implementation Platform

The primary implementation target is the iCEBreaker FPGA board, which features a Lattice iCE40UP5K FPGA. The design is written in Verilog and uses open-source tools for synthesis and implementation.

## Getting Started

[Instructions for building and testing the CPU will be added as the project progresses]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
