timescale 1ns/1ps

module sepm_4ch_core #(
    parameter int COUNTER_W = 32
) (
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   global_arm,
    input  logic                   estop,
    input  logic                   fault,
    input  logic [3:0]             channel_enable,
    input  logic [3:0]             trigger,
    input  logic [3:0]             polarity,
    input  logic [COUNTER_W-1:0]   pulse_cycles [0:3],
    input  logic [COUNTER_W-1:0]   dead_cycles  [0:3],
    output logic [3:0]             in1,
    output logic [3:0]             in2,
    output logic [3:0]             busy,
    output logic [3:0]             done,
    output logic [2:0]             dbg_state [0:3]
);

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : g_ch
            sepm_channel #(.COUNTER_W(COUNTER_W)) u_channel (
                .clk(clk),
                .rst(rst),
                .global_arm(global_arm),
                .channel_enable(channel_enable[i]),
                .estop(estop),
                .fault(fault),
                .trigger(trigger[i]),
                .polarity(polarity[i]),
                .pulse_cycles(pulse_cycles[i]),
                .dead_cycles(dead_cycles[i]),
                .in1(in1[i]),
                .in2(in2[i]),
                .busy(busy[i]),
                .done(done[i]),
                .dbg_state(dbg_state[i])
            );
        end
    endgenerate

endmodule
