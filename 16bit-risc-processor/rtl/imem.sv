module imem256x16(
    input  logic        clk,
    input  logic        prog_we,
    input  logic [7:0]  prog_addr,
    input  logic [15:0] prog_wdata,
    input  logic [15:0] addr,
    output logic [15:0] rdata
);
    // Writable instruction memory keeps the CPU generic during FPGA synthesis.
    // The initial contents still provide the simple power-on demo program.
    logic [15:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 16'hC000; // JMP 0 default

        // Default hardware demo:
        //   0: LD  R1,[R0+0]
        //   1: JMP 1
        mem[0] = 16'h0200;
        mem[1] = 16'hC001;
    end

    // Runtime programming port. Because instructions may change after
    // configuration, synthesis cannot specialize the processor to one ROM image.
    always_ff @(posedge clk) begin
        if (prog_we)
            mem[prog_addr] <= prog_wdata;
    end

    always_comb begin
        rdata = mem[addr[7:0]];
    end
endmodule
