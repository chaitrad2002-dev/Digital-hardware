# RISC16 ASIC front-end timing assumptions
# Target frequency: 100 MHz (10 ns period), matching the FPGA implementation target.
create_clock -name clk -period 10.000 [get_ports clk]

# Preliminary front-end margins. These are assumptions, not package/board requirements.
set_clock_uncertainty 0.200 [get_clocks clk]
set_input_delay  1.000 -clock [get_clocks clk] [get_ports {rst imem_rdata[*] dmem_rdata[*]}]
set_output_delay 1.000 -clock [get_clocks clk] [get_ports {imem_addr[*] dmem_we dmem_addr[*] dmem_wdata[*]}]

# Keep the clock ideal for pre-layout STA. CTS/post-route analysis comes later.
