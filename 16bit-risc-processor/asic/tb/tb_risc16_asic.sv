`timescale 1ns/1ps
module tb_risc16_asic;
    logic clk = 1'b0;
    logic rst = 1'b1;
    logic [15:0] imem_addr, imem_rdata;
    logic dmem_we;
    logic [15:0] dmem_addr, dmem_wdata, dmem_rdata;
    logic [15:0] imem [0:255];
    logic [15:0] dmem [0:255];
    integer errors = 0;
    integer i;

    risc16_asic_top dut(
        .clk(clk), .rst(rst),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .dmem_we(dmem_we), .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata), .dmem_rdata(dmem_rdata)
    );

    always #5 clk = ~clk;
    assign imem_rdata = imem[imem_addr[7:0]];
    assign dmem_rdata = dmem[dmem_addr[7:0]];
    always_ff @(posedge clk) if (dmem_we) dmem[dmem_addr[7:0]] <= dmem_wdata;

    function automatic [15:0] enc_r(input [3:0] op,input [2:0] rd,input [2:0] rs1,input [2:0] rs2);
        enc_r = {op,rd,rs1,rs2,3'b000};
    endfunction
    function automatic [15:0] enc_mem(input [3:0] op,input [2:0] rd,input [2:0] base,input [5:0] imm6);
        enc_mem = {op,rd,base,imm6};
    endfunction
    function automatic [15:0] enc_branch(input [3:0] op,input [2:0] ra,input [2:0] rb,input [5:0] imm6);
        enc_branch = {op,ra,rb,imm6};
    endfunction
    function automatic [15:0] enc_jmp(input [11:0] addr);
        enc_jmp = {4'hC,addr};
    endfunction

    task automatic check16(input string name,input [15:0] got,input [15:0] exp);
        if (got !== exp) begin $error("FAIL %s got=%h exp=%h",name,got,exp); errors++; end
        else $display("PASS %s = %h",name,got);
    endtask

    initial begin
        for (i=0;i<256;i=i+1) begin imem[i]=enc_jmp(12'd19); dmem[i]=16'h0000; end
        dmem[0]=16'd5; dmem[1]=16'd3;
        imem[0]=enc_mem(4'h0,3'd1,3'd0,6'd0);
        imem[1]=enc_mem(4'h0,3'd2,3'd0,6'd1);
        imem[2]=enc_r(4'h2,3'd3,3'd1,3'd2);
        imem[3]=enc_r(4'h3,3'd4,3'd1,3'd2);
        imem[4]=enc_r(4'h4,3'd5,3'd2,3'd0);
        imem[5]=enc_r(4'h5,3'd6,3'd2,3'd0);
        imem[6]=enc_r(4'h6,3'd7,3'd6,3'd0);
        imem[7]=enc_r(4'h7,3'd3,3'd1,3'd2);
        imem[8]=enc_r(4'h8,3'd4,3'd1,3'd2);
        imem[9]=enc_r(4'h9,3'd5,3'd2,3'd1);
        imem[10]=enc_mem(4'h1,3'd4,3'd0,6'd2);
        imem[11]=enc_branch(4'hA,3'd2,3'd7,6'd2);
        imem[12]=enc_r(4'h2,3'd1,3'd1,3'd1);
        imem[13]=enc_r(4'h2,3'd1,3'd1,3'd1);
        imem[14]=enc_branch(4'hB,3'd1,3'd2,6'd1);
        imem[15]=enc_r(4'h3,3'd1,3'd1,3'd2);
        imem[16]=enc_jmp(12'd18);
        imem[17]=enc_r(4'h3,3'd1,3'd1,3'd2);
        imem[18]=enc_mem(4'h0,3'd6,3'd0,6'd2);
        imem[19]=enc_jmp(12'd19);

        repeat(5) @(posedge clk); rst <= 1'b0;
        repeat(180) @(posedge clk); #1;
        check16("R1",dut.u_core.u_rf.regs[1],16'd5);
        check16("R2",dut.u_core.u_rf.regs[2],16'd3);
        check16("R3",dut.u_core.u_rf.regs[3],16'd1);
        check16("R4",dut.u_core.u_rf.regs[4],16'd7);
        check16("R5",dut.u_core.u_rf.regs[5],16'd1);
        check16("R6",dut.u_core.u_rf.regs[6],16'd7);
        check16("R7",dut.u_core.u_rf.regs[7],16'd3);
        check16("DMEM2",dmem[2],16'd7);
        if (errors==0) $display("RISC16 ASIC RTL SELF-CHECK: PASS");
        else $fatal(1,"SELF-CHECK FAIL: %0d errors",errors);
        $finish;
    end
endmodule
