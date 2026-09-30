`timescale 1ns / 1ps

module VGA_Interface(
    input            CLK100MHZ,
    input            RESET,
    inout      [7:0] BUS_DATA,
    input      [7:0] BUS_ADDR,
    input            BUS_WE,
    output           VGA_HS,
    output           VGA_VS,
    output     [3:0] VGA_R,
    output     [3:0] VGA_G,
    output     [3:0] VGA_B
);

    parameter [7:0] VGABaseAddr = 8'hB0;

    reg [1:0] div;
    always @(posedge CLK100MHZ or posedge RESET) begin
        if (RESET)
            div <= 2'b00;
        else
            div <= div + 2'b01;
    end
    wire CLK25MHZ = div[1];

    reg [7:0] X_reg;
    reg [6:0] Y_reg;
    reg [7:0] FG_reg;
    reg [7:0] BG_reg;

    wire [15:0] CONFIG_COLOURS = {BG_reg, FG_reg};

    reg  [14:0] A_ADDR;
    reg         A_DATA_IN;
    reg         A_WE;

    wire        DPR_CLK;
    wire [14:0] VGA_ADDR;
    wire        VGA_DATA;
    wire [7:0]  VGA_COLOUR;

    assign BUS_DATA = 8'hZZ;

    wire Selected = (BUS_ADDR >= VGABaseAddr) &&
                    (BUS_ADDR <= (VGABaseAddr + 8'h02));

    always @(posedge CLK100MHZ or posedge RESET) begin
        if (RESET) begin
            X_reg     <= 8'd0;
            Y_reg     <= 7'd0;
            FG_reg    <= 8'hE0;
            BG_reg    <= 8'h00;
            A_WE      <= 1'b0;
            A_ADDR    <= 15'd0;
            A_DATA_IN <= 1'b0;
        end else begin
            A_WE <= 1'b0;

            if (BUS_WE && Selected) begin
                if (BUS_ADDR == VGABaseAddr) begin
                    X_reg <= BUS_DATA;
                end else if (BUS_ADDR == (VGABaseAddr + 8'h01)) begin
                    Y_reg <= BUS_DATA[6:0];
                end else if (BUS_ADDR == (VGABaseAddr + 8'h02)) begin
                    if (BUS_DATA[7]) begin
                        if (BUS_DATA[0] == 1'b0)
                            BG_reg <= X_reg;
                        else
                            FG_reg <= X_reg;
                    end else begin
                        A_ADDR    <= {Y_reg, X_reg};
                        A_DATA_IN <= BUS_DATA[0];
                        A_WE      <= 1'b1;
                    end
                end
            end
        end
    end

    Frame_Buffer FB (
        .A_CLK     (CLK100MHZ),
        .A_ADDR    (A_ADDR),
        .A_DATA_IN (A_DATA_IN),
        .A_DATA_OUT(),
        .A_WE      (A_WE),
        .B_CLK     (DPR_CLK),
        .B_ADDR    (VGA_ADDR),
        .B_DATA    (VGA_DATA)
    );

    VGA_Sig_Gen VGA (
        .CLK            (CLK25MHZ),
        .CONFIG_COLOURS (CONFIG_COLOURS),
        .DPR_CLK        (DPR_CLK),
        .VGA_ADDR       (VGA_ADDR),
        .VGA_DATA       (VGA_DATA),
        .VGA_HS         (VGA_HS),
        .VGA_VS         (VGA_VS),
        .VGA_COLOUR     (VGA_COLOUR)
    );

    assign VGA_R = {VGA_COLOUR[7:5], VGA_COLOUR[7]};
    assign VGA_G = {VGA_COLOUR[4:2], VGA_COLOUR[4]};
    assign VGA_B = {VGA_COLOUR[1:0], VGA_COLOUR[1:0]};

endmodule