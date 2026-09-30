`timescale 1ns / 1ps

module VGA_Interface_tb;

    reg        CLK100MHZ;
    reg        RESET;
    reg  [7:0] BUS_ADDR;
    reg        BUS_WE;
    reg  [7:0] cpu_bus_out;
    reg        cpu_bus_drive;

    wire [7:0] BUS_DATA;

    wire       VGA_HS;
    wire       VGA_VS;
    wire [3:0] VGA_R;
    wire [3:0] VGA_G;
    wire [3:0] VGA_B;

    // shared tristate bus
    assign BUS_DATA = (cpu_bus_drive) ? cpu_bus_out : 8'hZZ;

    VGA_Interface DUT (
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

    // 100 MHz clock
    initial begin
        CLK100MHZ = 1'b0;
        forever #5 CLK100MHZ = ~CLK100MHZ;
    end

    // bus write task
    task bus_write;
        input [7:0] addr;
        input [7:0] data;
        begin
            @(posedge CLK100MHZ);
            BUS_ADDR      <= addr;
            cpu_bus_out   <= data;
            cpu_bus_drive <= 1'b1;
            BUS_WE        <= 1'b1;

            @(posedge CLK100MHZ);
            BUS_WE        <= 1'b0;
            cpu_bus_drive <= 1'b0;
            BUS_ADDR      <= 8'h00;
        end
    endtask

    initial begin
        RESET         = 1'b1;
        BUS_ADDR      = 8'h00;
        BUS_WE        = 1'b0;
        cpu_bus_out   = 8'h00;
        cpu_bus_drive = 1'b0;

        repeat(5) @(posedge CLK100MHZ);
        RESET = 1'b0;

        $display("---- VGA INTERFACE TB START ----");

        // -------------------------------------------------
        // Test 1: write X_reg through B0
        // -------------------------------------------------
        bus_write(8'hB0, 8'd10);
        @(posedge CLK100MHZ);

        if (DUT.X_reg == 8'd10)
            $display("PASS: X_reg updated to %0d", DUT.X_reg);
        else
            $display("FAIL: X_reg = %0d, expected 10", DUT.X_reg);

        // -------------------------------------------------
        // Test 2: write Y_reg through B1
        // -------------------------------------------------
        bus_write(8'hB1, 8'd20);
        @(posedge CLK100MHZ);

        if (DUT.Y_reg == 7'd20)
            $display("PASS: Y_reg updated to %0d", DUT.Y_reg);
        else
            $display("FAIL: Y_reg = %0d, expected 20", DUT.Y_reg);

        // -------------------------------------------------
        // Test 3: write one pixel at (X,Y)
        // B2 with bit7=0, bit0 = pixel value
        // -------------------------------------------------
        bus_write(8'hB2, 8'h01);   // pixel = 1
        @(posedge CLK100MHZ);

        if (DUT.FB.Mem[{DUT.Y_reg, DUT.X_reg}] == 1'b1)
            $display("PASS: framebuffer pixel set at address %0d", {DUT.Y_reg, DUT.X_reg});
        else
            $display("FAIL: framebuffer pixel not set correctly");

        // -------------------------------------------------
        // Test 4: clear same pixel
        // -------------------------------------------------
        bus_write(8'hB2, 8'h00);   // pixel = 0
        @(posedge CLK100MHZ);

        if (DUT.FB.Mem[{DUT.Y_reg, DUT.X_reg}] == 1'b0)
            $display("PASS: framebuffer pixel cleared");
        else
            $display("FAIL: framebuffer pixel not cleared");

        // -------------------------------------------------
        // Test 5: update FG colour
        // B0 = colour value, B2 = 81
        // -------------------------------------------------
        bus_write(8'hB0, 8'hE0);
        bus_write(8'hB2, 8'h81);
        @(posedge CLK100MHZ);

        if (DUT.FG_reg == 8'hE0)
            $display("PASS: FG_reg updated to %h", DUT.FG_reg);
        else
            $display("FAIL: FG_reg = %h, expected E0", DUT.FG_reg);

        // -------------------------------------------------
        // Test 6: update BG colour
        // B0 = colour value, B2 = 80
        // -------------------------------------------------
        bus_write(8'hB0, 8'h1C);
        bus_write(8'hB2, 8'h80);
        @(posedge CLK100MHZ);

        if (DUT.BG_reg == 8'h1C)
            $display("PASS: BG_reg updated to %h", DUT.BG_reg);
        else
            $display("FAIL: BG_reg = %h, expected 1C", DUT.BG_reg);

        // Optional: let VGA timing run a bit
        repeat(200) @(posedge CLK100MHZ);

        $display("---- VGA INTERFACE TB END ----");
        $stop;
    end

endmodule