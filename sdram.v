module sdram(
    input wire CLOCK_50,
    input wire [9:0] SW,
    output wire [7:0] VGA_B, VGA_G, VGA_R,
    output wire VGA_CLK, VGA_BLANK_N, VGA_HS, VGA_VS, VGA_SYNC_N,
    output wire [9:0] LEDR,
    input wire [3:0] KEY,
    output wire [11:0] DRAM_ADDR,
    output wire [1:0] DRAM_BA,
    output wire DRAM_CAS_N, DRAM_CKE, DRAM_CLK, DRAM_CS_N,
    inout wire [15:0] DRAM_DQ,
    output wire DRAM_RAS_N, DRAM_WE_N,
    output wire DRAM_LDQM, DRAM_UDQM,
    output wire TX_PIN, // UART TX pin
    input wire RX_PIN   // UART RX pin
);

// State definition for BUFF_CTRL
localparam ST0 = 2'b00, ST1 = 2'b01;

// Signal declarations
reg [1:0] BUFF_CTRL = ST0;
integer counter = 0;
reg test = 0;
reg [7:0] testdata = 8'b00000000;
integer Xpos = 0, Ypos = 0;
reg BUFF_WAIT = 0;
reg [2:0] VGAFLAG;
integer RAMFULL_POINTER = 0;
integer RAMRESTART_POINTER = 0;
reg [8:0] RAMADDR1GR = 9'b000000000, RAMADDR2GR = 9'b000000000;
reg [8:0] RAMADDR1GR_sync0, RAMADDR1GR_sync1, RAMADDR1GR_sync2, RAMADDR1_bin;
reg [8:0] RAMADDR2GR_sync0, RAMADDR2GR_sync1, RAMADDR2GR_sync2, RAMADDR2_bin;
reg [7:0] RAMIN1, RAMIN2, RAMOUT1, RAMOUT2;
reg RAMWE1 = 0, RAMWE2 = 0;
integer RAMADDR1 = 0, RAMADDR2 = 0;

reg [2:0] NEXTFRAME = 3'b000;
reg FRAMEEND = 0, FRAMESTART = 0;
reg ACTVIDEO = 0, VGABEGIN = 0;
reg [7:0] RED, GREEN, BLUE;

wire CLK167, CLK167_2, CLK49_5;
wire [21:0] SDRAM_ADDR;
wire [1:0] SDRAM_BE_N;
wire SDRAM_CS, SDRAM_RDVAL, SDRAM_WAIT;
wire SDRAM_RE_N, SDRAM_WE_N;
wire [15:0] SDRAM_READDATA, SDRAM_WRITEDATA;
wire [1:0] DRAM_DQM;

// UART Signals
reg tx_start = 0;
reg [7:0] tx_data;
reg [7:0] rx_data;
reg rx_ready = 0;
wire tx_baud_clk, rx_baud_clk;
reg tx_ready = 1;

// Instantiate Baud Rate Generator
baud_gen u_baud_tx(
    .clk(CLOCK_50),
    .reset(1'b0),
    .baud_clk(tx_baud_clk)
);

baud_gen u_baud_rx(
    .clk(CLOCK_50),
    .reset(1'b0),
    .baud_clk(rx_baud_clk)
);

// Instantiate UART Transmitter
uart_tx u_tx(
    .clk(CLOCK_50),
    .tx_start(tx_start),
    .data_in(tx_data),
    .tx_pin(TX_PIN), // UART TX pin
    .baud_clk(tx_baud_clk)
);

// Instantiate UART Receiver
uart_rx u_rx(
    .clk(CLOCK_50),
    .rx_pin(RX_PIN), // UART RX pin
    .baud_clk(rx_baud_clk),
    .data_out(rx_data),
    .rx_ready(rx_ready)
);

// Assignments for SDRAM signals and VGA control signals
assign DRAM_LDQM = DRAM_DQM[0];
assign DRAM_UDQM = DRAM_DQM[1];
assign DRAM_CLK = CLK167_2;
assign VGA_CLK = CLK49_5;
assign SDRAM_CS = 1'b1;
assign SDRAM_BE_N = 2'b00;
assign VGA_BLANK_N = 1'b1;
assign VGA_SYNC_N = 1'b0;

// UART Transmission Logic
always @(posedge CLOCK_50) begin
    if (tx_ready == 1'b1) begin
        if (BUFF_WAIT == 1'b0) begin
            tx_data <= RAMOUT1;  // Fetch data from buffer
            tx_start <= 1'b1;    // Start UART transmission
            tx_ready <= 1'b0;    // Mark UART as busy
        end else begin
            tx_start <= 1'b0;    // Stop transmission when buffer not ready
        end
    end
    if (tx_start == 1'b1) begin
        tx_start <= 1'b0;  // Reset tx_start after transmission starts
    end
    if (tx_start == 1'b0 && tx_ready == 1'b0) begin
        tx_ready <= 1'b1;  // UART is ready for next byte
    end
end

// SDRAM to buffer write/read processes would be implemented here
// Process for writing image data to SDRAM
always @(posedge CLK167) begin
    if (BUFF_CTRL == ST0) begin
        if (SDRAM_WAIT == 1'b0) begin
            SDRAM_WE_N <= 1'b0;
            SDRAM_RE_N <= 1'b1;
            if (Xpos < 799)
                Xpos <= Xpos + 1;
            else begin
                Xpos <= 0;
                if (Ypos < 599)
                    Ypos <= Ypos + 1;
                else
                    Ypos <= 0;
            end
            if ((Xpos - SW) * (Xpos - SW) + (Ypos - 300) * (Ypos - 300) < 40000)
                test <= 1'b0;
            else
                test <= 1'b1;

            SDRAM_WRITEDATA[7:0] <= {8{test}}; 
            SDRAM_ADDR <= SDRAM_ADDR + 1;
        end
        if (SDRAM_ADDR > (800*600-1)) begin
            RAMADDR1 <= 0;
            BUFF_WAIT <= 1'b0;
            RAMFULL_POINTER <= 10;
            BUFF_CTRL <= ST1;
            SDRAM_ADDR <= 0;
        end
    end else if (BUFF_CTRL == ST1) begin
        SDRAM_WE_N <= 1'b1;
        RAMWE1 <= SDRAM_RDVAL;
        if (BUFF_WAIT == 1'b0) begin
            SDRAM_RE_N <= 1'b0;
            if (SDRAM_WAIT == 1'b0 && SDRAM_RE_N == 1'b0) begin
                if (RAMFULL_POINTER < 511)
                    RAMFULL_POINTER <= RAMFULL_POINTER + 1;
                else
                    RAMFULL_POINTER <= 0;
                SDRAM_ADDR <= SDRAM_ADDR + 1;
            end
            if (RAMADDR2_bin == RAMFULL_POINTER) begin
                VGAFLAG[0] <= 1'b1;
                SDRAM_RE_N <= 1'b1;
                BUFF_WAIT <= 1'b1;
                if (RAMADDR2 + 63 < 511)
                    RAMRESTART_POINTER <= RAMADDR2_bin + 63;
                else
                    RAMRESTART_POINTER <= RAMADDR2_bin + 63 - 511;
            end
        end
        RAMIN1 <= SDRAM_READDATA[7:0];
        if (SDRAM_RDVAL == 1'b1) begin
            if (RAMADDR1 < 511)
                RAMADDR1 <= RAMADDR1 + 1;
            else
                RAMADDR1 <= 0;
        end
        if (RAMADDR2_bin == RAMRESTART_POINTER && BUFF_WAIT == 1'b1)
            BUFF_WAIT <= 1'b0;
        if (NEXTFRAME[2] == 1'b1) begin
            Xpos <= 0;
            Ypos <= 0;
            BUFF_CTRL <= ST0;
            VGAFLAG[0] <= 1'b0;
            SDRAM_ADDR <= 0;
            counter <= 0;
            test <= 1'b0;
        end
    end
end

// Process for VGA data synchronization and display
always @(posedge CLK49_5) begin
    RAMADDR2GR <= bin_to_gray(RAMADDR2);
    RAMADDR1GR_sync0 <= RAMADDR1GR;
    RAMADDR1GR_sync1 <= RAMADDR1GR_sync0;
    VGAFLAG[1] <= VGAFLAG[0];
    VGAFLAG[2] <= VGAFLAG[1];
    RAMADDR1_bin <= gray_to_bin(RAMADDR1GR_sync1);

    if (VGAFLAG[2] == 1'b1 && FRAMESTART == 1'b1)
        VGABEGIN <= 1'b1;

    if (FRAMEEND == 1'b1 && VGABEGIN == 1'b1) begin
        NEXTFRAME[0] <= 1'b1;
        VGABEGIN <= 1'b0;
    end else begin
        NEXTFRAME[0] <= 1'b0;
    end

    if (ACTVIDEO == 1'b1 && RAMADDR1_bin != RAMADDR2 && VGABEGIN == 1'b1) begin
        if (RAMADDR2 < 511)
            RAMADDR2 <= RAMADDR2 + 1;
        else
            RAMADDR2 <= 0;
        RED <= RAMOUT2;
        GREEN <= RAMOUT2;
        BLUE <= RAMOUT2;
    end else if (VGABEGIN == 1'b0) begin
        RAMADDR2 <= 0;
        BLUE <= 8'b00000000;
        RED <= 8'b00000000;
        GREEN <= 8'b00000000;
    end
end

endmodule

