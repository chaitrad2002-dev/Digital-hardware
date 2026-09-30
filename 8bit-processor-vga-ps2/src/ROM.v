`timescale 1ns / 1ps

module ROM(
 // Standard signals
    input               CLK,
    input       [7:0]   ADDR,
     // BUS signals
    output reg  [7:0]   DATA
);

    parameter RAMAddrWidth = 8;
// Memory
    reg [7:0] ROM [0:(2**RAMAddrWidth)-1];
 // Load program
    initial begin
        $readmemh("Complete_Demo_ROM.txt", ROM);
    end
 // Single port ram
    always @(posedge CLK)
        DATA <= ROM[ADDR];

endmodule