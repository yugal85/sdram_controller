module uart_rx (
    input wire clk,             // System clock
    input wire rx_pin,          // UART RX pin
    input wire baud_clk,        // Baud rate clock enable signal
    output reg [7:0] data_out,  // 8-bit received data
    output reg rx_ready         // Signal that data is ready
);

    reg [9:0] shift_reg;        // Shift register for 10 bits (start, 8 data, stop)
    reg [3:0] bit_cnt = 0;      // Bit counter
    reg rx_active = 1'b0;       // Reception active flag
    reg [7:0] rx_data;          // Register to store received data
    reg start_bit = 1'b0;       // Start bit flag

    always @(posedge clk) begin
        if (baud_clk == 1'b1) begin
            if (rx_active == 1'b0 && rx_pin == 1'b0) begin
                // Start bit detected
                rx_active <= 1'b1;
                bit_cnt <= 0;
                rx_ready <= 1'b0;
            end
            else if (rx_active == 1'b1) begin
                if (bit_cnt < 10) begin
                    // Shift in the bits
                    shift_reg <= {rx_pin, shift_reg[9:1]};
                    bit_cnt <= bit_cnt + 1;
                end
                else begin
                    // Done receiving, check stop bit
                    if (shift_reg[0] == 1'b1) begin
                        rx_data <= shift_reg[8:1];  // Extract the 8 data bits
                        rx_ready <= 1'b1;           // Set rx_ready flag
                    end
                    rx_active <= 1'b0;             // Reset rx_active flag
                end
            end
        end
    end

    // Assign received data to the output
    always @(posedge clk) begin
        if (rx_ready == 1'b1) begin
            data_out <= rx_data;   // Send received data to the output
        end
        else begin
            data_out <= 8'b0;      // Clear the output if no data is ready
        end
    end

endmodule
