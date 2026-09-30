timescale 1ns/1ps

module basys3_sepm_top (
    input  logic        CLK100MHZ,
    input  logic        btnC,
    input  logic        btnU,
    input  logic        btnD,
    input  logic        btnL,
    input  logic        btnR,
    input  logic [15:0] sw,
    output logic [15:0] led,
    output logic [7:0]  sepm_out
);

    localparam logic [31:0] PULSE_1MS = 32'd100_000;
    localparam logic [31:0] DEAD_1US  = 32'd100;

    logic [3:0] trigger;
    logic [3:0] polarity;
    logic [3:0] channel_enable;
    logic [3:0] in1, in2, busy, done;
    logic [2:0] dbg_state [0:3];
    logic [31:0] pulse_cycles [0:3];
    logic [31:0] dead_cycles  [0:3];

    assign trigger        = {btnR, btnL, btnD, btnU};
    assign polarity       = sw[7:4];
    assign channel_enable = sw[3:0];

    always_comb begin
        pulse_cycles[0] = PULSE_1MS;
        pulse_cycles[1] = PULSE_1MS;
        pulse_cycles[2] = PULSE_1MS;
        pulse_cycles[3] = PULSE_1MS;
        dead_cycles[0]  = DEAD_1US;
        dead_cycles[1]  = DEAD_1US;
        dead_cycles[2]  = DEAD_1US;
        dead_cycles[3]  = DEAD_1US;
    end

    sepm_4ch_core u_core (
        .clk(CLK100MHZ),
        .rst(btnC),
        .global_arm(sw[15]),
        .estop(sw[13]),
        .fault(sw[14]),
        .channel_enable(channel_enable),
        .trigger(trigger),
        .polarity(polarity),
        .pulse_cycles(pulse_cycles),
        .dead_cycles(dead_cycles),
        .in1(in1),
        .in2(in2),
        .busy(busy),
        .done(done),
        .dbg_state(dbg_state)
    );

    assign sepm_out = {
        in2[3], in1[3],
        in2[2], in1[2],
        in2[1], in1[1],
        in2[0], in1[0]
    };

    assign led[3:0]   = busy;
    assign led[7:4]   = done;
    assign led[11:8]  = in1;
    assign led[15:12] = in2;

endmodule
