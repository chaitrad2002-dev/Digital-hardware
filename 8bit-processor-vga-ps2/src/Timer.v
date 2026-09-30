`timescale 1ns / 1ps

//==============================================================
// Module: Timer
// Description:
// This module implements a programmable timer that generates
// periodic interrupts for the processor.
//
// Features:
// - Generates interrupts at configurable time intervals
// - Interrupt rate can be changed by the processor
// - Interrupts can be enabled or disabled
// - Current timer value can be read through the processor bus
//
// Memory Map:
// BaseAddr + 0 : Current timer value (read)
// BaseAddr + 1 : Interrupt rate register (write)
// BaseAddr + 2 : Timer reset register (write)
// BaseAddr + 3 : Interrupt enable register (write)
//==============================================================

module Timer(
    //==========================================================
    // System signals
    //==========================================================
    input               CLK,                    // System clock
    input               RESET,                  // Active-high reset

    //==========================================================
    // Processor bus interface
    //==========================================================
    inout      [7:0]    BUS_DATA,               // Shared processor data bus
    input      [7:0]    BUS_ADDR,               // Address from processor
    input               BUS_WE,                 // Write enable from processor

    //==========================================================
    // Interrupt signals
    //==========================================================
    output              BUS_INTERRUPT_RAISE,    // Interrupt request to processor
    input               BUS_INTERRUPT_ACK       // Interrupt acknowledge from processor
);

    //==========================================================
    // Memory mapped base address for the timer
    //==========================================================
    parameter [7:0] TimerBaseAddr = 8'hF0;

    // Default interrupt rate (in milliseconds)
    parameter InitialInterruptRate   = 8'd50;

    // Interrupt enabled by default
    parameter InitialInterruptEnable = 1'b1;

    //==========================================================
    // Timer configuration registers
    //==========================================================
    reg [7:0] InterruptRate;   // Time interval between interrupts
    reg       InterruptEnable; // Enable/disable interrupt generation

    //==========================================================
    // Interrupt Rate Configuration
    // Processor can change interrupt rate using:
    // BaseAddr + 1
    //==========================================================
    always @(posedge CLK) begin
        if (RESET)
            InterruptRate <= InitialInterruptRate;
        else if ((BUS_ADDR == TimerBaseAddr + 8'h01) && BUS_WE)
            InterruptRate <= BUS_DATA;
    end

    //==========================================================
    // Interrupt Enable Configuration
    // BaseAddr + 3 controls whether interrupts are enabled
    //==========================================================
    always @(posedge CLK) begin
        if (RESET)
            InterruptEnable <= InitialInterruptEnable;
        else if ((BUS_ADDR == TimerBaseAddr + 8'h03) && BUS_WE)
            InterruptEnable <= BUS_DATA[0];
    end

    //==========================================================
    // Clock Divider
    // Converts system clock (~100 MHz) into 1 ms tick
    //==========================================================
    reg [31:0] DownCounter;

    always @(posedge CLK) begin
        if (RESET)
            DownCounter <= 32'd0;
        else begin
            if (DownCounter == 32'd99999)
                DownCounter <= 32'd0;
            else
                DownCounter <= DownCounter + 1'b1;
        end
    end

    //==========================================================
    // Timer Register
    // Counts elapsed milliseconds
    //==========================================================
    reg [31:0] TimerReg;

    always @(posedge CLK) begin
        if (RESET || ((BUS_ADDR == TimerBaseAddr + 8'h02) && BUS_WE))
            TimerReg <= 32'd0;
        else if (DownCounter == 32'd0)
            TimerReg <= TimerReg + 1'b1;
    end

    //==========================================================
    // Interrupt generation logic
    //==========================================================
    reg TargetReached;
    reg [31:0] LastTime;

    always @(posedge CLK) begin
        if (RESET) begin
            TargetReached <= 1'b0;
            LastTime      <= 32'd0;
        end
        else if (TimerReg >= (LastTime + InterruptRate)) begin
            if (InterruptEnable)
                TargetReached <= 1'b1;
            else
                TargetReached <= 1'b0;

            LastTime <= TimerReg;
        end
        else begin
            TargetReached <= 1'b0;
        end
    end

    //==========================================================
    // Interrupt flag register
    //==========================================================
    reg Interrupt;

    always @(posedge CLK) begin
        if (RESET)
            Interrupt <= 1'b0;
        else if (BUS_INTERRUPT_ACK)
            Interrupt <= 1'b0;
        else if (TargetReached)
            Interrupt <= 1'b1;
        else
            Interrupt <= Interrupt;
    end

    // Send interrupt request to processor
    assign BUS_INTERRUPT_RAISE = Interrupt;

    //==========================================================
    // Timer value read from processor bus
    //==========================================================
    reg TransmitTimerValue;

    always @(posedge CLK) begin
        if ((BUS_ADDR == TimerBaseAddr) && !BUS_WE)
            TransmitTimerValue <= 1'b1;
        else
            TransmitTimerValue <= 1'b0;
    end

    // Tri-state bus output
    assign BUS_DATA = (TransmitTimerValue) ? TimerReg[7:0] : 8'hZZ;

endmodule