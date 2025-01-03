transcript on
if ![file isdirectory verilog_libs] {
	file mkdir verilog_libs
}

vlib verilog_libs/altera_ver
vmap altera_ver ./verilog_libs/altera_ver
vlog -vlog01compat -work altera_ver {c:/intelfpga/18.1/quartus/eda/sim_lib/altera_primitives.v}

vlib verilog_libs/lpm_ver
vmap lpm_ver ./verilog_libs/lpm_ver
vlog -vlog01compat -work lpm_ver {c:/intelfpga/18.1/quartus/eda/sim_lib/220model.v}

vlib verilog_libs/sgate_ver
vmap sgate_ver ./verilog_libs/sgate_ver
vlog -vlog01compat -work sgate_ver {c:/intelfpga/18.1/quartus/eda/sim_lib/sgate.v}

vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver ./verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver {c:/intelfpga/18.1/quartus/eda/sim_lib/altera_mf.v}

vlib verilog_libs/altera_lnsim_ver
vmap altera_lnsim_ver ./verilog_libs/altera_lnsim_ver
vlog -sv -work altera_lnsim_ver {c:/intelfpga/18.1/quartus/eda/sim_lib/altera_lnsim.sv}

vlib verilog_libs/cycloneive_ver
vmap cycloneive_ver ./verilog_libs/cycloneive_ver
vlog -vlog01compat -work cycloneive_ver {c:/intelfpga/18.1/quartus/eda/sim_lib/cycloneive_atoms.v}

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/nfca_controller {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/nfca_controller/nfca_tx_modulate.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/nfca_controller {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/nfca_controller/nfca_tx_frame.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/nfca_controller {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/nfca_controller/nfca_rx_tobytes.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/nfca_controller {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/nfca_controller/nfca_rx_tobits.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/nfca_controller {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/nfca_controller/nfca_rx_dsp_bak.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/nfca_controller {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/nfca_controller/nfca_controller.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/uart2nfca_system_top.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/uart_tx.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/uart_rx_parser.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/uart_rx.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/fpga_top.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/fifo_sync.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL {C:/Users/Dell/Desktop/FPGA_NFC_HR/RTL/ad7276_read_bak.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/PRJ/ip {C:/Users/Dell/Desktop/FPGA_NFC_HR/PRJ/ip/PLL.v}
vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/PRJ/db {C:/Users/Dell/Desktop/FPGA_NFC_HR/PRJ/db/pll_altpll.v}

vlog -vlog01compat -work work +incdir+C:/Users/Dell/Desktop/FPGA_NFC_HR/PRJ/../SIM {C:/Users/Dell/Desktop/FPGA_NFC_HR/PRJ/../SIM/tb_ad7276_read.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  tb_ad7276_read

add wave *
view structure
view signals
run -all
