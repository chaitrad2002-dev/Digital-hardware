`timescale 1ns / 1ps

//==============================================================
// Module: Frame_Buffer
// Description:
// This module implements the pixel memory used by the VGA system.
//
// It is a Dual-Port RAM:
//  - Port A: Used by the processor to write or read pixel data
//  - Port B: Used by the VGA controller to continuously read pixels
//            for display generation
//
// Memory Size:
//  32,768 locations (2^15 addresses)
//  Each location stores 1-bit pixel value
//
// Addressing:
//  The address {Y, X} from the VGA_Interface forms a 15-bit address.
//==============================================================

module Frame_Buffer(
    //==========================================================
    // Port A : Processor access port
    //==========================================================
    input            A_CLK,        // Clock for processor access
    input     [14:0] A_ADDR,       // Address for processor read/write
    input            A_DATA_IN,    // Pixel value written by processor
    output reg       A_DATA_OUT,   // Pixel value read by processor
    input            A_WE,         // Write enable for processor

    //==========================================================
    // Port B : VGA display read port
    //==========================================================
    input            B_CLK,        // Clock from VGA timing generator
    input     [14:0] B_ADDR,       // Address requested by VGA controller
    output reg       B_DATA        // Pixel value sent to VGA controller
);

    //==========================================================
    // Frame buffer memory
    // 32768 locations storing 1-bit pixel data
    //==========================================================
    reg Mem [0:32767];

    integer i;

    //==========================================================
    // Memory Initialization
    // Clears the entire frame buffer at startup
    // All pixels start as 0 (background)
    //==========================================================
    initial begin
        for(i = 0; i < 32768; i = i + 1)
            Mem[i] = 1'b0;
    end

    //==========================================================
    // Port A : Processor read/write access
    //==========================================================
    always @(posedge A_CLK) begin

        // Write pixel data if write enable is active
        if(A_WE)
            Mem[A_ADDR] <= A_DATA_IN;

        // Read pixel value at given address
        A_DATA_OUT <= Mem[A_ADDR];
    end

    //==========================================================
    // Port B : VGA read access
    // VGA controller reads pixel data continuously
    //==========================================================
    always @(posedge B_CLK) begin
        B_DATA <= Mem[B_ADDR];
    end

endmodule