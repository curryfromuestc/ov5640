//i2c时钟参数
`define  SCL_PERIOD  250
`define  SCL_HALF    125
`define  LOW_HLAF    65 
`define  HIGH_HALF   190

//i2c命令参数
`define CMD_START   4'b0001
`define CMD_WRITE   4'b0010
`define CMD_READ    4'b0100
`define CMD_STOP    4'b1000

//从机ID定义
`define WR_ID 8'h78
`define RD_ID 8'h79

//配置寄存器个数
//`define REG_NUM     254
`define REG_NUM     285


module cmos_config(
    input               clk         ,
    input               rst_n       ,
    input               clk_fast,
    //i2c_master
    output              req         ,
    output      [3:0]   cmd         ,
    output      [7:0]   dout        ,
    input               done        ,
    
    output              config_done 
);

//定义参数

    localparam  WAIT   = 4'b0001,//上电等待20ms
                IDLE   = 4'b0010,
                WREQ   = 4'b0100,//发写请求
                WRITE  = 4'b1000;//等待一个字节写完
    parameter   DELAY  = 1000_000;//上电延时20ms开始配置
//信号定义

    reg     [3:0]       state_c     ;
    reg     [3:0]       state_n     ;
    
    reg     [19:0]      cnt0        ;
    wire                add_cnt0/* synthesis syn_keep*/    ;
    wire                end_cnt0/* synthesis syn_keep*/    ;
    reg     [1:0]       cnt1        ;
    wire                add_cnt1/* synthesis syn_keep*/    ;
    wire                end_cnt1/* synthesis syn_keep*/    ;
    reg                 config_flag ;//1:表示在配置摄像头 0：表示配置完成
    wire     [23:0]      lut_data    ;

    reg                 tran_req    ; 
    reg      [3:0]      tran_cmd    ; 
    reg      [7:0]      tran_dout   ; 

    wire                wait2idle   ; 
    wire                idle2wreq   ; 
    wire                write2wreq  ; 
    wire                write2idle  ; 


//状态机

    always  @(posedge clk or negedge rst_n)begin
        if(~rst_n)begin        
            state_c <= WAIT;
        end
        else begin
            state_c <= state_n;
        end
    end

    always  @(*)begin
        case(state_c)
            WAIT :begin 
                if(wait2idle)
                   state_n = IDLE;
                else 
                   state_n = state_c; 
            end 
            IDLE :begin 
                if(idle2wreq)
                    state_n = WREQ; 
                else 
                    state_n = state_c; 
            end  
            WREQ  :state_n = WRITE;
            WRITE :begin 
                if(write2wreq)
                    state_n = WREQ; 
                else if(write2idle)
                    state_n = IDLE;
                else 
                    state_n = state_c; 
            end 
            default:state_n = IDLE; 
        endcase 
    end

    assign wait2idle  = state_c == WAIT  && end_cnt0; 
    assign idle2wreq  = state_c == IDLE  && config_flag; 
    assign write2wreq = state_c == WRITE && done && ~end_cnt1; 
    assign write2idle = state_c == WRITE && end_cnt1; 

//计数器
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt0 <= 0;
        end
        else if(add_cnt0)begin
            if(end_cnt0)
                cnt0 <= 0;
            else
                cnt0 <= cnt0 + 1;
        end
    end
    
    assign add_cnt0 = state_c == WAIT || state_c == WRITE && end_cnt1;
    assign end_cnt0 = add_cnt0 && cnt0 == ((state_c == WAIT)?(DELAY-1):(`REG_NUM-1));

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt1 <= 0;
        end
        else if(add_cnt1)begin
            if(end_cnt1)
                cnt1 <= 0;
            else
                cnt1 <= cnt1 + 1;
        end
    end
    
    assign add_cnt1 = state_c == WRITE && done;
    assign end_cnt1 = add_cnt1 && cnt1 == 4-1;

//config_flag
    always  @(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            config_flag <= 1'b1;
        end
        else if(config_flag & end_cnt0 & state_c != WAIT)begin    //所有寄存器配置完，flag拉低
            config_flag <= 1'b0;
        end
    end

//输出寄存器

    always  @(posedge clk or negedge rst_n)begin
        if(~rst_n)begin
            tran_req <= 0;
            tran_cmd <= 0;
            tran_dout <= 0;
        end
        else if(state_c == WREQ)begin
            case(cnt1)
                0:begin 
                    tran_req <= 1;
                    tran_cmd <= {`CMD_START | `CMD_WRITE};
                    tran_dout <= `WR_ID;
                end 
                1:begin 
                    tran_req <= 1;
                    tran_cmd <= `CMD_WRITE;
                    tran_dout <= lut_data[23:16];
                end
                2:begin 
                    tran_req <= 1;
                    tran_cmd <= `CMD_WRITE;
                    tran_dout <= lut_data[15:8];
                end
                3:begin 
                    tran_req <= 1;
                    tran_cmd <= {`CMD_STOP | `CMD_WRITE};
                    tran_dout <= lut_data[7:0];
                end
                default:tran_req <= 0;
            endcase 
        end
		else begin
		    tran_req  <= 0;
            tran_cmd  <= 0;
            tran_dout <= 0;
		end 
    end

//输出

    assign config_done = ~config_flag;
    assign req = tran_req;
    assign cmd = tran_cmd;
    assign dout = tran_dout;


i2c_rom	i2c_rom_inst (
	.address ( cnt0 ),
	.clock ( clk_fast ),
	.q ( lut_data )
	);


	

endmodule 



