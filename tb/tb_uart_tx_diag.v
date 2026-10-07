`timescale 1ns / 1ps

module tb_uart_tx_diag;

    parameter CLK_FREQ = 50_000_000;
    parameter BAUD_RATE = 115_200;
    localparam CLK_PERIOD = 20;

    reg clk;
    reg rst_n;
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_out;
    wire tx_busy;

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

    always #(CLK_PERIOD / 2) clk = ~clk;

    integer bit_index = 0;
    time last_change_time = 0;

    always @(tx_out) begin
        $display("Time %0t ns: tx_out changed to %b (duration of previous val: %0t ns)", $time, tx_out, $time - last_change_time);
        last_change_time = $time;
    end

    initial begin
        clk = 0;
        rst_n = 0;
        tx_start = 0;
        tx_data = 8'hA5; // 8'b10100101. LSB first: 1, 0, 1, 0, 0, 1, 0, 1

        #100;
        rst_n = 1;
        #40;

        $display("--- Starting TX for Data 0xA5 (binary 10100101) ---");
        $display("Expected sequence: Start(0), Bit0(1), Bit1(0), Bit2(1), Bit3(0), Bit4(0), Bit5(1), Bit6(0), Bit7(1), Stop(1)");
        tx_start = 1;
        #CLK_PERIOD;
        tx_start = 0;

        wait(tx_busy == 0);
        #1000;
        $finish;
    end

endmodule
