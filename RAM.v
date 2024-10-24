module true_dual_port_ram_dual_clock (
    input wire clk_a,
    input wire clk_b,
    input wire [8:0] addr_a,  // 9-bit address to access 512 locations
    input wire [8:0] addr_b,
    input wire [7:0] data_a,  // 8-bit data input for port A
    input wire [7:0] data_b,  // 8-bit data input for port B
    input wire we_a,          // Write enable for port A
    input wire we_b,          // Write enable for port B
    output reg [7:0] q_a,     // 8-bit data output for port A
    output reg [7:0] q_b      // 8-bit data output for port B
);

    // Declare the RAM memory (512 x 8 bits)
    reg [7:0] ram [0:511];

    // Port A logic
    always @(posedge clk_a) begin
        if (we_a) begin
            ram[addr_a] <= data_a;  // Write operation
        end
        q_a <= ram[addr_a];          // Read operation
    end

    // Port B logic
    always @(posedge clk_b) begin
        if (we_b) begin
            ram[addr_b] <= data_b;  // Write operation
        end
        q_b <= ram[addr_b];          // Read operation
    end

endmodule
