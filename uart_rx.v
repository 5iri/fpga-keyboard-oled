module uart_rx #(
    parameter CLK_FREQ = 100_000_000,  // 100 MHz FPGA clock
    parameter BAUD_RATE = 115200
)(
    input wire clk,         // FPGA clock
    input wire rst,         // Reset signal
    input wire rx,          // UART receive line
    output reg [7:0] data,  // Received data
    output reg data_valid   // High when new data is received
);

    localparam BAUD_TICK = CLK_FREQ / BAUD_RATE; // Clock ticks per bit
    reg [15:0] baud_counter = 0;
    reg [3:0] bit_index = 0;
    reg [7:0] shift_reg = 0;
    reg receiving = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            baud_counter <= 0;
            bit_index <= 0;
            shift_reg <= 0;
            receiving <= 0;
            data_valid <= 0;
        end else begin
            if (!receiving) begin
                if (!rx) begin  // Start bit detected (rx goes low)
                    receiving <= 1;
                    baud_counter <= BAUD_TICK / 2; // Sample in middle of bit
                    bit_index <= 0;
                end
            end else begin
                baud_counter <= baud_counter - 1;
                if (baud_counter == 0) begin
                    baud_counter <= BAUD_TICK;
                    if (bit_index < 8) begin
                        shift_reg[bit_index] <= rx; // Store received bit
                        bit_index <= bit_index + 1;
                    end else begin
                        receiving <= 0;
                        data <= shift_reg; // Store final byte
                        data_valid <= 1;   // Indicate new data
                    end
                end
            end
        end
    end
endmodule
