# Verilog UART Project (8N1 Specification)

A complete, fully verified **UART (Universal Asynchronous Receiver-Transmitter)** RTL implementation in **Verilog-2001** with comprehensive unit and loopback testbenches using **Icarus Verilog**.

---

## 📁 Repository Structure

```
uart/
├── rtl/                    # Verilog RTL Source Files
│   ├── uart_tx.v           # UART Transmitter Module
│   ├── uart_rx.v           # UART Receiver Module (with 2-stage sync & glitch rejection)
│   └── uart_top.v          # Top-Level UART Controller & Loopback Interface
├── tb/                     # Testbenches
│   ├── tb_uart_tx.v        # Transmitter Unit Testbench
│   ├── tb_uart_rx.v        # Receiver Unit Testbench (normal, glitch, frame error)
│   └── tb_uart_top.v       # Full System Loopback Testbench
├── simulation/             # Simulation output directory (VCD waveforms & VVP executables)
│   ├── tb_uart_tx.vcd
│   ├── tb_uart_rx.vcd
│   └── tb_uart_top.vcd
├── docs/                   # Architecture Documentation
│   └── uart_architecture.md# Detailed FSM diagrams & protocol breakdown
├── run_sim.bat             # One-click Windows batch script to compile & run all tests
└── README.md               # Project documentation and step-by-step guide
```

---

## ⚙️ Key Features & RTL Design Highlights

1. **Parameterizable Architecture**:
   - `CLK_FREQ`: System clock frequency in Hz (Default: `50 MHz`).
   - `BAUD_RATE`: Baud rate in bits/sec (Default: `115,200 bps`).
2. **Robust Transmitter (`uart_tx.v`)**:
   - 8 Data Bits, 1 Stop Bit, No Parity (8N1).
   - Generates clean start bit immediately upon `tx_start` pulse.
   - Outputs status signal `tx_busy`.
3. **High-Reliability Receiver (`uart_rx.v`)**:
   - **2-Stage Synchronizer**: Protects against metastability from external asynchronous RX signal.
   - **Mid-Bit Sampling**: Samples in the exact center of each bit period ($\text{BAUD\_DIV} / 2$) for optimal noise immunity.
   - **False Start Bit Filtering**: Rejects short noise glitches on the RX line.
   - **Frame Error Detection**: Flags missing stop bits via `frame_error` signal.
4. **Top-Level Loopback Interface (`uart_top.v`)**:
   - Built-in `loopback_en` control line for internal self-testing.
   - External serial pins (`tx_pin`, `rx_pin`).

---

## 🚀 Step-by-Step Guide to Run and Test

### Step 1: Prerequisites
Make sure **Icarus Verilog** (`iverilog` & `vvp`) is installed on your system.
On Windows, `iverilog` is located at `C:\iverilog\bin\iverilog.exe`.

### Step 2: One-Click Automated Simulation
Run `run_sim.bat` in Command Prompt or PowerShell:

```cmd
run_sim.bat
```

This script will automatically:
1. Compile `rtl/uart_tx.v` and run `tb/tb_uart_tx.v`.
2. Compile `rtl/uart_rx.v` and run `tb/tb_uart_rx.v`.
3. Compile `rtl/uart_top.v` and run system loopback test `tb/tb_uart_top.v`.
4. Generate VCD waveform files in the `simulation/` directory.

### Step 3: Manual Execution Commands

If you prefer running individual tests manually:

#### 1. Test UART Transmitter
```bash
iverilog -o simulation/tb_uart_tx.vvp rtl/uart_tx.v tb/tb_uart_tx.v
vvp simulation/tb_uart_tx.vvp
```

#### 2. Test UART Receiver
```bash
iverilog -o simulation/tb_uart_rx.vvp rtl/uart_rx.v tb/tb_uart_rx.v
vvp simulation/tb_uart_rx.vvp
```

#### 3. Test Full System Loopback
```bash
iverilog -o simulation/tb_uart_top.vvp rtl/uart_tx.v rtl/uart_rx.v rtl/uart_top.v tb/tb_uart_top.v
vvp simulation/tb_uart_top.vvp
```

---

## 📊 Viewing Waveforms with GTKWave

To inspect bit-level timing waveforms:

```bash
gtkwave simulation/tb_uart_top.vcd
```

Signals to observe:
- `sut.clk` & `sut.rst_n`
- `sut.tx_start` & `sut.tx_data`
- `sut.tx_pin` (Serial line output)
- `sut.rx_data` & `sut.rx_done`

---

## 📝 Testbench Verification Results

- **`tb_uart_tx`**: Transmitted `0xA5`, `0x55`, `0xFF`, `0x00`. Bit timings and frame boundaries verified.
- **`tb_uart_rx`**:
  - Test 1 (`0x3B` receive) -> PASSED
  - Test 2 (`0xC7` receive) -> PASSED
  - Test 3 (40ns Glitch filter check) -> PASSED
  - Test 4 (Frame error check) -> PASSED
- **`tb_uart_top`**: Transmitted string `'HELLO'` (`0x48`, `0x45`, `0x4C`, `0x4C`, `0x4F`) through loopback. All 5 bytes matched 100%.
