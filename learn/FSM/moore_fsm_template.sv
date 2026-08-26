module moore_fsm_template (
    input  wire       clk,      // 时钟
    input  wire       rst_n,    // 异步复位（低有效）
    input  wire [1:0] din,      // 输入信号（示例）
    output reg  [1:0] dout      // 输出信号
);

    // 状态编码（可使用独热码或二进制）
    localparam [1:0] S0 = 2'b00,
                     S1 = 2'b01,
                     S2 = 2'b10,
                     S3 = 2'b11;

    reg [1:0] state_cur, state_next;   // 当前状态、下一状态

    //-------------------------------------
    // 第一段：时序逻辑，状态更新
    //-------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_cur <= S0;            // 复位到初始状态
        else
            state_cur <= state_next;
    end

    //-------------------------------------
    // 第二段：组合逻辑，下一状态计算
    //-------------------------------------
    always_combo begin
        case (state_cur)
            S0: begin
                if (din == 2'b01)
                    state_next = S1;
                else
                    state_next = S0;
            end
            S1: begin
                if (din == 2'b10)
                    state_next = S2;
                else
                    state_next = S1;
            end
            S2: begin
                if (din == 2'b11)
                    state_next = S3;
                else
                    state_next = S0;
            end
            S3: begin
                state_next = S0;         // 无条件回到初始
            end
            default: state_next = S0;
        endcase
    end

    //-------------------------------------
    // 第三段：时序逻辑，输出生成（Moore型：仅依赖当前状态）
    //-------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= 2'b00;
        else begin
            case (state_cur)
                S0:    dout <= 2'b00;
                S1:    dout <= 2'b01;
                S2:    dout <= 2'b10;
                S3:    dout <= 2'b11;
                default: dout <= 2'b00;
            endcase
        end
    end

endmodule

