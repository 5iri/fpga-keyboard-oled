module top(
    input wire clk,
    input wire rx,
    output reg [9:0] leds
);
    wire [7:0] received_data;
    wire data_valid;

    uart_rx uart(
        .clk(clk),
        .rst(0),
        .rx(rx),
        .data(received_data),
        .data_valid(data_valid)
    );

    always @(posedge clk) begin
        if (data_valid) begin
            if (received_data >= "0" && received_data <= "9")
                leds <= 1 << (received_data - "0"); // Turn on corresponding LED
        end
    end
endmodule
