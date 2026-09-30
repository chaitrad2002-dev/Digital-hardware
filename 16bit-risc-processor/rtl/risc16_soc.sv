module risc16_soc(
    input  logic         clk,
    input  logic         rst,
    input  logic         prog_we,
    input  logic [7:0]   prog_addr,
    input  logic [15:0]  prog_wdata,
    output logic [15:0]  dbg_pc,
    output logic [15:0]  dbg_r1,
    output logic [3:0]   dbg_state,
    output logic [15:0]  dbg_ir,
    output logic [15:0]  dbg_alu_out,
    output logic [127:0] dbg_regs
);
    logic [15:0] ia, id, da, dw, dr;
    logic dwe;

    imem256x16 u_imem(
        .clk(clk),
        .prog_we(prog_we),
        .prog_addr(prog_addr),
        .prog_wdata(prog_wdata),
        .addr(ia),
        .rdata(id)
    );

    dmem256x16 u_dmem(
        .clk(clk), .we(dwe), .addr(da), .wdata(dw), .rdata(dr)
    );

    risc16_core u_core(
        .clk(clk), .rst(rst),
        .imem_addr(ia), .imem_rdata(id),
        .dmem_we(dwe), .dmem_addr(da), .dmem_wdata(dw), .dmem_rdata(dr),
        .dbg_pc(dbg_pc), .dbg_r1(dbg_r1), .dbg_state(dbg_state),
        .dbg_ir(dbg_ir), .dbg_alu_out(dbg_alu_out), .dbg_regs(dbg_regs)
    );
endmodule
