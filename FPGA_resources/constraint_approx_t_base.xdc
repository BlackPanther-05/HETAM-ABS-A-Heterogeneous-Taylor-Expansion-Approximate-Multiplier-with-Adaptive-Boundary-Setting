##############################################################
# XDC Constraint File for ZCU104
# Design: Purely Combinational Module (A1)
# Target: 1 GHz (1.0 ns)
##############################################################

# 1. Define Virtual Clock at 1 GHz
#    "Virtual" because your design is combinational - no real clock pin.
#    Do NOT attach it to any pin since there is no clock in the design.
create_clock -name virtual_clk -period 1.000

# 2. Set Input Delays for all input ports
#    Tells Vivado: data arrives 0ns after the virtual clock edge.
#    Adjust the delay value if your upstream logic adds latency.
set_input_delay -clock virtual_clk -max 0.000 [get_ports x[*]]
set_input_delay -clock virtual_clk -max 0.000 [get_ports y[*]]
set_input_delay -clock virtual_clk -max 0.000 [get_ports Conf_Bit_Mask[*]]

# 3. Set Output Delays for all output ports
#    Tells Vivado: data must arrive 0ns before the virtual clock edge.
set_output_delay -clock virtual_clk -max 0.000 [get_ports f[*]]

# 4. set_max_delay with -datapath_only
#    This is CRITICAL for combinational-only paths.
#    -datapath_only disables clock skew/jitter so Vivado measures
#    pure logic delay and reports a real WNS value.
set_max_delay -datapath_only \
              -from [get_ports x[*]] \
              -to   [get_ports f[*]] \
              1.000

set_max_delay -datapath_only \
              -from [get_ports y[*]] \
              -to   [get_ports f[*]] \
              1.000

set_max_delay -datapath_only \
              -from [get_ports Conf_Bit_Mask[*]] \
              -to   [get_ports f[*]] \
              1.000

# 5. Prevent Vivado from trimming your design during optimization
set_property DONT_TOUCH TRUE [get_cells A1]

# 6. Switching Activity for Power Analysis (Vivado Power Estimator)
set_switching_activity -default_static_probability 0.5
set_switching_activity -default_toggle_rate 0.5 [get_nets -hierarchical *]

##############################################################
# ZCU104 Board-Specific: Suppress unrelated clock warnings
# from on-board clocks that are not part of your design
##############################################################
set_false_path -from [get_clocks -quiet sys_clk*] -to [get_clocks virtual_clk]
set_false_path -from [get_clocks virtual_clk] -to [get_clocks -quiet sys_clk*]