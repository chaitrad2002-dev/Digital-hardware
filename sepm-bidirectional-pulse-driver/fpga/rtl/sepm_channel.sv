timescale 1ns/1ps

module sepm_channel #(
    parameter int COUNTER_W = 32
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic                 global_arm,
    input  logic                 channel_enable,
    input  logic                 estop,
    input  logic                 fault,
    input  logic                 trigger,
    input  logic                 polarity,
    input  logic [COUNTER_W-1:0] pulse_cycles,
    input  logic [COUNTER_W-1:0] dead_cycles,
    output logic                 in1,
    output logic                 in2,
    output logic                 busy,
    output logic                 done,
    output logic [2:0]           dbg_state
);

    logic local_arm;
    assign local_arm = global_arm & channel_enable;

    sepm_pulse_seq #(.COUNTER_W(COUNTER_W)) u_seq (
        .clk(clk),
        .rst(rst),
        .arm(local_arm),
        .estop(estop),
        .fault(fault),
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

endmodule
