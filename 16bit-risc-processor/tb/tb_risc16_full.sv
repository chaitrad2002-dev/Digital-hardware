`timescale 1ns/1ps

module tb_risc16_full;
    logic clk = 1'b0;
    logic rst = 1'b1;
    logic [15:0] pc, r1;
    logic [3:0] state;
    integer errors = 0;

    risc16_soc dut (
        .clk(clk),
        .rst(rst),
        .prog_we(1'b0),
        .prog_addr(8'h00),
        .prog_wdata(16'h0000),
        .dbg_pc(pc),
        .dbg_r1(r1),
        .dbg_state(state)
    );

    always #5 clk = ~clk; // 100 MHz

    function automatic [15:0] enc_r(
        input [3:0] op,
        input [2:0] rd,
        input [2:0] rs1,
        input [2:0] rs2
    );
        enc_r = {op, rd, rs1, rs2, 3'b000};
    endfunction

    function automatic [15:0] enc_mem(
        input [3:0] op,
        input [2:0] rd_or_src,
        input [2:0] base,
        input [5:0] imm6
    );
        enc_mem = {op, rd_or_src, base, imm6};
    endfunction

    function automatic [15:0] enc_branch(
        input [3:0] op,
        input [2:0] ra,
        input [2:0] rb,
        input [5:0] imm6
    );
        enc_branch = {op, ra, rb, imm6};
    endfunction

    function automatic [15:0] enc_jmp(input [11:0] addr);
        enc_jmp = {4'hC, addr};
    endfunction

    task automatic check16(input string name, input [15:0] got, input [15:0] exp);
        begin
            if (got !== exp) begin
                $error("FAIL %-12s got=%h expected=%h", name, got, exp);
                errors++;
            end else begin
                $display("PASS %-12s = %h", name, got);
            end
        end
    endtask

    initial begin : test_sequence
        integer i;

        // Override memories with a directed ISA test program.
        for (i = 0; i < 256; i = i + 1) begin
            dut.u_imem.mem[i] = enc_jmp(12'd19);
            dut.u_dmem.mem[i] = 16'h0000;
        end

        dut.u_dmem.mem[0] = 16'd5;
        dut.u_dmem.mem[1] = 16'd3;

        // 0: R1=5, 1: R2=3
        dut.u_imem.mem[0]  = enc_mem(4'h0, 3'd1, 3'd0, 6'd0); // LD  R1,[R0+0]
        dut.u_imem.mem[1]  = enc_mem(4'h0, 3'd2, 3'd0, 6'd1); // LD  R2,[R0+1]
        dut.u_imem.mem[2]  = enc_r(4'h2, 3'd3, 3'd1, 3'd2);   // ADD R3,R1,R2 = 8
        dut.u_imem.mem[3]  = enc_r(4'h3, 3'd4, 3'd1, 3'd2);   // SUB R4,R1,R2 = 2
        dut.u_imem.mem[4]  = enc_r(4'h4, 3'd5, 3'd2, 3'd0);   // INV R5,R2 = FFFC
        dut.u_imem.mem[5]  = enc_r(4'h5, 3'd6, 3'd2, 3'd0);   // LSL R6,R2 = 6
        dut.u_imem.mem[6]  = enc_r(4'h6, 3'd7, 3'd6, 3'd0);   // LSR R7,R6 = 3
        dut.u_imem.mem[7]  = enc_r(4'h7, 3'd3, 3'd1, 3'd2);   // AND R3,R1,R2 = 1
        dut.u_imem.mem[8]  = enc_r(4'h8, 3'd4, 3'd1, 3'd2);   // OR  R4,R1,R2 = 7
        dut.u_imem.mem[9]  = enc_r(4'h9, 3'd5, 3'd2, 3'd1);   // SLT R5,R2,R1 = 1
        dut.u_imem.mem[10] = enc_mem(4'h1, 3'd4, 3'd0, 6'd2); // ST  R4,[R0+2] -> 7
        dut.u_imem.mem[11] = enc_branch(4'hA,3'd2,3'd7,6'd2); // BEQ R2,R7 -> 14
        dut.u_imem.mem[12] = enc_r(4'h2, 3'd1,3'd1,3'd1);     // skipped
        dut.u_imem.mem[13] = enc_r(4'h2, 3'd1,3'd1,3'd1);     // skipped
        dut.u_imem.mem[14] = enc_branch(4'hB,3'd1,3'd2,6'd1); // BNE R1,R2 -> 16
        dut.u_imem.mem[15] = enc_r(4'h3, 3'd1,3'd1,3'd2);     // skipped
        dut.u_imem.mem[16] = enc_jmp(12'd18);                 // JMP 18
        dut.u_imem.mem[17] = enc_r(4'h3, 3'd1,3'd1,3'd2);     // skipped
        dut.u_imem.mem[18] = enc_mem(4'h0, 3'd6,3'd0,6'd2);   // LD R6,[2] = 7
        dut.u_imem.mem[19] = enc_jmp(12'd19);                 // stop loop

        repeat (5) @(posedge clk);
        rst <= 1'b0;

        repeat (180) @(posedge clk);
        #1;

        check16("R1", dut.u_core.u_rf.regs[1], 16'd5);
        check16("R2", dut.u_core.u_rf.regs[2], 16'd3);
        check16("R3", dut.u_core.u_rf.regs[3], 16'd1);
        check16("R4", dut.u_core.u_rf.regs[4], 16'd7);
        check16("R5", dut.u_core.u_rf.regs[5], 16'd1);
        check16("R6", dut.u_core.u_rf.regs[6], 16'd7);
        check16("R7", dut.u_core.u_rf.regs[7], 16'd3);
        check16("DMEM[2]", dut.u_dmem.mem[2], 16'd7);

        if (errors == 0)
            $display("\nRISC16 SELF-CHECK: PASS - all 13 ISA operations exercised.\n");
        else
            $fatal(1, "RISC16 SELF-CHECK: FAIL - %0d errors", errors);

        $finish;
    end

    // Basic safety checks useful in Vivado xsim.
    always @(posedge clk) begin
        if (!rst) begin
            assert (!$isunknown(pc)) else $fatal("PC contains X/Z");
            assert (!$isunknown(state)) else $fatal("FSM state contains X/Z");
            assert (state <= 4'd9) else $fatal("Illegal FSM state");
        end
    end
endmodule
