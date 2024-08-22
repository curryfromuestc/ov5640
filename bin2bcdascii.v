`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/04 18:27:01
// Design Name: 
// Module Name: bin2bcdascii
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


module bin2bcdascii(
    input rst,
    input clk,
    input [11:0] binin,
    input [2:0] select,
    output reg [7:0] ascii,
    input go,
    output reg done
    );

reg [31:0] bcd;

reg [2:0] try_pos;

//detect rising edge of go signal
reg go_last;
always @(posedge clk or negedge rst)
begin
    if (!rst)
        go_last <= 1'b0;
    else
        go_last <= go;
end
wire start = !go_last & go;

reg go_latch;

always@(negedge clk or negedge rst)
begin
    if (!rst)
    begin
        bcd <= {8'd9 , 8'd9 , 8'd9 , 8'd9};
        done <= 1'b1;
        try_pos <= 3'd3;
        go_latch <= 1'b0;
    end
    else if (start)
    begin
        bcd <= {8'd2 , 8'd9 , 8'd9 , 8'd9};
        go_latch <= 1'b1;
        done <= 1'b0;
        try_pos <= 3'd3;
    end
    else if (go_latch)
    begin
        if (try_pos == 3)
        begin
            if (binin < bcd[31:24] * 1000)
            begin
                bcd[31:24] <= bcd[31:24] - 1;
            end
            else
            begin
                try_pos <= 2;
            end
        end
        else if (try_pos == 2)
        begin
            if (binin < bcd[23:16] * 100 + bcd[31:24] * 1000)
            begin
                bcd[23:16] <= bcd[23:16] - 1;
            end
            else
            begin
                try_pos <= 1;
            end
        end
        else if (try_pos == 1)
        begin
            if (binin < bcd[15:8] * 10 + bcd[23:16] * 100 + bcd[31:24] * 1000)
            begin
                bcd[15:8] <= bcd[15:8] - 1;
            end
            else
            begin
                try_pos <= 0;
            end
        end
        else if (try_pos == 0)
        begin
            if (binin < bcd[7:0] + bcd[15:8] * 10 + bcd[23:16] * 100 + bcd[31:24] * 1000)
            begin
                bcd[7:0] <= bcd[7:0] - 1;
            end
            else
            begin
                done <= 1'b1;
                go_latch <= 1'b0;
            end
        end
    end
end


always @(*)
begin
    case (select)
        3'd0: ascii <= bcd[7:0] + 8'd48;
        3'd1: ascii <= bcd[15:8] + 8'd48;
        3'd2: ascii <= bcd[23:16] + 8'd48;
        3'd3: ascii <= bcd[31:24] + 8'd48;
        default: ascii <= 8'd0  + 8'd48;
    endcase
end

    
endmodule
