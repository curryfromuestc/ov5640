transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/debug_mux.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/cout.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/uart_watcher.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/sensor_filter.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/capture.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/cmos_config.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/I2C_AV_Config.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/top_design.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/UART_CONTROLLER.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/sdram_controller.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/pll1.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/wrfifo.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/cmos_in.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/transWH.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670/db {E:/FPGA_PROJECT/ALTERA/ov7670/db/pll1_altpll.v}
vlog -vlog01compat -work work +incdir+E:/FPGA_PROJECT/ALTERA/ov7670 {E:/FPGA_PROJECT/ALTERA/ov7670/i2c_master.v}
vlib sdram_interface
vmap sdram_interface sdram_interface
vlog -vlog01compat -work sdram_interface +incdir+e:/fpga_project/altera/ov7670/db/ip/sdram_interface {e:/fpga_project/altera/ov7670/db/ip/sdram_interface/sdram_interface.v}
vlog -vlog01compat -work sdram_interface +incdir+e:/fpga_project/altera/ov7670/db/ip/sdram_interface/submodules {e:/fpga_project/altera/ov7670/db/ip/sdram_interface/submodules/altera_reset_controller.v}
vlog -vlog01compat -work sdram_interface +incdir+e:/fpga_project/altera/ov7670/db/ip/sdram_interface/submodules {e:/fpga_project/altera/ov7670/db/ip/sdram_interface/submodules/altera_reset_synchronizer.v}
vlog -vlog01compat -work sdram_interface +incdir+e:/fpga_project/altera/ov7670/db/ip/sdram_interface/submodules {e:/fpga_project/altera/ov7670/db/ip/sdram_interface/submodules/sdram_interface_new_sdram_controller_0.v}

