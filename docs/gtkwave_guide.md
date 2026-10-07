# GTKWave & Waveform Analysis Guide for UART Project

This guide explains how to generate, open, and analyze waveform files (`.vcd`) using **Icarus Verilog** and **GTKWave**.

---

## 🛠️ 1. Generating Waveform Files

Run the automated simulation script in your terminal:

```cmd
run_sim.bat
```

This generates three VCD (Value Change Dump) waveform files inside the `simulation/` directory:
- `simulation/tb_uart_top.vcd` (Full system loopback simulation)
- `simulation/tb_uart_rx.vcd` (Receiver unit test waveform)
- `simulation/tb_uart_tx.vcd` (Transmitter unit test waveform)

---

## 🖥️ 2. Opening GTKWave

Open Command Prompt or PowerShell in `c:\projects\uart` and run:

```cmd
gtkwave simulation/tb_uart_top.vcd
```
*(If `gtkwave` is not in your PATH, run `C:\iverilog\gtkwave\bin\gtkwave.exe simulation/tb_uart_top.vcd`)*

---

## 🔍 3. How to Setup Signals in GTKWave

1. **Navigate the Signal Tree (SST Panel)**:
   - On the left sidebar under **SST**, expand `tb_uart_top` and click on `sut` (System Under Test).
2. **Select Signals**:
   - In the bottom-left signal pane, highlight the following key signals:
     - `clk` (System clock)
     - `rst_n` (Active-low reset)
     - `tx_start` (Transmit trigger)
     - `tx_data` (Data input byte)
     - `tx_busy` (Transmitter active status)
     - `tx_pin` (Serial line waveform)
     - `rx_data` (Received data byte)
     - `rx_done` (Receive complete pulse)
     - `rx_busy` (Receiver active status)
3. **Append to Display**:
   - Click the **Append** button at the bottom (or press `Alt + A`).
4. **Zoom to Fit Waveform**:
   - Click the **Zoom Fit** icon on the toolbar (or press `Ctrl + Shift + R`).
5. **Change Signal Display Format (Radix)**:
   - Right-click `tx_data` or `rx_data` $\rightarrow$ **Data Format** $\rightarrow$ select **Hexadecimal** or **ASCII**.

---

## 📈 4. Understanding the Output Graph (Step-by-Step)

### A. System Loopback Waveform (`tb_uart_top.vcd`)

```
clk         __||__||__||__||__||__||__||__||__||__||__||__||__||__||__||__||
tx_start    ____|‾‾|________________________________________________________
tx_data     ====( 0x4D / 'M' )==============================================
tx_pin      ‾‾‾‾‾‾‾‾\_______/   \_______/   \_______/   \_______/‾‾‾‾‾‾‾‾‾‾‾
                     Start Bit   Data Bit 0  Data Bit 1  Data Bit 2   Stop Bit
                     (0)         (1)         (0)         (1)          (1)
rx_done     ________________________________________________________|‾‾|____
rx_data     ====================================================( 0x4D / 'M' )
```

#### Step-by-Step Timing Breakdown:
1. **Idle State**:
   - Before transmission starts, `tx_pin` is continuously **HIGH (`1`)**. This is standard UART idle voltage level.
2. **Transmission Trigger**:
   - At time $t = 200\text{ ns}$, `tx_start` pulses HIGH for 1 clock cycle with `tx_data = 0x4D` (ASCII character `'M'`, binary `01001101`).
   - `tx_busy` transitions to HIGH (`1`).
3. **Start Bit Output**:
   - `tx_pin` drops **LOW (`0`)** for exactly **1 Bit Period** ($1000\text{ ns} = 50\text{ clock cycles}$). This signals the receiver that a byte frame has begun.
4. **Data Bits (LSB-First)**:
   - Over the next 8 Bit Periods ($8 \times 1000\text{ ns}$), `tx_pin` outputs the 8 data bits starting from bit 0 (LSB) to bit 7 (MSB):
     - Bit 0 = `1`
     - Bit 1 = `0`
     - Bit 2 = `1`
     - Bit 3 = `1`
     - Bit 4 = `0`
     - Bit 5 = `0`
     - Bit 6 = `1`
     - Bit 7 = `0`
5. **Stop Bit Output**:
   - After Bit 7, `tx_pin` returns to **HIGH (`1`)** for 1 Bit Period ($1000\text{ ns}$) to mark the frame end.
6. **Receiver Processing & Output**:
   - The UART Receiver samples `tx_pin` in the middle of each bit period ($500\text{ ns}$ into each bit).
   - Once the stop bit is sampled at the middle of bit period 10, `rx_data` updates to `0x4D` (`'M'`) and `rx_done` pulses HIGH for exactly 1 clock cycle ($20\text{ ns}$).

---

### B. Receiver Glitch Rejection & Frame Error (`tb_uart_rx.vcd`)

When opening `simulation/tb_uart_rx.vcd` in GTKWave:

1. **Glitch Rejection Test (Test 3)**:
   - Observe `rx_in` dropping LOW for only 2 clock cycles ($40\text{ ns}$).
   - Notice that `rx_busy` and `rx_done` remain `0`. The FSM checked the line at $\text{HALF\_BAUD\_DIV}$ ($500\text{ ns}$), saw the line recovered to `1`, and correctly discarded the noise glitch!
2. **Frame Error Test (Test 4)**:
   - Observe `rx_in` receiving data `0xAA` followed by a corrupted stop bit (`0` instead of `1`).
   - Notice `frame_error` pulses HIGH (`1`) and `rx_done` stays `0`, protecting upstream logic from corrupted data.
