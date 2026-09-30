module alu16(
    input  logic [3:0]  op,
    input  logic [15:0] a,
    input  logic [15:0] b,
    output logic [15:0] y
);
    localparam logic [3:0] OP_ADD = 4'h2, OP_SUB = 4'h3, OP_INV = 4'h4,
                           OP_LSL = 4'h5, OP_LSR = 4'h6, OP_AND = 4'h7,
                           OP_OR  = 4'h8, OP_SLT = 4'h9;
    always_comb begin
        unique case (op)
            OP_ADD: y = a + b;
            OP_SUB: y = a - b;
            OP_INV: y = ~a;
            OP_LSL: y = a << 1;
            OP_LSR: y = a >> 1;
            OP_AND: y = a & b;
            OP_OR : y = a | b;
            OP_SLT: y = ($signed(a) < $signed(b)) ? 16'h0001 : 16'h0000;
            default: y = 16'h0000;
        endcase
    end
endmodule
