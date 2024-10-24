module baud_gen (
    input wire clk,          // System clock
    input wire reset,        // Reset signal
    output reg baud_clk      // Baud rate clock enable signal
);

    parameter baud_rate_div = 434;  // 50 MHz clock / 9600 baud rate
    reg [8:0] counter = 0;          // Counter variable (9 bits to hold values up to 434)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            baud_clk <= 1'b0;
        end
        else begin
            if (counter < baud_rate_div) begin
                counter <= counter + 1;
            end
            else begin
                counter <= 0;
                baud_clk <= ~baud_clk;  // Toggle baud_clk
            end
        end
    end

endmodule
