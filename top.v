module top (
    input wire clk,
    input wire rx,
    output reg [9:0] leds
);
    wire [7:0] received_data;
    wire data_valid;

    // Debug indicator - turns on when any UART activity happens
    reg uart_active = 0;

    uart_rx uart (
        .clk(clk),
        .rst(0),
        .rx(rx),
        .data(received_data),
        .data_valid(data_valid)
    );

    // Main LED control logic with improved handling
    always @(posedge clk) begin
        if (data_valid) begin
            // Set debug indicator on any UART data
            uart_active <= 1;

            // Handle numeric characters (0-9)
            if (received_data >= "0" && received_data <= "9")
                leds <= 1 << (received_data - "0");  // Turn on corresponding LED
            else
                // For any non-numeric character, turn on all LEDs as a test
                leds <= 10'b1111111111;
        end
    end
endmodule
