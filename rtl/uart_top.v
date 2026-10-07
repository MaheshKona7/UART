// ============================================================================
// File Name   : uart_top.v
// Module Name : uart_top
// Description : Top-Level UART Controller Module (Transmitter + Receiver + Loopback)
// Standard    : IEEE 1364-2001 (Verilog-2001)
// ============================================================================

module uart_top #(
    parameter CLK_FREQ  = 50_000_000, // System clock frequency in Hz
    parameter BAUD_RATE = 115_200     // Target baud rate in bps
) (
    input  wire       clk,         // System clock
    input  wire       rst_n,       // Active-low asynchronous reset

    // Transmitter Interface
    input  wire       tx_start,    // Pulse high to transmit tx_data
    input  wire [7:0] tx_data,     // Data payload to transmit
    output wire       tx_busy,     // High while transmitter is active

    // Receiver Interface
    output wire [7:0] rx_data,     // Received data payload
    output wire       rx_done,     // High pulse for 1 clock cycle on valid reception
    output wire       rx_busy,     // High while receiver is active
    output wire       frame_error, // High on stop bit frame error

    // Serial Physical Pins & Loopback Option
    input  wire       loopback_en, // 1: Internal Loopback mode; 0: External Pin mode
    input  wire       rx_pin,      // External physical RX input pin
    output wire       tx_pin       // External physical TX output pin
);

    wire serial_tx_out;
    wire serial_rx_in;

    // Connect external TX pin
    assign tx_pin = serial_tx_out;

    // Select RX input line based on loopback control mode
    assign serial_rx_in = (loopback_en) ? serial_tx_out : rx_pin;

    // Instantiate UART Transmitter Module
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_out(serial_tx_out),
        .tx_busy(tx_busy)
    );

    // Instantiate UART Receiver Module
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_in(serial_rx_in),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_busy(rx_busy),
        .frame_error(frame_error)
    );

endmodule
