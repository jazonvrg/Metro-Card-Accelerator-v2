set sdc version 2.0

#setting clock = 100MHz
set CLK_PORT "PCLK"
set CLK_NAME "PCLK"
set CLK_PERIOD 10.0

create_clock -name $CLK_NAME -period $CLK_PERIOD [get_ports $CLK_PORT]

# clk uncertainty (setup / hold margin)
set_clock_uncertainty -setup 0.5 [get_clocks $CLK_NAME]
set_clock_uncertainty -hold 0.1 [get_clocks $CLK_NAME]
set_clock_transition 0.1 [get_clocks $CLK_NAME]

#Ansynchronous Reset (PRESETN)
set_false_path -from [get_ports PRESETN]

#I/O delay
set ALL_IN_EX_CLK [remove_from_collection [all_inputs] [get_ports [list $CLK_PORT PRESETN]]]

set_input_delay -max 2.5 -clock $CLK_NAME $ALL_IN_EX_CLK
set_input_delay -min 0.5 -clock $CLK_NAME $ALL_IN_EX_CLK

set_output_delay -max 2.5 -clock $CLK_NAME $ALL_IN_EX_CLK
set_output_delay -min 0.5 -clock $CLK_NAME $ALL_IN_EX_CLK

#INPUT TRANSITION VA OUTPUT CAPACITIVE GIA DINH
set_input_transition 0.1 $ALL_IN_EX_CLK
set_load 0.05 [all_outputs]
