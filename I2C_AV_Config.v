/*-------------------------------------------------------------------------
Description			:		sdram vga controller with ov7670 display.
Modification History	:
Data			By			Version			Change Description
===========================================================================
13/02/1
--------------------------------------------------------------------------*/
`timescale 1ns/1ns
module I2C_AV_Config 
(

	input  rst,
	input   iCLK,
    input clk_fast,

	
	//I2C Side
	output				I2C_SCLK,	//I2C CLOCK
	inout				I2C_SDAT,	//I2C DATA
	
	output				Config_Done//Config Done
	
);


wire req;
wire [3:0] cmd;
wire [7:0] dout;
wire done;

wire i2c_sda_i;
wire i2c_sda_o;
wire i2c_sda_oe;
cmos_config u_cfg(
    /*input               */.clk         (iCLK       ),
    /*input               */.rst_n       (rst    ),
    /*input               */.clk_fast    (clk_fast),
    //i2c_master
    /*output              */.req         (req       ),
    /*output      [3:0]   */.cmd         (cmd       ),
    /*output      [7:0]   */.dout        (dout      ),
    /*input               */.done        (done      ),
    /*output              */.config_done (Config_Done  )
);

i2c_master u_i2c(
    /*input               */.clk         (iCLK       ),
    /*input               */.rst_n       (rst     ),
    /*input               */.req         (req       ),
    /*input       [3:0]   */.cmd         (cmd       ),
    /*input       [7:0]   */.din         (dout      ),
    /*output      [7:0]   */.dout        (          ),
    /*output              */.done        (done      ),
    /*output              */.slave_ack   (          ),
    /*output              */.i2c_scl     (I2C_SCLK       ),
    /*input               */.i2c_sda_i   (i2c_sda_i ),
    /*output              */.i2c_sda_o   (i2c_sda_o ),
    /*output              */.i2c_sda_oe  (i2c_sda_oe)   
    );

    assign i2c_sda_i = I2C_SDAT;
    assign I2C_SDAT = i2c_sda_oe?i2c_sda_o:1'bz;

endmodule

