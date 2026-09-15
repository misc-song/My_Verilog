module spi_master(
    input sys_clk,
    input rst_n,
    input [7:0] data_in,        //数据输入
    output reg [7:0] data_out,  //数据输出
    output reg cs,              //片选信号
);
wire spi_clk;       //12.5Mhz 时钟
spi_clk spi_clk_inst(
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .spi_clk(spi_clk)
);


localparam IDLE        = 3'd0; // 空闲：CS=1, SCK=0，等待tx_start
localparam CS_ASSERT   = 3'd1; // CS拉低，等待tCSU片选建立时间；可在此设置DC
localparam TX_RX_BYTE  = 3'd2; // 核心：8个SCLK，全双工收发，bit计数器0~7
localparam CS_HOLD     = 3'd3; // 字节发送完成，保持CS低一段时间（tCSH）
localparam CS_DEASSERT = 3'd4; // CS拉高
localparam TRANS_DONE  = 3'd5; // 传输完成，rx_valid标志，回到IDLE

reg [2:0] current_state;
reg [2:0] next_state;

//三段式状态机 第一段 时序逻辑 状态切换
always@(posedge clk or negedge rst_n) begin
    if(rst_n == 0) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end 
end

//三段式状态机 第二段 组合逻辑 次态生成
always @(*) begin
    case(current_state)
        IDLE: begin
            if(data_in != 8'h00) begin
                next_state = CS_ASSERT;
            end
            else begin
                next_state = IDLE;
            end
        end
        CS_ASSERT: begin
            next_state = TX_RX_BYTE;
        end
        TX_RX_BYTE: begin
            if(data_in == 8'h00) begin
                next_state = CS_HOLD;
            end
            else begin
                next_state = TX_RX_BYTE;
            end
        end
        CS_HOLD: begin
            next_state = CS_DEASSERT;
        end
        CS_DEASSERT: begin
            next_state = TRANS_DONE;
        end
        TRANS_DONE: begin
            next_state = IDLE;
        end
        default: begin
            next_state = IDLE;
        end
    endcase
end

//三段式状态机 第三段 时序逻辑 输出逻辑
always @(posedge spi_clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        cs <= 1'b1;
    end
    else begin
        case(next_state)
            IDLE: begin
                cs <= 1'b1;
            end
            CS_ASSERT: begin
                cs <= 1'b0;
            end
        endcase
    end
end


endmodule