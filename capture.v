module capture(
    input           clk     ,//50M 主时钟
    input           clk_10hz, //10HZ 时钟 用于延迟计时
    input           rst_n   ,
    input   [7:0]  din     ,//摄像头数据输入
    input           pclk ,//摄像头像素时钟
    input           vsync  ,//帧同步信号
    input           href  ,//行同步信号
    output  [15:0]  dout    ,//输出数据
    input           dout_req,//输出请求信号
    output     dout_vld,//输出数据有效信号

    //读写控制与应答
    output   reg    ready_to_read, //数据准备好
    input          clr_read_addr,//读地址清空
    //sdram接口
    output          sdram_clk,
    output          cke     ,
    output          csn     ,
    output          rasn    ,
    output          casn    ,
    output          wen     ,
    output  [1:0]   bank    ,
    output  [12:0]  addr    ,
    inout   [15:0]  dq      ,
    output  [1:0]   dqm         
);

wire sample_200m;
reg pclk_buf;
always @(posedge sample_200m) // 让摄像头信号同步
begin
    pclk_buf <= pclk;
end

reg href_buf;
reg vsync_buf;
always @(posedge sample_200m)
begin
    href_buf <= href;
    vsync_buf <= vsync;
end


wire pll_locked;
pll1 u_pll1(
	.areset (~rst_n     ),
	.inclk0 (clk        ),
	.c0     (clk_100m   ), //本来是100M的，但是设计到不了100M
	.c1     (clk_100m_s ), //存在延迟，参数详见锁相环
    .c2     (sample_200m), //采样时钟，200M
	.locked (pll_locked) //是否锁定
    );

assign sdram_clk = clk_100m_s;

// 初始化延迟，等待SDRAM等设备准备就绪 
reg [2:0] latency_of_fifo_reset;
reg fifo_ok_status;
always @(posedge clk_10hz or negedge  pll_locked or negedge rst_n)
begin
    if (!pll_locked || !rst_n)
    begin
        latency_of_fifo_reset <= 3'd0;
        fifo_ok_status <= 1'b0;
    end
    else
    begin
        if (latency_of_fifo_reset == 3'd5)
        begin
            fifo_ok_status <= 1'b1;
        end
        else
        begin
            latency_of_fifo_reset <= latency_of_fifo_reset + 3'b1;
        end
    end
end




wire sdram_w_or_r_ack;
reg sdram_w_or_r;
wire clk_vga;
    sdram_controller u_meme_controller(
    /*input           */.clk     (clk_100m      ),//100M 控制器主时钟
    /*input           */.clk_in  (pclk_buf          ),//数据输入时钟
                        .clk_fifo_read(clk_100m_s), //FIFO读取时钟
    /*input           */.rst_n   (rst_n    ),
    /*input   [15:0]  */.din     (din),
    /*input           */.din_vld (href_buf && frame_start_latch && !frame_over_latch), //数据有效条件：当前行同步有效且在一帧内
    /*input           */.rd_req  (dout_req        ),//外部读请求
    /*output  [15:0]  */.dout    (dout          ),//外部读数据
    /*output          */.dout_vld(dout_vld      ),//外部读数据有效

               .addr_write_clr(line_error),            //写入地址归零，没有用到
               .addr_read_clr(clr_read_addr),//读取地址归零

    //读写控制与应答
               .w_or_r_req(sdram_w_or_r),    //读写切换请求
              .w_or_r_ack(sdram_w_or_r_ack),  //读写切换应答
    //sdram接口
    /*output          */.cke     (cke     ),
    /*output          */.csn     (csn     ),
    /*output          */.rasn    (rasn    ),
    /*output          */.casn    (casn    ),
    /*output          */.wen     (wen     ),
    /*output  [1:0]   */.bank    (bank    ),
    /*output  [12:0]  */.addr    (addr    ),
    /*inout   [15:0]  */.dq      (dq      ),
    /*output  [1:0]   */.dqm     (dqm     )    
);


reg line_error;
reg [8:0] pixels_counter;

always @(posedge pclk_buf or negedge rst_n)
begin
	if (!rst_n)
	begin
		pixels_counter <= 0;
		line_error <= 0;
	end
    else if (!frame_start_latch && line_error == 1)
		begin
			line_error = 0;
		end
	else if (href_buf && frame_start_latch)
	begin
		pixels_counter <= pixels_counter +1;
	end
	else  
		if (pixels_counter != 0 && pixels_counter != 639)
		begin
			line_error <= 0;
			pixels_counter <= 0;
		end
			
end 

// 判断帧是否开始，并锁存
reg frame_start_latch;
always @(negedge vsync_buf or negedge rst_n)
begin
    if (!rst_n)
    begin
        frame_start_latch <= 1'b0;
    end
    else if (line_error)
	 begin
		  frame_start_latch <= 1'b0;
	 end
	 
    else if (fifo_ok_status)
    begin
        frame_start_latch <= 1'b1;
    end
end

//判断帧是否结束，并锁存
reg frame_over_latch;
always @(posedge vsync_buf or negedge rst_n)
begin
    if (!rst_n)
    begin
        frame_over_latch <= 1'b0;
        sdram_w_or_r <= 1'b1;
    end
    else
    begin
        if (frame_start_latch)
        begin
            frame_over_latch <= 1'b1;
            sdram_w_or_r <= 1'b0;
        end
    end
end

// 判断数据是否已经全部写入sdram，发出数据准备好信号
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
	 begin
        ready_to_read <= 1'b0;
	 end
    else
    begin
        if (frame_over_latch && !sdram_w_or_r_ack)
        begin
            ready_to_read <= 1'b1;
        end
    end
end




endmodule