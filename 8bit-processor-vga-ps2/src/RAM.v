`timescale 1ns / 1ps

module RAM(
  // Standard Signals
    input       CLK,
  // BUS Signals
    inout [7:0] BUS_DATA,
    input [7:0] BUS_ADDR,
    input       BUS_WE
);

    parameter RAMBaseAddr  = 8'h00;
    parameter RAMAddrWidth = 7;
    // Tristate
    wire [7:0] BufferedBusData;
    reg  [7:0] Out;
    reg        RAMBusWE;
    
   //Only place data on the bus if the processor is NOT writing, and it is addressing this memory assign
    assign BUS_DATA = (RAMBusWE) ? Out : 8'hZZ;
    assign BufferedBusData = BUS_DATA;
//Memory
    reg [7:0] Mem [0:(2**RAMAddrWidth)-1];

    // Initialise the memory for data preloading, initialising variables, and declaring constants

    initial begin
        $readmemh("Complete_Demo_RAM.txt", Mem);
    end
   
    // Single port ram
    always @(posedge CLK) begin
     // Brute-force RAM address decoding. Think of a simpler way...

        if ((BUS_ADDR >= RAMBaseAddr) && (BUS_ADDR < RAMBaseAddr + 8'd128)) begin
            if (BUS_WE) begin
                Mem[BUS_ADDR[6:0]] <= BufferedBusData;
                RAMBusWE <= 1'b0;
            end else begin
                RAMBusWE <= 1'b1;
            end
        end else begin
            RAMBusWE <= 1'b0;
        end

        Out <= Mem[BUS_ADDR[6:0]];
    end

endmodule