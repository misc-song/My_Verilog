module mealy_fsm_template (
    input  wire       clk,      // 时钟
    input  wire       rst_n,    // 异步复位（低有效）
    input  wire [1:0] din,      // 输入信号（示例）
    output reg  [1:0] dout      // 输出信号
);

    // 状态编码
    localparam [1:0] S0 = 2'b00,
                     S1 = 2'b01,
                     S2 = 2'b10;

    reg [1:0] state_cur, state_next;

    //-------------------------------------
    // 第一段：时序逻辑，状态更新 
    //-------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_cur <= S0;
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
                    state_next = S0;
                else
                    state_next = S2;
            end
            default: state_next = S0;
        endcase
    end

    //-------------------------------------
    // 第三段：时序逻辑，输出生成（Mealy型：依赖当前状态和输入）
    //-------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= 2'b00;
        else begin
            case (state_cur)
                S0: begin
                    if (din == 2'b01)
                        dout <= 2'b01;   // 输出与输入组合
                    else
                        dout <= 2'b00;
                end
                S1: begin
                    if (din == 2'b10)
                        dout <= 2'b10;
                    else
                        dout <= 2'b01;
                end
                S2: begin
                    if (din == 2'b11)
                        dout <= 2'b11;
                    else
                        dout <= 2'b10;
                end
                default: dout <= 2'b00;
            endcase
        end
    end

endmodule