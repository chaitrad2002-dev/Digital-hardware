`timescale 1ns / 1ps

//==============================================================
// Module: Processor
// Description:
// Simple processor core for the assignment system.
// - Fetches instructions from ROM
// - Reads/writes data through shared bus
// - Supports ALU operations, branching, function calls,
//   memory dereferencing, and interrupt handling
//==============================================================

module Processor(
    input           CLK,                    // System clock
    input           RESET,                  // Active-high reset
    inout   [7:0]   BUS_DATA,               // Shared 8-bit data bus
    output  [7:0]   BUS_ADDR,               // Shared 8-bit address bus
    output          BUS_WE,                 // Bus write enable
    output  [7:0]   ROM_ADDRESS,            // Address sent to ROM
    input   [7:0]   ROM_DATA,               // Instruction/data read from ROM
    input   [1:0]   BUS_INTERRUPTS_RAISE,   // Interrupt request lines
    output  [1:0]   BUS_INTERRUPTS_ACK      // Interrupt acknowledge lines
);

    //==========================================================
    // Internal bus interface signals
    //==========================================================
    wire [7:0] BusDataIn;                   // Data read from shared bus
    reg  [7:0] CurrBusDataOut, NextBusDataOut;
    reg        CurrBusDataOutWE, NextBusDataOutWE;

    // Tri-state bus connection:
    // Processor drives BUS_DATA only during write operations
    assign BusDataIn = BUS_DATA;
    assign BUS_DATA  = CurrBusDataOutWE ? CurrBusDataOut : 8'hZZ;
    assign BUS_WE    = CurrBusDataOutWE;

    // Bus address register
    reg [7:0] CurrBusAddr, NextBusAddr;
    assign BUS_ADDR = CurrBusAddr;

    //==========================================================
    // General-purpose registers and control registers
    //==========================================================
    reg [7:0] CurrRegA, NextRegA;           // General register A
    reg [7:0] CurrRegB, NextRegB;           // General register B
    reg       CurrRegSelect, NextRegSelect; // Selects destination/source register
    reg [7:0] CurrProgContext, NextProgContext; // Stores return address for function call

    // Interrupt acknowledge register
    reg [1:0] CurrInterruptAck, NextInterruptAck;
    assign BUS_INTERRUPTS_ACK = CurrInterruptAck;

    //==========================================================
    // Program counter and ROM fetch logic
    //==========================================================
    reg  [7:0] CurrProgCounter, NextProgCounter;             // Current program counter
    reg  [1:0] CurrProgCounterOffset, NextProgCounterOffset; // Offset for multi-byte instruction fetch
    wire [7:0] ProgMemoryOut;                                // Current ROM output
    wire [7:0] ActualAddress;                                // Actual ROM address after offset

    assign ActualAddress = CurrProgCounter + CurrProgCounterOffset;
    assign ROM_ADDRESS   = ActualAddress;
    assign ProgMemoryOut = ROM_DATA;

    //==========================================================
    // ALU instance
    // ALU opcode is taken from upper nibble of instruction
    //==========================================================
    wire [7:0] AluOut;
    ALU ALU0 (
        .CLK         (CLK),
        .RESET       (RESET),
        .IN_A        (CurrRegA),
        .IN_B        (CurrRegB),
        .ALU_Op_Code (ProgMemoryOut[7:4]),
        .OUT_RESULT  (AluOut)
    );

    //==========================================================
    // State encoding for processor finite state machine
    //==========================================================
    parameter [7:0]
        IDLE                    = 8'hF0, // Wait state / interrupt polling

        GET_THREAD_START_ADDR_0 = 8'hF1, // Interrupt thread start fetch step 0
        GET_THREAD_START_ADDR_1 = 8'hF2, // Interrupt thread start fetch step 1
        GET_THREAD_START_ADDR_2 = 8'hF3, // Interrupt thread start fetch step 2

        CHOOSE_OPP              = 8'h00, // Decode current instruction

        READ_FROM_MEM_TO_A      = 8'h10, // Read memory into register A
        READ_FROM_MEM_TO_B      = 8'h11, // Read memory into register B
        READ_FROM_MEM_0         = 8'h12, // Memory read step 0
        READ_FROM_MEM_1         = 8'h13, // Memory read step 1
        READ_FROM_MEM_2         = 8'h14, // Memory read step 2
        READ_WAIT               = 8'hC0, // Wait state for memory read

        WRITE_TO_MEM_FROM_A     = 8'h20, // Write register A to memory
        WRITE_TO_MEM_FROM_B     = 8'h21, // Write register B to memory
        WRITE_ADDR              = 8'h22, // Setup write address
        WRITE_TO_MEM_0          = 8'h23, // Memory write step 0
        WRITE_TO_MEM_1          = 8'h24, // Memory write step 1

        DO_MATHS_OPP_SAVE_IN_A  = 8'h30, // ALU operation result stored in A
        DO_MATHS_OPP_SAVE_IN_B  = 8'h31, // ALU operation result stored in B
        DO_MATHS_OPP_0          = 8'h32, // ALU completion state

        IF_A_EQUALITY_B_GOTO    = 8'h40, // Conditional branch setup
        IF_A_EQUALITY_B_GOTO_0  = 8'h41, // Conditional branch execute

        GOTO_OP                 = 8'h50, // Unconditional jump setup
        GOTO_OP_0               = 8'h51, // Unconditional jump execute

        FUNCTION_START          = 8'h60, // Function call setup
        FUNCTION_START_0        = 8'h61, // Function call execute

        RETURN_OP               = 8'h70, // Return from function

        DE_REFERENCE_A          = 8'h80, // Dereference memory address in A
        DE_REFERENCE_B          = 8'h90, // Dereference memory address in B

        ROM_FETCH               = 8'hA0; // Fetch next instruction from ROM

    // Current and next FSM state
    reg [7:0] CurrState, NextState;

    //==========================================================
    // Sequential logic
    // Updates all state-holding registers on rising clock edge
    //==========================================================
    always @(posedge CLK) begin
        if (RESET) begin
            CurrState             <= ROM_FETCH;
            CurrProgCounter       <= 8'h00;
            CurrProgCounterOffset <= 2'h0;
            CurrBusAddr           <= 8'hFF;
            CurrBusDataOut        <= 8'h00;
            CurrBusDataOutWE      <= 1'b0;
            CurrRegA              <= 8'h00;
            CurrRegB              <= 8'h00;
            CurrRegSelect         <= 1'b0;
            CurrProgContext       <= 8'h00;
            CurrInterruptAck      <= 2'b00;
        end else begin
            CurrState             <= NextState;
            CurrProgCounter       <= NextProgCounter;
            CurrProgCounterOffset <= NextProgCounterOffset;
            CurrBusAddr           <= NextBusAddr;
            CurrBusDataOut        <= NextBusDataOut;
            CurrBusDataOutWE      <= NextBusDataOutWE;
            CurrRegA              <= NextRegA;
            CurrRegB              <= NextRegB;
            CurrRegSelect         <= NextRegSelect;
            CurrProgContext       <= NextProgContext;
            CurrInterruptAck      <= NextInterruptAck;
        end
    end

    //==========================================================
    // Combinational next-state logic
    // Default assignments first, then override per state
    //==========================================================
    always @* begin
        NextState             = CurrState;
        NextProgCounter       = CurrProgCounter;
        NextProgCounterOffset = 2'h0;
        NextBusAddr           = 8'hFF;
        NextBusDataOut        = CurrBusDataOut;
        NextBusDataOutWE      = 1'b0;
        NextRegA              = CurrRegA;
        NextRegB              = CurrRegB;
        NextRegSelect         = CurrRegSelect;
        NextProgContext       = CurrProgContext;
        NextInterruptAck      = 2'b00;

        case (CurrState)

            //==================================================
            // IDLE:
            // Wait here until an interrupt request arrives
            //==================================================
            IDLE: begin
                if (BUS_INTERRUPTS_RAISE[0]) begin
                    NextState        = GET_THREAD_START_ADDR_0;
                    NextProgCounter  = 8'hFF;   // ROM location for interrupt 0 vector
                    NextInterruptAck = 2'b01;
                end else if (BUS_INTERRUPTS_RAISE[1]) begin
                    NextState        = GET_THREAD_START_ADDR_0;
                    NextProgCounter  = 8'hFE;   // ROM location for interrupt 1 vector
                    NextInterruptAck = 2'b10;
                end else begin
                    NextState        = IDLE;
                    NextProgCounter  = CurrProgCounter;
                    NextInterruptAck = 2'b00;
                end
            end

            //==================================================
            // Interrupt vector fetch sequence
            //==================================================
            GET_THREAD_START_ADDR_0: begin
                NextState = GET_THREAD_START_ADDR_1;
            end

            GET_THREAD_START_ADDR_1: begin
                NextState       = GET_THREAD_START_ADDR_2;
                NextProgCounter = ProgMemoryOut; // Load ISR/thread start address
            end

            GET_THREAD_START_ADDR_2: begin
                NextState = ROM_FETCH;
            end

            //==================================================
            // Fetch instruction from ROM
            //==================================================
            ROM_FETCH: begin
                NextState = CHOOSE_OPP;
            end

            //==================================================
            // Decode instruction using lower nibble
            //==================================================
            CHOOSE_OPP: begin
                NextProgCounterOffset = 2'h1;
                case (ProgMemoryOut[3:0])
                    4'h0:    NextState = READ_FROM_MEM_TO_A;
                    4'h1:    NextState = READ_FROM_MEM_TO_B;
                    4'h2:    NextState = WRITE_TO_MEM_FROM_A;
                    4'h3:    NextState = WRITE_TO_MEM_FROM_B;
                    4'h4:    NextState = DO_MATHS_OPP_SAVE_IN_A;
                    4'h5:    NextState = DO_MATHS_OPP_SAVE_IN_B;
                    4'h6:    NextState = IF_A_EQUALITY_B_GOTO;
                    4'h7:    NextState = GOTO_OP;
                    4'h8:    NextState = IDLE;
                    4'h9:    NextState = FUNCTION_START;
                    4'hA:    NextState = RETURN_OP;
                    4'hB:    NextState = DE_REFERENCE_A;
                    4'hC:    NextState = DE_REFERENCE_B;
                    default: NextState = CurrState;
                endcase
            end

            //==================================================
            // Read from memory into register A or B
            //==================================================
            READ_FROM_MEM_TO_A: begin
                NextState     = READ_FROM_MEM_0;
                NextRegSelect = 1'b0;
            end

            READ_FROM_MEM_TO_B: begin
                NextState     = READ_FROM_MEM_0;
                NextRegSelect = 1'b1;
            end

            READ_FROM_MEM_0: begin
                NextState   = READ_FROM_MEM_1;
                NextBusAddr = ProgMemoryOut; // Operand gives memory address
            end

            READ_FROM_MEM_1: begin
                NextState       = READ_WAIT;
                NextBusAddr     = CurrBusAddr;
                NextProgCounter = CurrProgCounter + 8'd2; // Move to next instruction
            end

            READ_WAIT: begin
                NextState   = READ_FROM_MEM_2;
                NextBusAddr = CurrBusAddr;
            end

            READ_FROM_MEM_2: begin
                NextState = ROM_FETCH;
                if (!CurrRegSelect)
                    NextRegA = BusDataIn;
                else
                    NextRegB = BusDataIn;
            end

            //==================================================
            // Write register A or B to memory
            //==================================================
            WRITE_TO_MEM_FROM_A: begin
                NextState       = WRITE_ADDR;
                NextRegSelect   = 1'b0;
                NextProgCounter = CurrProgCounter + 8'd2;
            end

            WRITE_TO_MEM_FROM_B: begin
                NextState       = WRITE_ADDR;
                NextRegSelect   = 1'b1;
                NextProgCounter = CurrProgCounter + 8'd2;
            end

            WRITE_ADDR: begin
                NextState   = WRITE_TO_MEM_0;
                NextBusAddr = ProgMemoryOut; // Operand gives memory address
            end

            WRITE_TO_MEM_0: begin
                NextState        = WRITE_TO_MEM_1;
                NextBusAddr      = CurrBusAddr;
                NextBusDataOut   = CurrRegSelect ? CurrRegB : CurrRegA;
                NextBusDataOutWE = 1'b1;
            end

            WRITE_TO_MEM_1: begin
                NextState        = ROM_FETCH;
                NextBusAddr      = CurrBusAddr;
                NextBusDataOut   = CurrBusDataOut;
                NextBusDataOutWE = 1'b1;
            end

            //==================================================
            // Execute ALU operation and save result
            //==================================================
            DO_MATHS_OPP_SAVE_IN_A: begin
                NextState       = DO_MATHS_OPP_0;
                NextRegA        = AluOut;
                NextProgCounter = CurrProgCounter + 8'd1;
            end

            DO_MATHS_OPP_SAVE_IN_B: begin
                NextState       = DO_MATHS_OPP_0;
                NextRegB        = AluOut;
                NextProgCounter = CurrProgCounter + 8'd1;
            end

            DO_MATHS_OPP_0: begin
                NextState = ROM_FETCH;
            end

            //==================================================
            // Conditional branch
            // Note: current design checks if RegA equals 8'h01
            //==================================================
            IF_A_EQUALITY_B_GOTO: begin
                NextState             = IF_A_EQUALITY_B_GOTO_0;
                NextProgCounterOffset = 2'h1;
            end

            IF_A_EQUALITY_B_GOTO_0: begin
                NextState = ROM_FETCH;
                if (CurrRegA == 8'h01)
                    NextProgCounter = ProgMemoryOut;
                else
                    NextProgCounter = CurrProgCounter + 8'd2;
            end

            //==================================================
            // Unconditional jump
            //==================================================
            GOTO_OP: begin
                NextState             = GOTO_OP_0;
                NextProgCounterOffset = 2'h1;
            end

            GOTO_OP_0: begin
                NextState       = ROM_FETCH;
                NextProgCounter = ProgMemoryOut;
            end

            //==================================================
            // Function call:
            // Save return address in program context
            //==================================================
            FUNCTION_START: begin
                NextState             = FUNCTION_START_0;
                NextProgCounterOffset = 2'h1;
                NextProgContext       = CurrProgCounter + 8'd2;
            end

            FUNCTION_START_0: begin
                NextState       = ROM_FETCH;
                NextProgCounter = ProgMemoryOut;
            end

            //==================================================
            // Return from function
            //==================================================
            RETURN_OP: begin
                NextState       = ROM_FETCH;
                NextProgCounter = CurrProgContext;
            end

            //==================================================
            // Dereference register A/B as memory address
            //==================================================
            DE_REFERENCE_A: begin
                NextState       = READ_WAIT;
                NextBusAddr     = CurrRegA;
                NextRegSelect   = 1'b0;
                NextProgCounter = CurrProgCounter + 8'd1;
            end

            DE_REFERENCE_B: begin
                NextState       = READ_WAIT;
                NextBusAddr     = CurrRegB;
                NextRegSelect   = 1'b1;
                NextProgCounter = CurrProgCounter + 8'd1;
            end

            //==================================================
            // Default recovery state
            //==================================================
            default: begin
                NextState = ROM_FETCH;
            end
        endcase
    end

endmodule