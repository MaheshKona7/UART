// ============================================================================
// File Name   : tb_uart_rx.v
// Module Name : tb_uart_rx
// Description : Comprehensive Testbench for UART Receiver
// ============================================================================

`timescale 1ns / 1ps

module tb_uart_rx;

    parameter CLK_FREQ  = 50_000_000;
    parameter BAUD_RATE = 1_000_000; // 1 Mbps for fast simulation
    localparam CLK_PERIOD = 20;      // 20 ns
    localparam BIT_PERIOD = (CLK_FREQ / BAUD_RATE) * CLK_PERIOD; // 1000 ns per bit

    reg        clk;
    reg        rst_n;
    reg        rx_in;
    wire [7:0] rx_data;
    wire       rx_done;
    wire       rx_busy;
    wire       frame_error;

    // Instantiate Unit Under Test (UUT)
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .rx_in(rx_in),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_busy(rx_busy),
        .frame_error(frame_error)
    );

    // Clock Generation
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Task to send a UART Serial Byte (8N1 format)
    task send_uart_byte;
        input [7:0] data;
        input       corrupt_stop_bit;
        integer bit_i;
        begin
            $display("[RX TB] Sending Serial Byte: 0x%0h (corrupt_stop=%b)", data, corrupt_stop_bit);
            
            // Start Bit (0)
            rx_in = 1'b0;
            #BIT_PERIOD;

            // 8 Data Bits (LSB First)
            for (bit_i = 0; bit_i < 8; bit_i = bit_i + 1) begin
                rx_in = data[bit_i];
                #BIT_PERIOD;
            end

            // Stop Bit (1 if normal, 0 if corrupted)
            rx_in = corrupt_stop_bit ? 1'b0 : 1'b1;
            #BIT_PERIOD;

            // Return line to idle high
            rx_in = 1'b1;
        end
    endtask

    initial begin
        // Initialize Signals
        clk   = 0;
        rst_n = 0;
        rx_in = 1'b1;

        // Reset Pulse
        #100;
        rst_n = 1;
        #100;

        $display("==================================================");
        $display("   STARTING UART RECEIVER TESTBENCH              ");
        $display("==================================================");

        // Test 1: Receive Normal Byte 0x3B (00111011)
        fork
            send_uart_byte(8'h3B, 1'b0);
            @(posedge rx_done);
        join
        if (rx_data == 8'h3B && !frame_error) begin
            $display("[RX TEST 1 PASSED] Successfully Received Byte 0x%0h", rx_data);
        end else begin
            $display("[RX TEST 1 FAILED] Expected 0x3B, got 0x%0h (frame_error=%b)", rx_data, frame_error);
        end
        #(BIT_PERIOD * 2);

        // Test 2: Receive Normal Byte 0xC7 (11000111)
        fork
            send_uart_byte(8'hC7, 1'b0);
            @(posedge rx_done);
        join
        if (rx_data == 8'hC7 && !frame_error) begin
            $display("[RX TEST 2 PASSED] Successfully Received Byte 0x%0h", rx_data);
        end else begin
            $display("[RX TEST 2 FAILED] Expected 0xC7, got 0x%0h (frame_error=%b)", rx_data, frame_error);
        end
        #(BIT_PERIOD * 2);

        // Test 3: False Start Bit Glitch Test (Short low pulse for 40ns << half baud period)
        $display("[RX TEST 3] Testing False Start Bit Glitch Filter...");
        rx_in = 1'b0;
        #(CLK_PERIOD * 2); // 40 ns glitch
        rx_in = 1'b1;      // Line recovers to high
        #(BIT_PERIOD * 2);
        if (rx_busy == 0 && rx_done == 0) begin
            $display("[RX TEST 3 PASSED] False start bit glitch successfully rejected!");
        end else begin
            $display("[RX TEST 3 FAILED] Glitch incorrectly triggered receiver!");
        end
        #(BIT_PERIOD * 2);

        // Test 4: Frame Error Test (Corrupted Stop Bit)
        $display("[RX TEST 4] Testing Frame Error Detection (Corrupted Stop Bit)...");
        send_uart_byte(8'hAA, 1'b1); // Send with corrupt stop bit
        #BIT_PERIOD;
        if (frame_error == 1) begin
            $display("[RX TEST 4 PASSED] Frame Error correctly detected!");
        end else begin
            $display("[RX TEST 4 FAILED] Frame Error was NOT detected.");
        end

        $display("==================================================");
        $display("   UART RECEIVER TEST COMPLETED SUCCESSFULLY!    ");
        $display("==================================================");
        #1000;
        $finish;
    end

    // VCD Waveform Dump
    initial begin
        $dumpfile("simulation/tb_uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);
    end

endmodule
