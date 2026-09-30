`timescale 1ns / 1ps

module Processor_System_Top(
    input        CLK100MHZ,
    input        RESET,
    output       VGA_HS,
    output       VGA_VS,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B
);

wire [7:0] ROM_ADDR;
wire [7:0] ROM_DATA;

wire [7:0] BUS_ADDR;
wire       BUS_WE;
wire [7:0] BUS_DATA;

wire [1:0] IRQ_RAISE;
wire [1:0] IRQ_ACK;

assign IRQ_RAISE[0] = 1'b0;

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

ROM UROM(
    .CLK  (CLK100MHZ),
    .ADDR (ROM_ADDR),
    .DATA (ROM_DATA)
);

RAM URAM(
    .CLK      (CLK100MHZ),
    .BUS_DATA (BUS_DATA),
    .BUS_ADDR (BUS_ADDR),
    .BUS_WE   (BUS_WE)
);

VGA_Interface UVGA(
    .CLK100MHZ (CLK100MHZ),
    .RESET     (RESET),
    .BUS_DATA  (BUS_DATA),
    .BUS_ADDR  (BUS_ADDR),
    .BUS_WE    (BUS_WE),
    .VGA_HS    (VGA_HS),
    .VGA_VS    (VGA_VS),
    .VGA_R     (VGA_R),
    .VGA_G     (VGA_G),
    .VGA_B     (VGA_B)
);

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