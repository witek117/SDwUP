connect -url tcp:127.0.0.1:3121
source C:/Witek/huffmann/proba4/proba4.sdk/cotex_design_wrapper_hw_platform_0/ps7_init.tcl
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent Zed 210248531645"} -index 0
loadhw C:/Witek/huffmann/proba4/proba4.sdk/cotex_design_wrapper_hw_platform_0/system.hdf
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent Zed 210248531645"} -index 0
stop
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Zed 210248531645"} -index 0
rst -processor
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Zed 210248531645"} -index 0
dow C:/Witek/huffmann/proba4/proba4.sdk/uart_cpp/Debug/uart_cpp.elf
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Zed 210248531645"} -index 0
con
