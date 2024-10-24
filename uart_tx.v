module uart_tx (
    input wire clk,            // System clock
    input wire tx_start,       // Signal to start transmission
    input wire [7:0] data_in,  // 8-bit data to transmit
    output reg tx_pin,         // UART TX pin
    input wire baud_clk        // Baud rate clock enable signal
);

    reg [9:0] shift_reg;  // Start bit, data bits, stop bit
    reg [3:0] bit_cnt = 0;  // Bit counter
    reg tx_busy = 1'b0;     // Transmission busy flag

    always @(posedge clk) begin
        if (baud_clk == 1'b1) begin
            if (tx_start == 1'b1 && tx_busy == 1'b0) begin
                // Load shift register with start bit, data, and stop bit
                shift_reg <= {1'b1, data_in, 1'b0};  // {Stop bit, data, Start bit}
                bit_cnt <= 0;
                tx_busy <= 1'b1;
            end
            else if (tx_busy == 1'b1) begin
                if (bit_cnt < 10) begin
                    // Shift out each bit in turn
                    tx_pin <= shift_reg[0];
                    shift_reg <= {1'b1, shift_reg[9:1]};  // Shift right
                    bit_cnt <= bit_cnt + 1;
                end
                else begin
                    tx_busy <= 1'b0;  // Transmission complete
                end
            end
        end
    end

endmodule
