// ============================================================================
// File Name   : uart_tx.v
// Module Name : uart_tx
// Description : UART Transmitter (8 Data Bits, 1 Stop Bit, No Parity - 8N1)
// Standard    : IEEE 1364-2001 (Verilog-2001)
// ============================================================================

module uart_tx #(
    parameter CLK_FREQ  = 50_000_000, // System clock frequency in Hz (default: 50 MHz)
    parameter BAUD_RATE = 115_200     // Target baud rate in bps (default: 115200)
) (
    input  wire       clk,      // System clock
    input  wire       rst_n,    // Active-low asynchronous reset
    input  wire       tx_start, // Pulse high to start transmission
    input  wire [7:0] tx_data,  // 8-bit data payload to transmit
    output reg        tx_out,   // Serial UART output line
    output reg        tx_busy   // High during active transmission
);

    // Calculate number of clock cycles per baud bit
    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;

    // FSM State Encoding
    localparam STATE_IDLE     = 1'b0;
    localparam STATE_TRANSMIT = 1'b1;

    reg       state;
    reg [31:0] baud_cnt;
    reg [3:0]  bit_idx;
    reg [9:0]  tx_frame; // 10-bit frame: {Stop_bit(1), tx_data[7:0], Start_bit(0)}

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= STATE_IDLE;
            tx_out   <= 1'b1; // UART idle state is high
            tx_busy  <= 1'b0;
            baud_cnt <= 0;
            bit_idx  <= 0;
            tx_frame <= 10'h3FF;
        end else begin
            case (state)
                STATE_IDLE: begin
                    tx_out  <= 1'b1;
                    tx_busy <= 1'b0;
                    baud_cnt <= 0;
                    bit_idx  <= 0;

                    if (tx_start) begin
                        // Load 10-bit frame: [0]=Start(0), [8:1]=Data, [9]=Stop(1)
                        tx_frame <= {1'b1, tx_data, 1'b0};
                        tx_out   <= 1'b0; // Immediately output start bit
                        tx_busy  <= 1'b1;
                        state    <= STATE_TRANSMIT;
                    end
                end

                STATE_TRANSMIT: begin
                    tx_busy <= 1'b1;
                    tx_out  <= tx_frame[bit_idx];

                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 0;
                        if (bit_idx == 4'd9) begin
                            // All 10 bits transmitted (Start + 8 Data + Stop)
                            state   <= STATE_IDLE;
                            tx_out  <= 1'b1;
                            tx_busy <= 1'b0;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
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
