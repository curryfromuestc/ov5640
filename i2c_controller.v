/*-------------------------------------------------------------------------
===========================================================================
15/02/1
--------------------------------------------------------------------------*/
`timescale 1ns/1ns
module I2C_Controller 
(
	input rst,
	input sys_clock,
	input [7:0] I2C_addr,
	input [23:0] I2C_WDATA,

	input go,
	output reg clk_line,
	output reg sda_line,
	output reg trans_finished

);

always @(posedge sys_clock or negedge rst)
	begin
		if (!rst)
			begin
				clk_line <= 1'bz;
				sda_line <= 1'bz;
			end
		else
		begin
			if (clk_line_buf == 1'b0)
				clk_line <= 1'b0;
			else
				clk_line <= 1'bz;

			if (sda_line_buf == 1'b0)
				sda_line <= 1'b0;
			else
				sda_line <= 1'bz;
		end
	end

reg sda_line_buf;
reg clk_line_buf;

reg i2c_clk_line;
reg [10:0] i2c_clk_counter;

parameter i2c_clk_freq = 800000;
parameter sys_clock_freq = 25000000;

//generate start signal

reg go_last;
always @(posedge sys_clock or negedge rst)
	begin
		if (!rst)
			go_last <= 1'b0;
		else 
			go_last <= go;
	end

wire start = !go_last & go;



//创建�??个两倍于I2C频率的时�??
always @(posedge sys_clock or negedge rst)
	begin
		if (!rst)
			begin
				i2c_clk_counter <= 11'b0;
				i2c_clk_line <= 1'b0;
			end
		else if (!go || trans_finished )
			begin
				i2c_clk_counter <= 11'b0;
				i2c_clk_line <= 1'b0;
			end
		else
			begin
				if (i2c_clk_counter == (sys_clock_freq/i2c_clk_freq/2)-1)
					begin
						i2c_clk_line <= ~i2c_clk_line;
						i2c_clk_counter <= 11'b0;
					end
				else
					i2c_clk_counter <= i2c_clk_counter + 11'b1;
			end
	end

reg [7:0] i2c_counter;

always @(posedge start or posedge i2c_clk_line or negedge rst)
	begin
		if (!rst)
		begin
			i2c_counter <= 8'b0;
			sda_line_buf <= 1'b1;
			clk_line_buf <= 1'b1;
			trans_finished <= 1'b1;
		end
			
		else if (start)
		begin
			i2c_counter <= 8'b0;
			sda_line_buf <= 1'b0;
			clk_line_buf <= 1'b1;
			trans_finished <= 1'b0;
		end

		else
		begin
			case (i2c_counter)
				8'd0: begin
					sda_line_buf <= 1'b0;
					clk_line_buf <= 1'b1;
					i2c_counter <= i2c_counter + 8'd1;
				end
				8'd1: begin
					sda_line_buf <= 1'b0;
					clk_line_buf <= 1'b1;i2c_counter <= i2c_counter + 8'd1;
				end
				8'd2: begin
					sda_line_buf <= 1'b0;
					clk_line_buf <= 1'b1;i2c_counter <= i2c_counter + 8'd1;
				end
				8'd3: begin
					sda_line_buf <= 1'b0;
					clk_line_buf <= 1'b1;i2c_counter <= i2c_counter + 8'd1;
				end

				8'd4: begin
					sda_line_buf <= 1'b0;
					clk_line_buf <= 1'b0;i2c_counter <= i2c_counter + 8'd1;
				end

				8'd5: begin
					sda_line_buf <= I2C_addr[7];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd9: begin
					sda_line_buf <= I2C_addr[6];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd13: begin
					sda_line_buf <= I2C_addr[5];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd17: begin
					sda_line_buf <= I2C_addr[4];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd21: begin
					sda_line_buf <= I2C_addr[3];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd25: begin
					sda_line_buf <= I2C_addr[2];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd29: begin
					sda_line_buf <= I2C_addr[1];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd33: begin
					sda_line_buf <= I2C_addr[0];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd37: begin
					sda_line_buf <= 1'b1;i2c_counter <= i2c_counter + 8'd1;
				end
				8'd41: begin
					sda_line_buf <= I2C_WDATA[23];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd45: begin
					sda_line_buf <= I2C_WDATA[22];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd49: begin
					sda_line_buf <= I2C_WDATA[21];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd53: begin
					sda_line_buf <= I2C_WDATA[20];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd57: begin
					sda_line_buf <= I2C_WDATA[19];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd61: begin
					sda_line_buf <= I2C_WDATA[18];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd65: begin
					sda_line_buf <= I2C_WDATA[17];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd69: begin
					sda_line_buf <= I2C_WDATA[16];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd73: begin
					sda_line_buf <= 1'b1;i2c_counter <= i2c_counter + 8'd1;
				end
				8'd77: begin
					sda_line_buf <= I2C_WDATA[15];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd81: begin
					sda_line_buf <= I2C_WDATA[14];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd85: begin
					sda_line_buf <= I2C_WDATA[13];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd89: begin
					sda_line_buf <= I2C_WDATA[12];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd93: begin
					sda_line_buf <= I2C_WDATA[11];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd97: begin
					sda_line_buf <= I2C_WDATA[10];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd101: begin
					sda_line_buf <= I2C_WDATA[9];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd105: begin
					sda_line_buf <= I2C_WDATA[8];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd109: begin
					sda_line_buf <= 1'b1;i2c_counter <= i2c_counter + 8'd1;
				end

				8'd112: begin
					clk_line_buf <= ~clk_line_buf;
					if(I2C_WDATA[7:0] == 8'hee)
						i2c_counter <= 8'd149;
					else
						i2c_counter <= 8'd113;
				end

				8'd113: begin
					sda_line_buf <= I2C_WDATA[7];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd117: begin
					sda_line_buf <= I2C_WDATA[6];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd121: begin
					sda_line_buf <= I2C_WDATA[5];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd125: begin
					sda_line_buf <= I2C_WDATA[4];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd129: begin
					sda_line_buf <= I2C_WDATA[3];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd133: begin
					sda_line_buf <= I2C_WDATA[2];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd137: begin
					sda_line_buf <= I2C_WDATA[1];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd141: begin
					sda_line_buf <= I2C_WDATA[0];i2c_counter <= i2c_counter + 8'd1;
				end
				8'd145: begin
					sda_line_buf <= 1'b1;i2c_counter <= i2c_counter + 8'd1;
				end

		
				8'd149: begin
					sda_line_buf <= 1'b1;
					clk_line_buf <= 1'b1;
					i2c_counter <= i2c_counter + 8'd1;
				end
				
				8'd150: begin
					sda_line_buf <= 1'b1;
					clk_line_buf <= 1'b1;
					i2c_counter <= i2c_counter + 8'd1;
				end
				
				8'd151: begin
					sda_line_buf <= 1'b1;
					clk_line_buf <= 1'b1;
					trans_finished <= 1'b1;
				end

				default: begin
					if (!(i2c_counter & 8'b1))//偶数
						begin
							clk_line_buf <= ~clk_line_buf;
							i2c_counter <= i2c_counter + 8'd1;
						end
					else
					begin
						i2c_counter <= i2c_counter + 8'd1;
					end
				end


			endcase
		end
	end


endmodule
