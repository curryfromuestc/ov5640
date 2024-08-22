	sdram_interface u0 (
		.avs_address       (<connected-to-avs_address>),       //     avs.address
		.avs_byteenable_n  (<connected-to-avs_byteenable_n>),  //        .byteenable_n
		.avs_chipselect    (<connected-to-avs_chipselect>),    //        .chipselect
		.avs_writedata     (<connected-to-avs_writedata>),     //        .writedata
		.avs_read_n        (<connected-to-avs_read_n>),        //        .read_n
		.avs_write_n       (<connected-to-avs_write_n>),       //        .write_n
		.avs_readdata      (<connected-to-avs_readdata>),      //        .readdata
		.avs_readdatavalid (<connected-to-avs_readdatavalid>), //        .readdatavalid
		.avs_waitrequest   (<connected-to-avs_waitrequest>),   //        .waitrequest
		.clk_clk           (<connected-to-clk_clk>),           //     clk.clk
		.mem_pin_addr      (<connected-to-mem_pin_addr>),      // mem_pin.addr
		.mem_pin_ba        (<connected-to-mem_pin_ba>),        //        .ba
		.mem_pin_cas_n     (<connected-to-mem_pin_cas_n>),     //        .cas_n
		.mem_pin_cke       (<connected-to-mem_pin_cke>),       //        .cke
		.mem_pin_cs_n      (<connected-to-mem_pin_cs_n>),      //        .cs_n
		.mem_pin_dq        (<connected-to-mem_pin_dq>),        //        .dq
		.mem_pin_dqm       (<connected-to-mem_pin_dqm>),       //        .dqm
		.mem_pin_ras_n     (<connected-to-mem_pin_ras_n>),     //        .ras_n
		.mem_pin_we_n      (<connected-to-mem_pin_we_n>),      //        .we_n
		.reset_reset_n     (<connected-to-reset_reset_n>)      //   reset.reset_n
	);

