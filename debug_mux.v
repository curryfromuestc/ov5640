module debug_mux(
    input clk,
    input rst_n,
    input mode_switch,

    // 连接sdram
    input [15:0]  sdram_dout,
    output sdram_dout_req,
    input   sdram_dout_vld,
    input   sdram_ready_to_read,
    output reg sdram_clr_read_addr,

    // 连接sensor_filter
    output reg [15:0] sensor_filter_din,
    output sensor_filter_en,
    input   sensor_filter_sdram_rd_req,
    output reg sensor_filter_sdram_read_ack,
    
    // 连接uart_watcher
    output reg [15:0] uart_watcher_din,
    output uart_watcher_en,
    input   uart_watcher_sdram_rd_req,
    output reg uart_watcher_sdram_read_ack


);
// 0 接入sensor_filter , 1 接入uart_watcher

// detect the posedge and negedge of mode_switch
reg mode_switch_last;
always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        mode_switch_last <= 1'b0;
    end
    else
    begin
        mode_switch_last <= mode_switch;
    end
end
wire mode_switch_posedge = mode_switch & ~mode_switch_last;
wire mode_switch_negedge = ~mode_switch & mode_switch_last;

reg current_mode;

reg work_mode; // 下一工作状态
reg [2:0] work_change_cnt;  //状态机计数器
reg sensor_filter_en_buf; // sensor_filter使能
reg uart_watcher_en_buf; // uart_watcher使能

// 流程：先复位SDRAM读取地址，然后关闭两个子模块，然后切换工作模式，然后打开对应的子模块
always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        sensor_filter_en_buf <= 1'b1;
        uart_watcher_en_buf <= 1'b0;
        work_mode <= 1'b0;
        current_mode <= 1'b0;
        sdram_clr_read_addr <= 1'b0;
    end
    else
    begin
        if (mode_switch_posedge)
        begin
            work_mode <= 1'b1;
            work_change_cnt <= 3'b1;
        end
        if (mode_switch_negedge)
        begin
            work_mode <= 1'b0;
            work_change_cnt <= 3'b1;
        end

        case(work_change_cnt)
        3'b1:
        begin
            work_change_cnt <= 3'b10;
            sdram_clr_read_addr <= 1'b1;
            uart_watcher_en_buf <= 1'b0;
            sensor_filter_en_buf <= 1'b0;
        end
        3'b10:
        begin
            work_change_cnt <= 3'b11;
            sdram_clr_read_addr <= 1'b0;
        end
        3'b11:
        begin
            work_change_cnt <= 3'b100;
            current_mode <= work_mode;
        end
        3'b100:
        begin
            if (current_mode == 1'b0)
            begin
                sensor_filter_en_buf <= 1'b1;
            end
            else
            begin
                uart_watcher_en_buf <= 1'b1;
            end
            work_change_cnt <= 3'b0;
        end
		  endcase
    end
end

// 根据当前模式选择数据流向
always @(*)
begin
    if (current_mode)
    begin
        uart_watcher_din <= sdram_dout;
        uart_watcher_sdram_read_ack <= sdram_dout_vld;
        sensor_filter_sdram_read_ack <= 1'b0;
    end
    else
    begin
        sensor_filter_din <= sdram_dout;
        sensor_filter_sdram_read_ack <= sdram_dout_vld;
        uart_watcher_sdram_read_ack <= 1'b0;
    end
end

assign sdram_dout_req = current_mode ? uart_watcher_sdram_rd_req : sensor_filter_sdram_rd_req; // 读请求来源选择
assign uart_watcher_en = uart_watcher_en_buf && sdram_ready_to_read; // 使能条件：当前模式为1，且SDRAM准备好数据
assign sensor_filter_en = sensor_filter_en_buf && sdram_ready_to_read; // 使能条件：当前模式为0，且SDRAM准备好数据

endmodule