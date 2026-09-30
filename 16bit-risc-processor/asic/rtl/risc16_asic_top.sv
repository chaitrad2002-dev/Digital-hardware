module risc16_asic_top(
    input  logic        clk,
    input  logic        rst,

    // Instruction SRAM / ROM macro interface
    output logic [15:0] imem_addr,
    input  logic [15:0] imem_rdata,

    // Data SRAM macro interface
    output logic        dmem_we,
    output logic [15:0] dmem_addr,
    output logic [15:0] dmem_wdata,
    input  logic [15:0] dmem_rdata
);
    // FPGA-only debug signals are intentionally not exposed at the ASIC boundary.
    logic [15:0]  dbg_pc;
    logic [15:0]  dbg_r1;
    logic [3:0]   dbg_state;
    logic [15:0]  dbg_ir;
    logic [15:0]  dbg_alu_out;
    logic [127:0] dbg_regs;

    risc16_core u_core (
        .clk(clk),
        .rst(rst),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_we(dmem_we),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata),
        .dbg_pc(dbg_pc),
        .dbg_r1(dbg_r1),
        .dbg_state(dbg_state),
        .dbg_ir(dbg_ir),
        .dbg_alu_out(dbg_alu_out),
        .dbg_regs(dbg_regs)
    );
endmodule
