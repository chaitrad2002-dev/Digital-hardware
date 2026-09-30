module dmem256x16(
    input  logic        clk,
    input  logic        we,
    input  logic [15:0] addr,
    input  logic [15:0] wdata,
    output logic [15:0] rdata
);
    logic [15:0] mem [0:255];
    integer i;
    initial begin
        for (i=0;i<256;i=i+1) mem[i] = 16'h0000;
        mem[0] = 16'h0001;
    end
    always_ff @(posedge clk) if (we) mem[addr[7:0]] <= wdata;
    always_comb rdata = mem[addr[7:0]];
endmodule
