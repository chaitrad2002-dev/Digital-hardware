timescale 1ns/1ps

module sepm_pulse_seq #(
    parameter int COUNTER_W = 32
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic                 arm,
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

    typedef enum logic [2:0] {
        S_IDLE      = 3'd0,
        S_DEAD_PRE  = 3'd1,
        S_PULSE     = 3'd2,
        S_DEAD_POST = 3'd3
    } state_t;

    state_t state;
    logic [COUNTER_W-1:0] count;
    logic trigger_d;
    logic polarity_latched;
    logic trigger_rise;

    assign trigger_rise = trigger & ~trigger_d;
    assign dbg_state = state;
    assign busy = (state != S_IDLE);

    always_comb begin
        in1 = 1'b0;
        in2 = 1'b0;

        if (arm && !estop && !fault && state == S_PULSE) begin
            if (polarity_latched)
                in1 = 1'b1;
            else
                in2 = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state            <= S_IDLE;
            count            <= '0;
            trigger_d        <= 1'b0;
            polarity_latched <= 1'b0;
            done             <= 1'b0;
        end else begin
            trigger_d <= trigger;
            done      <= 1'b0;

            if (!arm || estop || fault) begin
                state <= S_IDLE;
                count <= '0;
            end else begin
                case (state)
                    S_IDLE: begin
                        count <= '0;
                        if (trigger_rise) begin
                            polarity_latched <= polarity;
                            if (dead_cycles == 0) begin
                                state <= S_PULSE;
                                count <= '0;
                            end else begin
                                state <= S_DEAD_PRE;
                                count <= '0;
                            end
                        end
                    end

                    S_DEAD_PRE: begin
                        if (count + 1 >= dead_cycles) begin
                            state <= S_PULSE;
                            count <= '0;
                        end else begin
                            count <= count + 1'b1;
                        end
                    end

                    S_PULSE: begin
                        if ((pulse_cycles <= 1) || (count + 1 >= pulse_cycles)) begin
                            count <= '0;
                            if (dead_cycles == 0) begin
                                state <= S_IDLE;
                                done  <= 1'b1;
                            end else begin
                                state <= S_DEAD_POST;
                            end
                        end else begin
                            count <= count + 1'b1;
                        end
                    end

                    S_DEAD_POST: begin
                        if (count + 1 >= dead_cycles) begin
                            state <= S_IDLE;
                            count <= '0;
                            done  <= 1'b1;
                        end else begin
                            count <= count + 1'b1;
                        end
                    end

                    default: begin
                        state <= S_IDLE;
                        count <= '0;
                    end
                endcase
            end
        end
    end

endmodule
