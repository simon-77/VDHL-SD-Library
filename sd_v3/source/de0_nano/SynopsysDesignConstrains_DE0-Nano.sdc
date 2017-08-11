# Synopsys Design Constraints File
# Default sdc-File for Alteras FPGAs
#######################################
# Author:	Simon Aster
# Date:		June 21, 2016
# Version:	2
#######################################

# Constrain clock port clk with a 20-ns periode
create_clock -name {clk} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk}]

derive_clock_uncertainty

# Automatically apply a generate clock on the output of phase-locked loops (PLLs)
# This command can be safely left in the SDC even if no PLLs exist in the design
derive_pll_clocks

# Constrain the input I/O path
set_input_delay -clock clk -max 3 [all_inputs]
set_input_delay -clock clk -min 2 [all_inputs]

# Constrain the output I/O path
set_output_delay -clock clk -max 3 [all_outputs]
set_output_delay -clock clk -min 2 [all_outputs]
