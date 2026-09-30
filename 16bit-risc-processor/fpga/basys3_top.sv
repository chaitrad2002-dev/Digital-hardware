module basys3_top(
    input  logic        CLK100MHZ,
    input  logic        btnC,      // CPU reset
    input  logic        btnU,      // write one instruction word
    input  logic        btnD,      // reset instruction-loader address to 0
    input  logic [15:0] sw,        // loader data / debug selector
    output logic [15:0] led
);
    logic [15:0] pc, r1, ir, alu_out;
    logic [3:0]  state;
    logic [127:0] regs_flat;

    logic btnU_d;
    logic [7:0] loader_addr;
    logic prog_we;

    // Rising-edge detector for the instruction-memory programming button.
    always_ff @(posedge CLK100MHZ) begin
        if (btnC || btnD) begin
            btnU_d <= 1'b0;
            loader_addr <= 8'h00;
        end else begin
            btnU_d <= btnU;
            if (prog_we)
                loader_addr <= loader_addr + 8'd1;
        end
    end

    assign prog_we = btnU & ~btnU_d;

    risc16_soc u_soc(
        .clk(CLK100MHZ),
        .rst(btnC),
        .prog_we(prog_we),
        .prog_addr(loader_addr),
        .prog_wdata(sw),
        .dbg_pc(pc),
        .dbg_r1(r1),
        .dbg_state(state),
        .dbg_ir(ir),
        .dbg_alu_out(alu_out),
        .dbg_regs(regs_flat)
    );

    // Board debug mux. With SW[3:0]=0 (all switches down), LEDs show R1,
    // so the existing power-on demo still lights LED0.
    always_comb begin
        unique case (sw[3:0])
            4'h0: led = regs_flat[31:16];    // R1
            4'h1: led = regs_flat[47:32];    // R2
            4'h2: led = regs_flat[63:48];    // R3
            4'h3: led = regs_flat[79:64];    // R4
            4'h4: led = regs_flat[95:80];    // R5
            4'h5: led = regs_flat[111:96];   // R6
            4'h6: led = regs_flat[127:112];  // R7
            4'h7: led = pc;
            4'h8: led = ir;
            4'h9: led = alu_out;
            4'hA: led = {12'h000, state};
            4'hB: led = {8'h00, loader_addr};
            default: led = r1;
        endcase
    end
endmodule
