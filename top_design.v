`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/01 17:26:21
// Design Name: 
// Module Name: top_design
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_design(
    input clk,
    input rst,
    output xclk,
    output scl,
    inout sda,
    output reg cam_rst,
    input rst1,
    output config_down,
    output led0,

    input vsync,
    input href,
    input pclk,
    input d7,
    input d6,
    input d5,
    input d4,
    input d3,
    input d2,
    input d1,
    input d0,

    output led1,
    output reg uart_pin,
	 output  uart_pin_1,
    input soft_rst,
    input i2c_rst,
	 
	 output pwdn,

     input uart_pin_rec,
	
	 
	output              sdram_clk       ,
    output              sdram_cke       ,   
    output              sdram_csn       ,   
    output              sdram_rasn      ,   
    output              sdram_casn      ,   
    output              sdram_wen       ,   
    output  [1:0]       sdram_bank      ,   
    output  [12:0]      sdram_addr      ,   
    inout   [15:0]      sdram_dq        ,   
    output  [1:0]       sdram_dqm       ,

    input               mode_switch,

     output              pump_enable,

    input test_change,

    input mover_enable,
    input move_to_home_enable,
	 
	 output uart_test1

    );


assign pwdn = 0;
assign xclk = 1'bz;

// 产生25MHz的时钟
reg clk_25M;
always @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        clk_25M <= 1'b0;
    end
    else
    begin
        clk_25M <= ~clk_25M;
    end
end

// 串口发送复用
always @(posedge clk )
begin
    uart_pin <= color_uart & 1;
end

// 控制摄像头复位
always @(posedge clk)
begin
    cam_rst <= rst;
end

assign uart_test1 = uart_pin_1;
// 产生10Hz的时钟，用于计时或毛刺过滤
reg [21:0] cnt_10hz;
reg clock_10hz;
always @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        cnt_10hz <= 22'd0;
        clock_10hz <= 1'b0;
    end
    else
    begin
        if (cnt_10hz == 22'd2499999)
        begin
            cnt_10hz <= 22'd0;
            clock_10hz <= ~clock_10hz;
        end
        else
        begin
            cnt_10hz <= cnt_10hz + 22'd1;            
        end
    end
end

// 低速时钟的产生，用于慢速模块，使用PLL方便调节速度
wire shape_clock;
wire shape_clock_slow;
pll0	pll0_inst (
	.areset ( ~rst ),
	.inclk0 ( clk ),
	.c0 ( shape_clock ),
	.c1 ( shape_clock_slow ),
	.c2(xclk)
	);


//对 i2c_rst 毛刺过滤
reg last_i2c_rst;
always @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        last_i2c_rst <= 1'b1;
    end
    else
    begin
        last_i2c_rst <= i2c_rst;
    end
end

// 摄像头I2C配置模块
// I2C_AV_Config I2C_AV_Config_0 (
//     .rst(last_i2c_rst),
//     .CLK_1M(shape_clock),
//     .clock_slow(clock_10hz),

//    .I2C_SCLK(scl),
//    .I2C_SDAT(sda),
//    .Config_Done(config_down)
//    );

I2C_AV_Config I2C_AV_Config_0 (
    .rst(last_i2c_rst),
    .iCLK(clk_25M),
    .clk_fast(clk),

   .I2C_SCLK(scl),
   .I2C_SDAT(sda),
   .Config_Done(config_down)
   );
	
// 对mode_switch进行滤波
// mode_switch 用于控制调试MUX，决定SDRAM分配给串口监视器还是图像处理模块
reg mode_switch_last;
always @(posedge clock_10hz or negedge rst)
begin
    if (!rst)
    begin
        mode_switch_last <= 1'b0;
    end
    else
    begin
        mode_switch_last <= mode_switch;
    end
end


// 对soft_rst_last进行毛刺过滤
// soft_rst_last 用于控制所有的子模块复位
reg soft_rst_last;
always @(posedge clock_10hz or negedge rst)
begin
    if (!rst)
    begin
        soft_rst_last <= 1'b0;
    end
    else
    begin
        soft_rst_last <= soft_rst;
    end
end

// SDRAM 读取所需要的信号
wire sdram_write_ok;
wire sdram_read_req;
wire sdram_read_vld;
wire sdram_read_clr_addr;
wire [15:0] sdram_dout;

// 摄像头捕获模块
capture capture_ins(
    .clk(clk),
    .clk_10hz(clock_10hz),
    .rst_n(soft_rst_last && sub_module_reset),
    .din({d7,d6,d5,d4,d3,d2,d1,d0}),
    .pclk(pclk),
    .vsync(vsync),
    .href(href),
    .dout(sdram_dout),
    .dout_req(sdram_read_req),
    .dout_vld(sdram_read_vld),
    .ready_to_read(sdram_write_ok),
    .clr_read_addr(sdram_read_clr_addr),
    .sdram_clk(sdram_clk),
    .cke(sdram_cke),
    .csn(sdram_csn),
    .rasn(sdram_rasn),
    .casn(sdram_casn),
    .wen(sdram_wen),
    .bank(sdram_bank),
    .addr(sdram_addr),
    .dq(sdram_dq),
    .dqm(sdram_dqm)

);


// 色彩范围
wire [4:0] red_ub;
wire [4:0] red_lb;
wire [5:0] green_ub;
wire [5:0] green_lb;
wire [4:0] blue_ub;
wire [4:0] blue_lb;

// 从mux接入色彩过滤器的信号
wire [15:0] filter_din;
wire filter_en;
wire filter_read_req;
wire filter_read_ack;
wire filter_write_ok;

// 从mux接入uart_watcher的信号
wire uart_watcher_en;
wire uart_watcher_rd_req;
wire uart_watcher_read_ack;
wire [15:0] uart_watcher_din;

// MUX，用于将SDRAM的信号切换到不同的模块
debug_mux debug_mux_ins(
    .clk(clk),
    .rst_n(rst),
    .mode_switch(mode_switch_last),  // 控制开关

    // 对接sdram
    .sdram_dout(sdram_dout),
    .sdram_dout_req(sdram_read_req),
    .sdram_dout_vld(sdram_read_vld),
    .sdram_ready_to_read(sdram_write_ok),
    .sdram_clr_read_addr(sdram_read_clr_addr),

    // 对接sensor_filter
    .sensor_filter_din(filter_din),
    .sensor_filter_en(filter_en),
    .sensor_filter_sdram_rd_req(filter_read_req_out),
    .sensor_filter_sdram_read_ack(filter_read_ack),
    
    // 对接uart_watcher
    .uart_watcher_din(uart_watcher_din),
    .uart_watcher_en(uart_watcher_en),
    .uart_watcher_sdram_rd_req(uart_watcher_rd_req),
    .uart_watcher_sdram_read_ack(uart_watcher_read_ack)

);

// 串口图像监视，用于把SDRAM中的图像发送至计算机
wire color_uart;
uart_watcher uart_watcher_ins(
    .clk(clk),
    .rst_n(soft_rst_last && sub_module_reset),
    .en(uart_watcher_en),
    .din(uart_watcher_din),
    .sdram_rd_req(uart_watcher_rd_req),
    .sdram_read_ack(uart_watcher_read_ack),
    .uart_pin(color_uart)
);



wire bin_uart;
wire sensor_fit_color_out;
wire filter_ack_out;
// 图像二值化的模块，色彩过滤，夹在图像处理模块和MUX之间
sensor_filter_mid sensor_filter(
    .clk(clk),
    .rst_n(soft_rst_last && sub_module_reset),
    .sensor_data(filter_din),
    .req_in(read_req_hub),
    .req_out(filter_read_req_out),
    .ack_in(filter_read_ack),
    .ack_out(filter_ack_out),
    .color_select(color_select),
    .color_out(sensor_fit_color_out)
);

// 图像模块处理完成信号
wire analyse_done;
// 识别到的位置
wire [8:0] hexagon_x;
wire [8:0] circle_x;
wire [8:0] square_x;
wire [7:0] hexagon_y;
wire [7:0] circle_y;
wire [7:0] square_y;
wire [8:0] square_left;
wire [8:0] square_right;

// 聚合处理模块和二值化图像的串口监视请求
wire read_req_hub;
assign read_req_hub = filter_read_req || 0;//uart_watcher_rd_req_bin;

// 开关切换当前使能二值化串口监视还是图像处理模块，并且对test_change进行毛刺过滤
reg test_change_last;
always @(posedge clock_10hz or negedge rst)
begin
    if (!rst)
    begin
        test_change_last <= 1'b0;
    end
    else
    begin
        test_change_last <= test_change;
    end
end

wire left_or_right;

// 图像处理模块
shape_finder shape_finder_ins(
    .clk(shape_clock_slow),   //由于电路规模非常大, fmax跑不上去, 所以使用慢时钟
    .rst_n(soft_rst_last && sub_module_reset),
    .en(filter_en && !test_change_last),    // 如果test_change为1，则不处理图像
    .data_req(filter_read_req),
    .data_ack(filter_ack_out),
    .data_in(sensor_fit_color_out),
    .analysis_done(analyse_done),
    .hexagon_x(hexagon_x),
    .circle_x(circle_x),
    .square_x(square_x),
    .hexagon_y(hexagon_y),
    .circle_y(circle_y),
    .square_y(square_y),
    .square_left(square_left),
    .square_right(square_right),
    .left_or_right(left_or_right)
);


// 这个串口监视模块用于监视二值化过后的图像
//uart_watcher uart_watcher_ins_1(
//   .clk(clk),
//   .rst_n(soft_rst_last && sub_module_reset),
//   .en(filter_en && test_change_last),     // 如果test_change为0，则不处理图像
//   .din({sensor_fit_color_out,sensor_fit_color_out,sensor_fit_color_out,sensor_fit_color_out,sensor_fit_color_out,sensor_fit_color_out,sensor_fit_color_out,sensor_fit_color_out,sensor_fit_color_out}),
//   .sdram_rd_req(tcher_rd_req_bin),
//   .sdram_read_ack(filter_ack_out),
//   .uart_pin(bin_uart)
//);

// 对mover_enable进行毛刺过滤
reg mover_enable_last;
always @(posedge clock_10hz or negedge rst)
begin
    if (!rst)
    begin
        mover_enable_last <= 1'b0;
    end
    else
    begin
        mover_enable_last <= mover_enable;
    end
end

// 对move_to_home_enable进行毛刺过滤
reg move_to_home_last;
always @(posedge clock_10hz or negedge rst)
begin
    if (!rst)
    begin
        move_to_home_last <= 1'b0;
    end
    else
    begin
        move_to_home_last <= move_to_home_enable;
    end
end


wire [1:0] color_select;  // 当前选择的颜色
wire sub_module_reset;      // 子模块复位信号

// 系统主控制模块
full_mover  full_mover_ins(
    .clk(clk),
    .clk_slow(shape_clock),
    .clk_10hz(clock_10hz),
    .rst_n(rst),

    .square_start_x(square_x),
    .square_start_y(square_y),
    .circle_start_x(circle_x),
    .circle_start_y(circle_y),
    .hexagon_start_x(hexagon_x),
    .hexagon_start_y(hexagon_y),

    .left_or_right(left_or_right),

    .square_left(square_left),
    .square_right(square_right),
    
    .color_select(color_select),
    .process_ok(analyse_done),
    .en(mover_enable_last),
    .move_to_home(move_to_home_last),
    .pump_enable(pump_enable),
    .mov_complete(led0),
    .sub_module_reset(sub_module_reset),
    .uart_pin(uart_pin_1)
);


endmodule
