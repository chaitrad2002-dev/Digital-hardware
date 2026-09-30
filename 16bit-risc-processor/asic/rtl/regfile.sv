module regfile8x16(
    input  logic         clk,
    input  logic         rst,
    input  logic         we,
    input  logic [2:0]   waddr,
    input  logic [15:0]  wdata,
    input  logic [2:0]   raddr1,
    input  logic [2:0]   raddr2,
    output logic [15:0]  rdata1,
    output logic [15:0]  rdata2,
    output logic [127:0] dbg_regs
);
    logic [15:0] regs [0:7];
    integer i;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 16'h0000;
        end else if (we && (waddr != 3'd0)) begin
            regs[waddr] <= wdata;
        end
    end

    always_comb begin
        rdata1 = (raddr1 == 3'd0) ? 16'h0000 : regs[raddr1];
        rdata2 = (raddr2 == 3'd0) ? 16'h0000 : regs[raddr2];
    end

    // Full register-file observability for on-board debug.
    assign dbg_regs = {regs[7], regs[6], regs[5], regs[4],
                       regs[3], regs[2], regs[1], regs[0]};
endmodule
