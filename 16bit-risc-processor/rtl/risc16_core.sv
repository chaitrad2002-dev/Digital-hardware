module risc16_core(
    input  logic        clk,
    input  logic        rst,
    output logic [15:0] imem_addr,
    input  logic [15:0] imem_rdata,
    output logic        dmem_we,
    output logic [15:0] dmem_addr,
    output logic [15:0] dmem_wdata,
    input  logic [15:0] dmem_rdata,
    output logic [15:0] dbg_pc,
    output logic [15:0] dbg_r1,
    output logic [3:0]  dbg_state,
    output logic [15:0] dbg_ir,
    output logic [15:0] dbg_alu_out,
    output logic [127:0] dbg_regs
);
    localparam logic [3:0] OP_LD  = 4'h0, OP_ST  = 4'h1, OP_ADD = 4'h2,
                           OP_SUB = 4'h3, OP_INV = 4'h4, OP_LSL = 4'h5,
                           OP_LSR = 4'h6, OP_AND = 4'h7, OP_OR  = 4'h8,
                           OP_SLT = 4'h9, OP_BEQ = 4'hA, OP_BNE = 4'hB,
                           OP_JMP = 4'hC;

    typedef enum logic [3:0] {
        S_FETCH=4'd0, S_DECODE=4'd1, S_EXEC_R=4'd2, S_WB_R=4'd3,
        S_ADDR=4'd4, S_MEM_RD=4'd5, S_MEM_WB=4'd6, S_MEM_WR=4'd7,
        S_BRANCH=4'd8, S_JUMP=4'd9
    } state_t;

    state_t state, next_state;
    logic [15:0] pc, ir, alu_out, mdr;
    logic [3:0] opcode;
    logic [2:0] rd, rs1, rs2;
    logic [2:0] rf_raddr1, rf_raddr2;
    logic [15:0] rdata1, rdata2, alu_y;
    logic [15:0] sext_imm6;
    logic rf_we;
    logic [2:0] rf_waddr;
    logic [15:0] rf_wdata;
    logic [15:0] branch_target;

    assign opcode = ir[15:12];
    assign rd  = ir[11:9];
    assign rs1 = ir[8:6];
    assign rs2 = ir[5:3];
    assign rf_raddr1 = ((opcode == OP_BEQ) || (opcode == OP_BNE)) ? ir[11:9] : ir[8:6];
    assign rf_raddr2 = ((opcode == OP_BEQ) || (opcode == OP_BNE)) ? ir[8:6] :
                       (opcode == OP_ST) ? ir[11:9] : ir[5:3];
    assign sext_imm6 = {{10{ir[5]}}, ir[5:0]};
    assign branch_target = pc + sext_imm6;
    assign imem_addr = pc;
    assign dbg_pc = pc;
    assign dbg_state = state;
    assign dbg_ir = ir;
    assign dbg_alu_out = alu_out;
    assign dbg_r1 = dbg_regs[31:16];

    regfile8x16 u_rf(
        .clk(clk), .rst(rst), .we(rf_we), .waddr(rf_waddr), .wdata(rf_wdata),
        .raddr1(rf_raddr1), .raddr2(rf_raddr2), .rdata1(rdata1), .rdata2(rdata2), .dbg_regs(dbg_regs)
    );

    alu16 u_alu(.op(opcode), .a(rdata1), .b(rdata2), .y(alu_y));

    always_comb begin
        next_state = S_FETCH;
        unique case (state)
            S_FETCH:  next_state = S_DECODE;
            S_DECODE: begin
                unique case (opcode)
                    OP_LD, OP_ST: next_state = S_ADDR;
                    OP_BEQ, OP_BNE: next_state = S_BRANCH;
                    OP_JMP: next_state = S_JUMP;
                    default: next_state = S_EXEC_R;
                endcase
            end
            S_EXEC_R: next_state = S_WB_R;
            S_WB_R:   next_state = S_FETCH;
            S_ADDR:   next_state = (opcode == OP_LD) ? S_MEM_RD : S_MEM_WR;
            S_MEM_RD: next_state = S_MEM_WB;
            S_MEM_WB: next_state = S_FETCH;
            S_MEM_WR: next_state = S_FETCH;
            S_BRANCH: next_state = S_FETCH;
            S_JUMP:   next_state = S_FETCH;
            default:  next_state = S_FETCH;
        endcase
    end

    always_comb begin
        rf_we = 1'b0;
        rf_waddr = rd;
        rf_wdata = alu_out;
        dmem_we = 1'b0;
        dmem_addr = alu_out;
        dmem_wdata = rdata2;
        if (state == S_WB_R) begin
            rf_we = 1'b1;
            rf_wdata = alu_out;
        end else if (state == S_MEM_WB) begin
            rf_we = 1'b1;
            rf_wdata = mdr;
        end else if (state == S_MEM_WR) begin
            dmem_we = 1'b1;
            dmem_wdata = rdata2;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= S_FETCH;
            pc <= 16'h0000;
            ir <= 16'h0000;
            alu_out <= 16'h0000;
            mdr <= 16'h0000;
        end else begin
            state <= next_state;
            unique case (state)
                S_FETCH: begin
                    ir <= imem_rdata;
                    pc <= pc + 16'd1;
                end
                S_EXEC_R: alu_out <= alu_y;
                S_ADDR: alu_out <= rdata1 + sext_imm6;
                S_MEM_RD: mdr <= dmem_rdata;
                S_BRANCH: begin
                    if ((opcode == OP_BEQ && rdata1 == rdata2) ||
                        (opcode == OP_BNE && rdata1 != rdata2))
                        pc <= branch_target;
                end
                S_JUMP: pc <= {4'h0, ir[11:0]};
                default: ;
            endcase
        end
    end
endmodule
