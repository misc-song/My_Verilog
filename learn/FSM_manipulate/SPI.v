module SPI(
    input  wire sys_clk,
    input  wire reset_n,
    input  wire en_sig,
    output reg  spi_clk,    // 修改：增加 spi_clk 输出，便于外接从机
    output reg  cs,
    output reg  out
);

// 状态定义
localparam [1:0] IDLE    = 2'b00;
localparam [1:0] PREPAR  = 2'b01;
localparam [1:0] SEND    = 2'b10;
localparam [1:0] RELEASE = 2'b11;

// 待发送数据（可改为输入端口）
parameter [7:0] data = 8'b10101010;

// 内部信号
reg [1:0] current_status;
reg [1:0] next_status;
reg [3:0] count;
reg [7:0] shift_reg;     // 修改：使用移位寄存器代替 bit_count

//========================================================================
// 1. spi_clk 生成
// 修改：仅在 SEND 状态翻转，非 SEND 状态保持低电平
//========================================================================
always @(posedge sys_clk or negedge reset_n) begin
    if (!reset_n) begin
        spi_clk <= 1'b0;
    end else if (current_status == SEND) begin
        spi_clk <= ~spi_clk;
    end else begin
        spi_clk <= 1'b0;
    end
end

//========================================================================
// 2. 计数器
// 修改：状态切换时清零，使用 current_status != next_status 检测
//========================================================================
always @(posedge sys_clk or negedge reset_n) begin
    if (!reset_n) begin
        count <= 4'd0;
    end else if (current_status != next_status) begin
        count <= 4'd0;          // 状态即将切换，清零
    end else if (count == 4'd15) begin
        count <= 4'd0;
    end else begin
        count <= count + 1'd1;
    end
end

//========================================================================
// 3. 状态机时序逻辑
//========================================================================
always @(posedge sys_clk or negedge reset_n) begin
    if (!reset_n) begin
        current_status <= IDLE;
    end else begin
        current_status <= next_status;
    end
end

//========================================================================
// 4. 状态机组合逻辑
//========================================================================
always @(*) begin
    case (current_status)
        IDLE:    next_status = en_sig ? PREPAR : IDLE;
        PREPAR:  next_status = (count == 4'd15) ? SEND : PREPAR;
        SEND:    next_status = (count == 4'd15) ? RELEASE : SEND;
        RELEASE: next_status = (count == 4'd15) ? IDLE : RELEASE;
        default: next_status = IDLE;
    endcase
end

//========================================================================
// 5. 输出逻辑（cs、out、移位寄存器）
// 修改：使用移位寄存器，在 spi_clk 下降沿更新数据，保证上升沿采样稳定
//========================================================================
always @(posedge sys_clk or negedge reset_n) begin
    if (!reset_n) begin
        cs        <= 1'b1;
        out       <= 1'b0;
        shift_reg <= 8'b0;
    end else begin
        case (current_status)
            IDLE: begin
                cs        <= 1'b1;
                out       <= 1'b0;
                shift_reg <= data;      // 预加载待发送数据
            end
            PREPAR: begin
                cs        <= 1'b0;
                out       <= data[7];   // 第一位在第一个spi_clk上升沿前稳定
                shift_reg <= data;
            end
            SEND: begin
                cs <= 1'b0;
                // 当 spi_clk 为高（即将下降）时移位，数据在下降沿更新
                if (spi_clk == 1'b1) begin
                    out       <= shift_reg[6];              // 输出下一位
                    shift_reg <= {shift_reg[6:0], 1'b0};    // 左移
                end
            end
            RELEASE: begin
                cs        <= 1'b0;
                out       <= 1'b0;
                shift_reg <= shift_reg;  // 保持不变
            end
            default: begin
                cs        <= 1'b1;
                out       <= 1'b0;
                shift_reg <= 8'b0;
            end
        endcase
    end
end

endmodule