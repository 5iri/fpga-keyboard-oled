module uart_rx #(
    parameter CLK_FREQ  = 100_000_000,  // 100 MHz FPGA clock
    parameter BAUD_RATE = 115200
) (
    input  wire       clk,        // FPGA clock
    input  wire       rst,        // Reset signal
    input  wire       rx,         // UART receive line
    output reg  [7:0] data,       // Received data
    output reg        data_valid  // High when new data is received
);

    // States
    localparam IDLE = 2'd0;
    localparam DATA = 2'd1;
    localparam STOP = 2'd2;
    localparam COMPLETE = 2'd3;

    // Calculate baud rate divider
    localparam BAUD_TICK = CLK_FREQ / BAUD_RATE;

    // Registers
    reg [15:0] counter;
    reg [ 1:0] state;
    reg [ 3:0] bits;
    reg [ 7:0] shift_reg;

    // Initialize values
    initial begin
        counter = 0;
        state = IDLE;
        bits = 0;
        shift_reg = 0;
        data = 0;
        data_valid = 0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            state <= IDLE;
            bits <= 0;
            shift_reg <= 0;
            data <= 0;
            data_valid <= 0;
        end else begin
            // Default state for data_valid (auto-clear after one cycle)
            if (data_valid) data_valid <= 0;

            case (state)
                IDLE: begin
                    if (rx == 0) begin  // Start bit detected
                        counter <= 0;
                        bits <= 0;
                        state <= DATA;
                    end
                end

                DATA: begin
                    if (counter < BAUD_TICK - 1) begin
                        counter <= counter + 1;
                    end else begin
                        counter <= 0;
                        // Sample in the middle of the bit
                        if (counter == BAUD_TICK / 2) begin
                            // Shift in new bit (LSB first)
                            shift_reg <= {rx, shift_reg[7:1]};
                            bits <= bits + 1;

                            // Check if we've received all 8 bits
                            if (bits == 7) begin
                                state <= STOP;
                            end
                        end
                    end
                end

                STOP: begin
                    if (counter < BAUD_TICK - 1) begin
                        counter <= counter + 1;
                    end else begin
                        // Check for valid stop bit
                        if (rx == 1) begin
                            data  <= shift_reg;  // Update output data
                            state <= COMPLETE;
                        end else begin
                            // Invalid stop bit (framing error)
                            state <= IDLE;
                        end
                        counter <= 0;
                    end
                end

                COMPLETE: begin
                    data_valid <= 1;  // Signal data is valid for one clock cycle
                    state <= IDLE;  // Return to idle state for next byte
                end
            endcase
        end
    end
endmodule
