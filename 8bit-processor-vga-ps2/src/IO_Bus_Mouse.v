`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The University of Edinburgh
// Engineer:
// 
// Create Date:    20:22:07 03/17/2014 
// Design Name: 
// Module Name:    IO_Bus_Mouse 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:
//
// Mouse bus peripheral with:
// - bus-mapped mouse registers at A0-A3
// - interrupt support
// - clamped + sampled mouse coordinates for steadier VGA/7-seg behavior
//
//////////////////////////////////////////////////////////////////////////////////
module IO_Bus_Mouse(
    // standard signals
    input           CLK,
    input           RESET,

    // BUS signals
    inout   [7:0]   BUS_DATA,
    input   [7:0]   BUS_ADDR,
    input           BUS_WE,

    // PS2 serial connections
    inout           CLK_MOUSE,
    inout           DATA_MOUSE,

    // interrupt signals
    output          BUS_INTERRUPT_RAISE,
    input           BUS_INTERRUPT_ACK,

    // direct mouse outputs for top-level region logic / debug
    output  [7:0]   MouseX_out,
    output  [7:0]   MouseY_out
);

    wire [3:0] MouseStatus;
    wire [7:0] MouseX;
    wire [7:0] MouseY;
    wire [7:0] MouseZ;
    wire       SendInterrupt;

    MouseTransceiver mouse(
        .RESET        (RESET),
        .CLK          (CLK),
        .CLK_MOUSE    (CLK_MOUSE),
        .DATA_MOUSE   (DATA_MOUSE),
        .MouseStatus  (MouseStatus),
        .MouseX       (MouseX),
        .MouseY       (MouseY),
        .MouseZ       (MouseZ),
        .SendInterrupt(SendInterrupt)
    );

    // ---------------------------------------------------------
    // Clamp coordinates so cursor does not disappear too easily
    // on the far right / bottom edges
    // ---------------------------------------------------------
    wire [7:0] MouseX_clamped;
    wire [7:0] MouseY_clamped;

   assign MouseX_clamped = (MouseX > 8'd159) ? 8'd159 : MouseX;
assign MouseY_clamped = (MouseY > 8'd119) ? 8'd119 : MouseY;

    // ---------------------------------------------------------
    // Sample mouse coordinates more slowly for stability
    // 100 MHz / 2,000,000 ≈ 20 ms
    // ---------------------------------------------------------
    reg [21:0] sample_counter;
    reg [7:0]  MouseX_sampled;
    reg [7:0]  MouseY_sampled;

    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            sample_counter <= 22'd0;
            MouseX_sampled <= 8'd80;
            MouseY_sampled <= 8'd60;
        end
        else begin
            if (sample_counter == 22'd499999) begin
                sample_counter <= 22'd0;
                MouseX_sampled <= MouseX_clamped;
                MouseY_sampled <= MouseY_clamped;
            end
            else begin
                sample_counter <= sample_counter + 22'd1;
            end
        end
    end

    assign MouseX_out = MouseX_sampled;
    assign MouseY_out = MouseY_sampled;

    // ---------------------------------------------------------
    // Interrupt handling
    // ---------------------------------------------------------
    reg Interrupt;

    always @(posedge CLK) begin
        if (RESET)
            Interrupt <= 1'b0;
        else if (SendInterrupt)
            Interrupt <= 1'b1;
        else if (BUS_INTERRUPT_ACK)
            Interrupt <= 1'b0;
    end

    assign BUS_INTERRUPT_RAISE = Interrupt;

    // ---------------------------------------------------------
    // Bus interface
    // A0 = status
    // A1 = X
    // A2 = Y
    // A3 = Z
    // ---------------------------------------------------------
    parameter BaseAddr  = 8'hA0;
    parameter AddrWidth = 2;   // 4 x 8-bit registers

    wire [7:0] BufferedBusData;
    reg  [7:0] Out;
    reg        IOBusWE;

    assign BUS_DATA        = (IOBusWE) ? Out : 8'hZZ;
    assign BufferedBusData = BUS_DATA;

    reg [7:0] Mem [(2**AddrWidth)-1:0];

    wire CS;
    assign CS = ((BUS_ADDR >= BaseAddr) && (BUS_ADDR < BaseAddr + 2**AddrWidth)) ? 1'b1 : 1'b0;

    always @(posedge CLK) begin
        // continuously refresh readable mouse registers
        Mem[0] <= {4'b0000, MouseStatus};
        Mem[1] <= MouseX_sampled;
        Mem[2] <= MouseY_sampled;
        Mem[3] <= MouseZ;

        if (CS) begin
            if (BUS_WE) begin
                // if CPU writes into this peripheral space
                Mem[BUS_ADDR[1:0]] <= BufferedBusData;
                IOBusWE <= 1'b0;
            end
            else begin
                // CPU is reading from this peripheral
                IOBusWE <= 1'b1;
            end
        end
        else begin
            IOBusWE <= 1'b0;
        end

        Out <= Mem[BUS_ADDR[1:0]];
    end

endmodule