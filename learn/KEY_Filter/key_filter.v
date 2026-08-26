module key_filter #(
    parameter CLK_FREQ = 50_000_000,  // 系统时钟频率 (Hz)
    parameter DEBOUNCE_MS = 20        // 消抖时间 (ms)
)(
    input wire clk,
    input wire rst_n,                 // 异步复位，低有效
    input wire key_in,                // 原始按键输入（假设低电平为按下）
    output reg key_out,               // 消抖后的稳定输出（低电平表示按下）
    output reg key_pressed            // 有效按下确认脉冲（高有效，持续1个周期）
);

//========== 参数与状态编码 ==========
localparam MAX_CNT = CLK_FREQ / 1000 * DEBOUNCE_MS; // 计数最大值
localparam IDLE        = 2'b00,
           DOWN_FILTER = 2'b01,
           DOWN_STABLE = 2'b10,
           UP_FILTER   = 2'b11;

reg [1:0] state, next_state;
reg [31:0] cnt; // 计数器，位宽需足够容纳 MAX_CNT

//========== 第一段：时序逻辑，状态寄存器 ==========
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

//========== 第二段：组合逻辑，次态转移 ==========
// 注意：此块为纯组合逻辑，所有赋值必须为阻塞赋值 "="
always @(*) begin
    next_state = state; // 默认保持，防止产生锁存器
    case (state)
        IDLE: begin
            if (key_in == 1'b0)       // 检测到下降沿，开始滤波
                next_state = DOWN_FILTER;
            else
                next_state = IDLE;
        end

        DOWN_FILTER: begin
            if (key_in == 1'b1)       // 出现高电平抖动，立刻取消滤波
                next_state = IDLE;
            else if (cnt == MAX_CNT - 1) // 低电平稳定持续满消抖时间
                next_state = DOWN_STABLE;
            else
                next_state = DOWN_FILTER;
        end

        DOWN_STABLE: begin
            if (key_in == 1'b1)       // 检测到上升沿，开始释放滤波
                next_state = UP_FILTER;
            else
                next_state = DOWN_STABLE;
        end

        UP_FILTER: begin
            if (key_in == 1'b0)       // 出现低电平抖动，立刻回到稳定按下状态
                next_state = DOWN_STABLE;
            else if (cnt == MAX_CNT - 1) // 高电平稳定持续满消抖时间
                next_state = IDLE;
            else
                next_state = UP_FILTER;
        end

        default: next_state = IDLE;
    endcase
end

//========== 第三段：时序逻辑，输出与计数器控制 ==========
// 此段使用当前状态 state，产生最终输出和计数器的递增/清零
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 0;
        key_out <= 1'b1;   // 默认释放状态
        key_pressed <= 1'b0;
    end else begin
        // 默认值：脉冲信号每个周期自动清零，计数器步进值在此统一声明
        key_pressed <= 1'b0;
        
        case (state)
            IDLE: begin
                cnt <= 0;
                key_out <= 1'b1;
            end

            DOWN_FILTER: begin
                key_out <= 1'b1; // 消抖未完成，输出仍为释放状态
                if (key_in == 1'b1) begin      // 检测到抖动，计数器归零
                    cnt <= 0;
                end else if (cnt == MAX_CNT - 1) begin
                    // 滤波完成，产生一个周期的按键有效脉冲
                    key_pressed <= 1'b1;
                    cnt <= 0;                  // 计满后归零，为下次计数准备
                end else begin
                    cnt <= cnt + 1;
                end
            end

            DOWN_STABLE: begin
                key_out <= 1'b0; // 输出稳定按下状态
                cnt <= 0;        // 保持计数器归零
            end

            UP_FILTER: begin
                key_out <= 1'b0; // 释放滤波期间，输出仍保持按下状态
                if (key_in == 1'b0) begin      // 检测到抖动，计数器归零
                    cnt <= 0;
                end else if (cnt == MAX_CNT - 1) begin
                    // 释放滤波完成，计数器归零，但无需产生脉冲信号
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end

            default: begin
                cnt <= 0;
                key_out <= 1'b1;
            end
        endcase
    end
end

endmodule