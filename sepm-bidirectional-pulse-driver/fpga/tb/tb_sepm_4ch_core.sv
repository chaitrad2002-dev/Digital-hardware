`timescale 1ns/1ps

module tb_sepm_4ch_core;

    localparam int COUNTER_W = 32;
    localparam int TEST_PULSE = 8;
    localparam int TEST_DEAD  = 3;

    logic clk = 1'b0;
    logic rst = 1'b1;
    logic global_arm = 1'b0;
    logic estop = 1'b0;
    logic fault = 1'b0;
    logic [3:0] channel_enable = 4'b1111;
    logic [3:0] trigger = 4'b0000;
    logic [3:0] polarity = 4'b0000;
    logic [COUNTER_W-1:0] pulse_cycles [0:3];
    logic [COUNTER_W-1:0] dead_cycles [0:3];
    logic [3:0] in1, in2, busy, done;
    logic [2:0] dbg_state [0:3];

    integer errors = 0;
    integer i;

    always #5 clk = ~clk; // 100 MHz

    sepm_4ch_core #(.COUNTER_W(COUNTER_W)) dut (
        .clk(clk),
        .rst(rst),
        .global_arm(global_arm),
        .estop(estop),
        .fault(fault),
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

    task automatic pulse_trigger(input int ch);
        begin
            @(negedge clk);
            trigger[ch] = 1'b1;
            @(negedge clk);
            trigger[ch] = 1'b0;
        end
    endtask

    task automatic check_no_illegal_bridge;
        begin
            for (int k = 0; k < 4; k++) begin
                if (in1[k] && in2[k]) begin
                    $error("Illegal bridge state on channel %0d", k);
                    errors++;
                end
            end
        end
    endtask

    task automatic wait_for_pulse_and_check(input int ch, input bit forward);
        integer high_cycles;
        begin
            high_cycles = 0;
            wait (busy[ch] === 1'b1);
            wait ((in1[ch] || in2[ch]) === 1'b1);
            while (in1[ch] || in2[ch]) begin
                @(posedge clk);
                #1;
                high_cycles++;
                check_no_illegal_bridge();
                if (forward && !in1[ch]) begin
                    $error("CH%0d expected forward IN1 high", ch);
                    errors++;
                end
                if (!forward && !in2[ch]) begin
                    $error("CH%0d expected reverse IN2 high", ch);
                    errors++;
                end
            end
            if (high_cycles != TEST_PULSE) begin
                $error("CH%0d pulse width = %0d cycles, expected %0d", ch, high_cycles, TEST_PULSE);
                errors++;
            end
            wait (busy[ch] === 1'b0);
        end
    endtask

    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            pulse_cycles[i] = TEST_PULSE;
            dead_cycles[i]  = TEST_DEAD;
        end

        repeat (5) @(posedge clk);
        rst = 1'b0;
        global_arm = 1'b1;

        for (i = 0; i < 4; i = i + 1) begin
            polarity[i] = 1'b1;
            fork
                pulse_trigger(i);
                wait_for_pulse_and_check(i, 1'b1);
            join
        end

        for (i = 0; i < 4; i = i + 1) begin
            polarity[i] = 1'b0;
            fork
                pulse_trigger(i);
                wait_for_pulse_and_check(i, 1'b0);
            join
        end

        polarity = 4'b0101;
        @(negedge clk);
        trigger = 4'b1111;
        @(negedge clk);
        trigger = 4'b0000;
        wait (&busy);
        wait ((|(in1 | in2)) === 1'b1);
        repeat (TEST_PULSE) begin
            @(posedge clk); #1;
            check_no_illegal_bridge();
            if (!(in1[0] && in2[1] && in1[2] && in2[3])) begin
                $error("Mixed-polarity simultaneous output mismatch");
                errors++;
            end
        end
        wait (busy == 4'b0000);

        polarity[0] = 1'b1;
        fork
            begin
                pulse_trigger(0);
                wait (in1[0]);
                repeat (2) @(posedge clk);
                pulse_trigger(0);
            end
            wait_for_pulse_and_check(0, 1'b1)
        join

        polarity[1] = 1'b1;
        pulse_trigger(1);
        wait (in1[1] === 1'b1);
        #2 estop = 1'b1;
        #1;
        if (in1[1] !== 1'b0 || in2[1] !== 1'b0) begin
            $error("ESTOP did not force CH1 outputs low immediately");
            errors++;
        end
        @(posedge clk); #1;
        if (busy[1] !== 1'b0) begin
            $error("ESTOP did not abort CH1 busy state");
            errors++;
        end
        estop = 1'b0;

        polarity[2] = 1'b0;
        pulse_trigger(2);
        wait (in2[2] === 1'b1);
        #2 fault = 1'b1;
        #1;
        if ((|in1) || (|in2)) begin
            $error("FAULT did not force all outputs low immediately");
            errors++;
        end
        @(posedge clk); #1;
        fault = 1'b0;

        channel_enable[3] = 1'b0;
        pulse_trigger(3);
        repeat (10) @(posedge clk);
        if (busy[3] || in1[3] || in2[3]) begin
            $error("Disabled channel 3 responded to trigger");
            errors++;
        end

        if (errors == 0)
            $display("SEPM 4CH SELF-CHECK: PASS");
        else
            $display("SEPM 4CH SELF-CHECK: FAIL (%0d errors)", errors);

        $finish;
    end

    always @(posedge clk) begin
        if (!rst) begin
            assert (!(in1[0] && in2[0]));
            assert (!(in1[1] && in2[1]));
            assert (!(in1[2] && in2[2]));
            assert (!(in1[3] && in2[3]));
        end
    end

endmodule
