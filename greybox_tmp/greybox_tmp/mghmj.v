//altiobuf_in CBX_SINGLE_OUTPUT_FILE="ON" enable_bus_hold="FALSE" INTENDED_DEVICE_FAMILY=""Cyclone IV E"" number_of_channels=0 use_differential_mode="FALSE" use_dynamic_termination_control="FALSE" datain dataout
//VERSION_BEGIN 20.1 cbx_mgl 2020:06:05:12:11:10:SJ cbx_stratixii 2020:06:05:12:04:51:SJ cbx_util_mgl 2020:06:05:12:04:51:SJ  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2020  Intel Corporation. All rights reserved.
//  Your use of Intel Corporation's design tools, logic functions 
//  and other software and tools, and any partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Intel Program License 
//  Subscription Agreement, the Intel Quartus Prime License Agreement,
//  the Intel FPGA IP License Agreement, or other applicable license
//  agreement, including, without limitation, that your use is for
//  the sole purpose of programming logic devices manufactured by
//  Intel and sold by Intel or its authorized distributors.  Please
//  refer to the applicable agreement for further details, at
//  https://fpgasoftware.intel.com/eula.



//synthesis_resources = altiobuf_in 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  mghmj
	( 
	datain,
	dataout) /* synthesis synthesis_clearbox=1 */;
	input   datain;
	output   dataout;

	wire  wire_mgl_prim1_dataout;

	altiobuf_in   mgl_prim1
	( 
	.datain(datain),
	.dataout(wire_mgl_prim1_dataout));
	defparam
		mgl_prim1.enable_bus_hold = "FALSE",
		mgl_prim1.intended_device_family = ""Cyclone IV E"",
		mgl_prim1.number_of_channels = 0,
		mgl_prim1.use_differential_mode = "FALSE",
		mgl_prim1.use_dynamic_termination_control = "FALSE";
	assign
		dataout = wire_mgl_prim1_dataout;
endmodule //mghmj
//VALID FILE
