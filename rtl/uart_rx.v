// ============================================================================
// File Name   : uart_rx.v
// Module Name : uart_rx
// Description : UART Receiver (8 Data Bits, 1 Stop Bit, No Parity - 8N1)
// Standard    : IEEE 1364-2001 (Verilog-2001)
// Features    : 2-Stage Synchronizer for Metastability Immunity,
//               Mid-Bit Sampling, False Start Bit Detection, Frame Error Detection.
// ============================================================================

module uart_rx #(
    parameter CLK_FREQ  = 50_000_000, // System clock frequency in Hz (default: 50 MHz)
    parameter BAUD_RATE = 115_200     // Target baud rate in bps (default: 115200)
) (
    input  wire       clk,         // System clock
    input  wire       rst_n,       // Active-low asynchronous reset
    input  wire       rx_in,       // Serial UART input line
    output reg  [7:0] rx_data,     // Received 8-bit byte output
    output reg        rx_done,     // Pulse high for 1 clock cycle when byte is received
    output reg        rx_busy,     // High while reception is in progress
    output reg        frame_error  // High if stop bit is invalid (0 instead of 1)
);

    // Calculate baud clock divider and midpoint divider
    localparam BAUD_DIV      = CLK_FREQ / BAUD_RATE;
    localparam HALF_BAUD_DIV = BAUD_DIV / 2;

    // FSM State Encoding
    localparam STATE_IDLE  = 2'b00;
    localparam STATE_START = 2'b01;
    localparam STATE_DATA  = 2'b10;
    localparam STATE_STOP  = 2'b11;

    reg [1:0]  state;
    reg [31:0] baud_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  rx_shift;

    // 2-Stage Synchronizer to prevent metastability on asynchronous input line
    reg rx_sync1;
    reg rx_sync2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx_in;
            rx_sync2 <= rx_sync1;
        end
    end

    // Receiver FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= STATE_IDLE;
            rx_data     <= 8'h00;
            rx_done     <= 1'b0;
            rx_busy     <= 1'b0;
            frame_error <= 1'b0;
            baud_cnt    <= 0;
            bit_idx     <= 0;
            rx_shift    <= 8'h00;
        end else begin
            case (state)
                STATE_IDLE: begin
                    rx_done  <= 1'b0;
                    rx_busy  <= 1'b0;
                    baud_cnt <= 0;
                    bit_idx  <= 0;

                    // Start bit detection: falling edge on synchronized RX line
                    if (rx_sync2 == 1'b0) begin
                        state   <= STATE_START;
                        rx_busy <= 1'b1;
                    end
                end

                STATE_START: begin
                    rx_busy <= 1'b1;
                    if (baud_cnt == HALF_BAUD_DIV - 1) begin
                        baud_cnt <= 0;
                        // Mid-bit check: verify start bit is still low
                        if (rx_sync2 == 1'b0) begin
                            state   <= STATE_DATA;
                            bit_idx <= 3'd0;
                        end else begin
                            // False start bit detected (glitch filtering)
                            state   <= STATE_IDLE;
                            rx_busy <= 1'b0;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                STATE_DATA: begin
                    rx_busy <= 1'b1;
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt          <= 0;
                        rx_shift[bit_idx] <= rx_sync2; // Mid-bit sampling

                        if (bit_idx == 3'd7) begin
                            state <= STATE_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                STATE_STOP: begin
                    rx_busy <= 1'b1;
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 0;
                        state    <= STATE_IDLE;
                        rx_busy  <= 1'b0;

                        if (rx_sync2 == 1'b1) begin
                            // Valid stop bit
                            rx_data     <= rx_shift;
                            rx_done     <= 1'b1;
                            frame_error <= 1'b0;
                        end else begin
                            // Frame error (stop bit missing/corrupted)
                            frame_error <= 1'b1;
                            rx_done     <= 1'b0;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule
