@echo off
REM ============================================================================
REM Build and Run Script for UART Project Simulations (Icarus Verilog)
REM ============================================================================

echo =================================================================
echo                    UART PROJECT SIMULATION SUITE
echo =================================================================

if not exist "simulation" mkdir simulation

echo [1/3] Building and running UART Transmitter Testbench...
C:\iverilog\bin\iverilog.exe -o simulation/tb_uart_tx.vvp rtl/uart_tx.v tb/tb_uart_tx.v
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Transmitter compilation failed!
    exit /b %ERRORLEVEL%
)
C:\iverilog\bin\vvp.exe simulation/tb_uart_tx.vvp

echo.
echo [2/3] Building and running UART Receiver Testbench...
C:\iverilog\bin\iverilog.exe -o simulation/tb_uart_rx.vvp rtl/uart_rx.v tb/tb_uart_rx.v
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Receiver compilation failed!
    exit /b %ERRORLEVEL%
)
C:\iverilog\bin\vvp.exe simulation/tb_uart_rx.vvp

echo.
echo [3/3] Building and running Top-Level Loopback Testbench...
C:\iverilog\bin\iverilog.exe -o simulation/tb_uart_top.vvp rtl/uart_tx.v rtl/uart_rx.v rtl/uart_top.v tb/tb_uart_top.v
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Top loopback compilation failed!
    exit /b %ERRORLEVEL%
)
C:\iverilog\bin\vvp.exe simulation/tb_uart_top.vvp

echo.
echo =================================================================
echo             ALL SIMULATIONS EXECUTED SUCCESSFULLY!
echo =================================================================
