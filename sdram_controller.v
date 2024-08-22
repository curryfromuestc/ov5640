

module sdram_controller(
    input           clk     ,//100M 控制器主时钟
    input           clk_fifo_read,  //FIFO读取时钟
    input           clk_in  ,//数据输入时钟
    input           rst_n   ,
    input   [7:0]  din     ,   //摄像头输入数据，拼接在FIFO中进行
    input           din_vld ,  //数据有效


    input           rd_req  ,//外部读请求
    output  [15:0]  dout    ,//外部读数据
    output   reg    dout_vld,//外部读数据有效

    //地址清空
    input           addr_write_clr,
    input           addr_read_clr,

    //读写控制与应答
    input           w_or_r_req,
    output       w_or_r_ack,

 
    //sdram接口
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
//信号定义
 
    reg                avm_write      ; 
    reg                avm_read       ; 
    wire    [23:0]      avm_addr       ; 
    wire    [15:0]      avm_wrdata     ; 
    wire    [15:0]      avs_rddata     ; 
    wire                avs_rddata_vld ; 
    wire                avs_waitrequest; 

    wire [15:0]         wfifo_data     ;


reg [23:0] wr_addr;
reg [23:0] rd_addr;


assign avm_addr = w_or_r_ack ? wr_addr : rd_addr;


always @(negedge clk or negedge rst_n)
begin
    if (!rst_n)
        begin
            avm_write <= 1'b1;
        end
    else
    begin
        if (w_or_r_ack && !wfifo_empty )
        begin
            avm_write <= 1'b0; //低电平写入有效
        end
        else if ( (!(waitrequest_last || avs_waitrequest)) && fifo_ready_to_read)
        begin
            avm_write <= 1'b1;
        end
    end
end


//写入地址自增
always @(negedge clk or negedge rst_n or posedge addr_write_clr)
begin
    if (!rst_n || addr_write_clr)
    begin
        wr_addr <= 24'b0;
    end
    else
    begin
        if(wfifo_rdreq)
            wr_addr <= wr_addr + 24'b1;
    end
end

assign wfifo_rdreq = !avm_write && w_or_r_ack && !avs_waitrequest && !waitrequest_last; // 读取FIFO请求控制
wire [15:0] wfifo_q;
assign wfifo_wrreq = din_vld && w_or_r_ack ; // 写入FIFO请求控制 
// assign avm_wrdata[7:0] = wfifo_q[15:8]; // 写入FIFO数据输出
// assign avm_wrdata[15:8] = wfifo_q[7:0]; // 写入FIFO数据输出
assign avm_wrdata[15:0] = wfifo_q[15:0];
assign w_or_r_ack = w_or_r_req || !wfifo_empty; // 读写请求应答

/////////////////////////////读取控制

// 产生rd_req的上升沿
reg rd_req_last;
reg rd_req_last_1;
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        rd_req_last <= 1'b0;
        rd_req_last_1 <= 1'b0;
    end
    else
    begin
        rd_req_last <= rd_req;
        rd_req_last_1 <= rd_req_last;
    end
end
wire rd_req_rise = rd_req_last && !rd_req_last_1; // 读请求上升沿

reg waitrequest_last;
always @(posedge clk)
begin
    waitrequest_last <= avs_waitrequest;
end


always @(negedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        avm_read <= 1'b1;
        dout_vld <= 1'b0;
    end
    else
    begin
        if (!w_or_r_ack && rd_req_rise)
        begin
            avm_read <= 1'b0;
            dout_vld <= 1'b0;
        end
        else if (!rd_req)
        begin
            avm_read <= 1'b1;
            dout_vld <= 1'b0;
        end
        else if (avs_rddata_vld)
        begin
            avm_read <= 1'b1;
            dout_vld <= 1'b1;
        end
        
    end
end


assign dout = avs_rddata;
always @(negedge clk or negedge rst_n or posedge addr_read_clr)
begin
    if (!rst_n || addr_read_clr)
    begin
        rd_addr <= 24'b0;
    end
    else
    begin
        if (avs_rddata_vld && dout_vld)
        begin
            rd_addr <= rd_addr + 24'd1;
        end
    end
end

wire [15:0] wrusedw_sig;
wire fifo_ready_to_read = (wrusedw_sig > 16'b1) ? 1'b1 : 1'b0;

assign wfifo_data = din;

    wrfifo	wrfifo_inst (
	.aclr   (~rst_n     ),
	.data   (wfifo_data ),
	.rdclk  (clk_fifo_read        ),
	.rdreq  (wfifo_rdreq),
	.wrclk  (clk_in     ),
	.wrreq  (wfifo_wrreq),
	.q      (wfifo_q    ),
	.rdempty(wfifo_empty),
	.wrfull (wfifo_full ),
    .wrusedw ( wrusedw_sig )
	);
    

    sdram_interface u_interface (
        .clk_clk           (clk             ),           //     clk.clk
        .reset_reset_n     (rst_n           ),     //   reset.reset_n
        .avs_address       (avm_addr        ),       //     avs.address
        .avs_byteenable_n  (2'b00           ),  //        .byteenable_n
        .avs_chipselect    (1'b1            ),    //        .chipselect
        .avs_writedata     (avm_wrdata      ),     //        .writedata
        .avs_read_n        (avm_read        ),        //        .read_n
        .avs_write_n       (avm_write       ),       //        .write_n
        .avs_readdata      (avs_rddata      ),      //        .readdata
        .avs_readdatavalid (avs_rddata_vld  ), //        .readdatavalid
        .avs_waitrequest   (avs_waitrequest ),   //        .waitrequest

        .mem_pin_addr      (addr            ),      // mem_pin.addr
        .mem_pin_ba        (bank            ),        //        .ba
        .mem_pin_cas_n     (casn            ),     //        .cas_n
        .mem_pin_cke       (cke             ),       //        .cke
        .mem_pin_cs_n      (csn             ),      //        .cs_n
        .mem_pin_dq        (dq              ),        //        .dq
        .mem_pin_dqm       (dqm             ),       //        .dqm
        .mem_pin_ras_n     (rasn            ),     //        .ras_n
        .mem_pin_we_n      (wen             )       //        .we_n
    );

endmodule      

