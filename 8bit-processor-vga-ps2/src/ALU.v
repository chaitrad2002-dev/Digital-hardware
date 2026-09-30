`timescale 1ns / 1ps

//==============================================================
// Module: ALU (Arithmetic Logic Unit)
// Description:
// Performs arithmetic and logical operations on two 8-bit inputs.
// The operation executed is determined by the 4-bit ALU_Op_Code.
//
// This module is used by the Processor to perform calculations
// such as addition, subtraction, comparisons, shifts, and
// increment/decrement operations.
//
// Inputs:
//   IN_A, IN_B      : 8-bit operands
//   ALU_Op_Code     : Operation selector
//
// Output:
//   OUT_RESULT      : Result of ALU operation
//==============================================================

module ALU(
    input           CLK,            // System clock
    input           RESET,          // Active-high reset
    input   [7:0]   IN_A,           // Operand A
    input   [7:0]   IN_B,           // Operand B
    input   [3:0]   ALU_Op_Code,    // ALU operation code
    output  [7:0]   OUT_RESULT      // Result of the operation
);

    // Register to store ALU output
    reg [7:0] Out;

    //==========================================================
    // ALU operation logic
    // Executes on the rising edge of the clock
    //==========================================================
    always @(posedge CLK) begin
        if (RESET)
            // Reset ALU output to zero
            Out <= 8'h00;
        else begin
            case (ALU_Op_Code)

                // Arithmetic operations
                4'h0: Out <= IN_A + IN_B;   // Addition
                4'h1: Out <= IN_A - IN_B;   // Subtraction
                4'h2: Out <= IN_A * IN_B;   // Multiplication

                // Bit shift operations
                4'h3: Out <= IN_A << 1;     // Left shift A
                4'h4: Out <= IN_A >> 1;     // Right shift A

                // Increment operations
                4'h5: Out <= IN_A + 1'b1;   // Increment A
                4'h6: Out <= IN_B + 1'b1;   // Increment B

                // Decrement operations
                4'h7: Out <= IN_A - 1'b1;   // Decrement A
                4'h8: Out <= IN_B - 1'b1;   // Decrement B

                // Comparison operations
                4'h9: Out <= (IN_A == IN_B) ? 8'h01 : 8'h00; // Equality check
                4'hA: Out <= (IN_A >  IN_B) ? 8'h01 : 8'h00; // A greater than B
                4'hB: Out <= (IN_A <  IN_B) ? 8'h01 : 8'h00; // A less than B

                // Default operation
                default: Out <= IN_A;       // Pass-through
            endcase
        end
    end

    // Connect internal register to module output
    assign OUT_RESULT = Out;

endmodule