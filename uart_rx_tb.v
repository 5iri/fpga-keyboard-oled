`timescale 1ns / 1ps

module uart_rx_tb ();
    // Parameters
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz clock
    parameter BAUD_RATE = 115200;
    parameter BIT_PERIOD = 1_000_000_000 / BAUD_RATE;  // in ns

    // Testbench signals
    reg clk = 0;
    reg rst = 0;
    reg rx = 1;
    wire [7:0] data;
    wire data_valid;

    // Test data
    reg [7:0] test_bytes[0:4] = {8'h41, 8'h42, 8'h43, 8'h30, 8'h39};  // "ABC09"
    integer i, j;

    // DUT instantiation
    uart_rx #(
        .CLK_FREQ (100_000_000),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .data(data),
        .data_valid(data_valid)
    );

    // Clock generation
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Task to send a byte via UART
    task send_byte;
        input [7:0] byte_to_send;
        begin
            // Start bit (low)
            rx = 0;
            #(BIT_PERIOD);

            // Data bits (LSB first)
            for (j = 0; j < 8; j = j + 1) begin
                rx = byte_to_send[j];
                #(BIT_PERIOD);
            end

            // Stop bit (high)
            rx = 1;
            #(BIT_PERIOD);
        end
    endtask

    // Test procedure
    initial begin
        $display("Starting UART RX Testbench");

        // Apply reset
        rst = 1;
        #(CLK_PERIOD * 10);
        rst = 0;
        #(CLK_PERIOD * 10);

        // Wait a bit before starting transmission
        rx = 1;  // Idle state
        #(BIT_PERIOD * 2);

        // Send test bytes
        for (i = 0; i < 5; i = i + 1) begin
            $display("Sending byte: 0x%h ('%c')", test_bytes[i], test_bytes[i]);
            send_byte(test_bytes[i]);

            // Wait a bit between bytes
            #(BIT_PERIOD * 2);
        end

        // Let the simulation run a bit longer to complete processing
        #(BIT_PERIOD * 5);

        $display("UART RX Testbench completed");
        $finish;
    end

    // Monitor received data
    always @(posedge clk) begin
        if (data_valid) begin
            $display("Time: %t, Received byte: 0x%h ('%c')", $time, data, data);
        end
    end

    // Optional: Add a timeout
    initial begin
        #(BIT_PERIOD * 100);
        $display("Testbench timeout reached");
        $finish;
    end

    // Optional: Generate waveform file
    initial begin
        $dumpfile("uart_rx_tb.vcd");
        $dumpvars(0, uart_rx_tb);
    end

endmodule
