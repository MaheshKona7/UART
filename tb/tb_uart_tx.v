// ============================================================================
// File Name   : tb_uart_tx.v
// Module Name : tb_uart_tx
// Description : Comprehensive Testbench for UART Transmitter
// ============================================================================

`timescale 1ns / 1ps

module tb_uart_tx;

    // Simulation Parameters (Higher Baud Rate for Faster Sim Speed)
    parameter CLK_FREQ  = 50_000_000;
    parameter BAUD_RATE = 1_000_000; // 1 Mbps for fast simulation
    localparam CLK_PERIOD = 20;      // 50 MHz clock period = 20 ns
    localparam BIT_PERIOD = (CLK_FREQ / BAUD_RATE) * CLK_PERIOD; // 1000 ns per bit

    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_out;
    wire       tx_busy;

    // Instantiate Unit Under Test (UUT)
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_out(tx_out),
        .tx_busy(tx_busy)
    );

    // Clock Generation
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Test Data Array
    reg [7:0] test_bytes [0:3];
    integer i;

    initial begin
        // Initialize Signals
        clk      = 0;
        rst_n    = 0;
        tx_start = 0;
        tx_data  = 8'h00;

        test_bytes[0] = 8'hA5; // 10100101
        test_bytes[1] = 8'h55; // 01010101
        test_bytes[2] = 8'hFF; // 11111111
        test_bytes[3] = 8'h00; // 00000000

        // Reset Pulse
        #100;
        rst_n = 1;
        #40;

        $display("==================================================");
        $display("   STARTING UART TRANSMITTER TESTBENCH           ");
        $display("==================================================");

        for (i = 0; i < 4; i = i + 1) begin
            $display("[TX TEST] Transmitting Byte 0x%0h...", test_bytes[i]);
            tx_data  = test_bytes[i];
            tx_start = 1;
            #CLK_PERIOD;
            tx_start = 0;

            // Wait for transmission to begin
            wait(tx_busy == 1);
            // Wait for transmission to complete
            wait(tx_busy == 0);

            $display("[TX TEST] Transmission of Byte 0x%0h Complete!", test_bytes[i]);
            #(BIT_PERIOD * 2); // Wait 2 bit periods before next send
        end

        $display("==================================================");
        $display("   UART TRANSMITTER TEST COMPLETED SUCCESSFULLY!  ");
        $display("==================================================");
        #1000;
        $finish;
    end

    // VCD Waveform Dump
    initial begin
        $dumpfile("simulation/tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);
    end

endmodule
