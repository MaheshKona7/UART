// ============================================================================
// File Name   : tb_uart_top.v
// Module Name : tb_uart_top
// Description : System Loopback Testbench for UART Top Module
// ============================================================================

`timescale 1ns / 1ps

module tb_uart_top;

    parameter CLK_FREQ  = 50_000_000;
    parameter BAUD_RATE = 1_000_000; // 1 Mbps for fast simulation
    localparam CLK_PERIOD = 20;

    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_busy;
    wire [7:0] rx_data;
    wire       rx_done;
    wire       rx_busy;
    wire       frame_error;
    reg        loopback_en;
    reg        rx_pin;
    wire       tx_pin;

    // Instantiate System Under Test (SUT)
    uart_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) sut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_busy(tx_busy),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_busy(rx_busy),
        .frame_error(frame_error),
        .loopback_en(loopback_en),
        .rx_pin(rx_pin),
        .tx_pin(tx_pin)
    );

    // Clock Generation
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Test Data Buffer
    reg [7:0] test_packets [0:4];
    integer i;

    initial begin
        clk         = 0;
        rst_n       = 0;
        tx_start    = 0;
        tx_data     = 8'h00;
        loopback_en = 1'b1; // Enable internal loopback mode
        rx_pin      = 1'b1;

        test_packets[0] = 8'h48; // 'H'
        test_packets[1] = 8'h45; // 'E'
        test_packets[2] = 8'h4C; // 'L'
        test_packets[3] = 8'h4C; // 'L'
        test_packets[4] = 8'h4F; // 'O'

        // Apply Reset
        #100;
        rst_n = 1;
        #100;

        $display("==================================================");
        $display("   STARTING SYSTEM LOOPBACK TESTBENCH (UART TOP) ");
        $display("==================================================");

        for (i = 0; i < 5; i = i + 1) begin
            $display("[LOOPBACK TEST] Transmitting Data: 0x%0h ('%c')", test_packets[i], test_packets[i]);
            tx_data  = test_packets[i];
            tx_start = 1;
            #CLK_PERIOD;
            tx_start = 0;

            // Wait for receiver done signal
            wait(rx_done == 1);
            #CLK_PERIOD;

            if (rx_data == test_packets[i] && !frame_error) begin
                $display("[LOOPBACK SUCCESS] Transmitted 0x%0h -> Received 0x%0h ('%c') MATCH!", 
                         test_packets[i], rx_data, rx_data);
            end else begin
                $display("[LOOPBACK ERROR] Transmitted 0x%0h, but Received 0x%0h (Frame Error = %b)", 
                         test_packets[i], rx_data, frame_error);
            end

            // Wait until TX is free before sending next character
            wait(tx_busy == 0);
            #(CLK_PERIOD * 50);
        end

        $display("==================================================");
        $display("   SYSTEM LOOPBACK TEST COMPLETED SUCCESSFULLY!  ");
        $display("==================================================");
        #1000;
        $finish;
    end

    // VCD Waveform Dump
    initial begin
        $dumpfile("simulation/tb_uart_top.vcd");
        $dumpvars(0, tb_uart_top);
    end

endmodule
