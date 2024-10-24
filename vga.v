module vga(
    input wire CLK,
    input wire [7:0] R_IN, G_IN, B_IN,
    output reg [7:0] R_OUT, G_OUT, B_OUT,
    output reg VGAHS, VGAVS,
    output reg VGA_FRAMESTART, VGA_FRAMEEND,
    output reg ACTVID
);

// Signal declarations
integer Xpos = 0;
integer Ypos = 0;

always @(posedge CLK) begin
    // Frame start condition
    if (Ypos == 624)
        VGA_FRAMESTART <= 1'b1;
    else
        VGA_FRAMESTART <= 1'b0;

    // Frame end condition
    if (Ypos == 600)
        VGA_FRAMEEND <= 1'b1;
    else
        VGA_FRAMEEND <= 1'b0;

    // Horizontal pixel counter
    if (Xpos < 1055)
        Xpos <= Xpos + 1;
    else if (Xpos == 1055) begin
        Xpos <= 0;
        Ypos <= Ypos + 1;
    end

    // Vertical pixel counter
    if (Ypos == 624)
        Ypos <= 0;

    // Horizontal sync pulse
    if (Xpos > 815 && Xpos < 895)
        VGAHS <= 1'b0;
    else
        VGAHS <= 1'b1;

    // Vertical sync pulse
    if (Ypos > 601 && Ypos < 605)
        VGAVS <= 1'b0;
    else
        VGAVS <= 1'b1;

    // Blanking region
    if (Xpos > 800 || Ypos > 600) begin
        B_OUT <= 8'b00000000;
        G_OUT <= 8'b00000000;
        R_OUT <= 8'b00000000;
    end

    // Active video region
    if (Xpos == 1055)
        ACTVID <= 1'b1;
    else if (Xpos == 799 || Ypos > 599)
        ACTVID <= 1'b0;

    // Visible image display
    if (Xpos < 799 && Ypos < 600) begin
        B_OUT <= B_IN;
        R_OUT <= R_IN;
        G_OUT <= G_IN;
    end else begin
        B_OUT <= 8'b00000000;
        G_OUT <= 8'b00000000;
        R_OUT <= 8'b00000000;
    end
end

endmodule
