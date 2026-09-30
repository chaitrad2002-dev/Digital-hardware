`timescale 1ns / 1ps

module Processor_System_top_TB;

    // Inputs
    reg CLK100MHZ;
    reg RESET;

    // Outputs
    wire VGA_HS;
    wire VGA_VS;
    wire [3:0] VGA_R;
    wire [3:0] VGA_G;
    wire [3:0] VGA_B;

    // Instantiate DUT
    Processor_System_Top DUT (
        .CLK100MHZ (CLK100MHZ),
        .RESET     (RESET),
        .VGA_HS    (VGA_HS),
        .VGA_VS    (VGA_VS),
        .VGA_R     (VGA_R),
        .VGA_G     (VGA_G),
        .VGA_B     (VGA_B)
    );

    // 100MHz clock - 10ns period
    initial CLK100MHZ = 0;
    always #5 CLK100MHZ = ~CLK100MHZ;

    // Simulation
    initial begin
        // Reset
        RESET = 1;
        repeat(20) @(posedge CLK100MHZ);
        RESET = 0;

        $display("Reset released at time %0t", $time);
        $display("Processor starting...");

        // Run for enough cycles to complete draw_screen
        // draw_screen writes 256*128 = 32768 pixels
        // Each write takes ~8 cycles minimum
        // So ~300000 cycles needed
        repeat(500000) @(posedge CLK100MHZ);

        $display("Time %0t: VGA_R=%b VGA_G=%b VGA_B=%b", $time, VGA_R, VGA_G, VGA_B);
        $display("Time %0t: VGA_HS=%b VGA_VS=%b", $time, VGA_HS, VGA_VS);

        // Run more to see colour swap after timer interrupt
        $display("Waiting for timer interrupt (~100ms = 10,000,000 cycles)...");
        repeat(10000000) @(posedge CLK100MHZ);

        $display("Time %0t: After timer - VGA_R=%b VGA_G=%b VGA_B=%b", $time, VGA_R, VGA_G, VGA_B);

        $display("Simulation complete.");
        $finish;
    end

    // Monitor bus activity
    initial begin
        $monitor("Time %0t: BUS_ADDR=%h BUS_WE=%b VGA_HS=%b VGA_VS=%b R=%h G=%h B=%h",
            $time,
            DUT.BUS_ADDR,
            DUT.BUS_WE,
            VGA_HS,
            VGA_VS,
            VGA_R,
            VGA_G,
            VGA_B);
    end

endmodule
