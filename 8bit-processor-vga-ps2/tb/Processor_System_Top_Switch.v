`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: Processor_System_Top_Switch
// Description:
// Top-level module for the processor-based VGA system with an
// added switch-controlled display feature.
//
// This module connects together:
// - Processor
// - ROM
// - RAM
// - VGA interface with switch control
// - Timer interrupt module
//
// Extra Functionality:
// - SW0 is used to control VGA display visibility in the
//   modified VGA interface module.
//
// Inputs:
// - CLK100MHZ : Main system clock
// - RESET     : Active-high reset
// - SW0       : Switch input for VGA display enable
//
// Outputs:
// - VGA_HS, VGA_VS : VGA sync signals
// - VGA_R/G/B      : VGA colour outputs
//////////////////////////////////////////////////////////////////////////////////

module Processor_System_Top_Switch(
    input        CLK100MHZ,   // 100 MHz board clock
    input        RESET,       // Active-high reset
    input        SW0,         // Switch input for extra VGA functionality
    output       VGA_HS,      // VGA horizontal sync
    output       VGA_VS,      // VGA vertical sync
    output [3:0] VGA_R,       // VGA red output
    output [3:0] VGA_G,       // VGA green output
    output [3:0] VGA_B        // VGA blue output
);

    //==========================================================
    // ROM interface signals
    //==========================================================
    wire [7:0] ROM_ADDR;      // Address sent from processor to ROM
    wire [7:0] ROM_DATA;      // Instruction/data from ROM to processor

    //==========================================================
    // Shared processor bus signals
    //==========================================================
    wire [7:0] BUS_ADDR;      // Shared bus address
    wire       BUS_WE;        // Shared bus write enable
    wire [7:0] BUS_DATA;      // Shared bus data

    //==========================================================
    // Interrupt lines
    //==========================================================
    wire [1:0] IRQ_RAISE;     // Interrupt request lines
    wire [1:0] IRQ_ACK;       // Interrupt acknowledge lines

    // Interrupt source 0 is permanently disabled
    assign IRQ_RAISE[0] = 1'b0;

    //==========================================================
    // Processor instance
    //==========================================================
    Processor CPU(
        .CLK                 (CLK100MHZ),
        .RESET               (RESET),
        .BUS_DATA            (BUS_DATA),
        .BUS_ADDR            (BUS_ADDR),
        .BUS_WE              (BUS_WE),
        .ROM_ADDRESS         (ROM_ADDR),
        .ROM_DATA            (ROM_DATA),
        .BUS_INTERRUPTS_RAISE(IRQ_RAISE),
        .BUS_INTERRUPTS_ACK  (IRQ_ACK)
    );

    //==========================================================
    // ROM instance
    // Stores program instructions for the processor
    //==========================================================
    ROM UROM(
        .CLK  (CLK100MHZ),
        .ADDR (ROM_ADDR),
        .DATA (ROM_DATA)
    );

    //==========================================================
    // RAM instance
    // Stores processor data
    //==========================================================
    RAM URAM(
        .CLK      (CLK100MHZ),
        .BUS_DATA (BUS_DATA),
        .BUS_ADDR (BUS_ADDR),
        .BUS_WE   (BUS_WE)
    );

    //==========================================================
    // Modified VGA interface with switch-controlled display
    //==========================================================
    VGA_Interface_Switch UVGA(
        .CLK100MHZ (CLK100MHZ),
        .RESET     (RESET),
        .SW0       (SW0),
        .BUS_DATA  (BUS_DATA),
        .BUS_ADDR  (BUS_ADDR),
        .BUS_WE    (BUS_WE),
        .VGA_HS    (VGA_HS),
        .VGA_VS    (VGA_VS),
        .VGA_R     (VGA_R),
        .VGA_G     (VGA_G),
        .VGA_B     (VGA_B)
    );

    //==========================================================
    // Timer instance
    // Generates interrupt request on IRQ_RAISE[1]
    //==========================================================
    Timer UTIMER(
        .CLK                (CLK100MHZ),
        .RESET              (RESET),
        .BUS_DATA           (BUS_DATA),
        .BUS_ADDR           (BUS_ADDR),
        .BUS_WE             (BUS_WE),
        .BUS_INTERRUPT_RAISE(IRQ_RAISE[1]),
        .BUS_INTERRUPT_ACK  (IRQ_ACK[1])
    );

endmodule