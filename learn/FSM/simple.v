module simple(
    input clk,
    input rst_n,
    input w,
    output reg[1:0] z
);
 //初始化状态码
localparam A = 2'b00;
localparam B = 2'b01;
localparam C = 2'b10;
 
 // 声明状态
reg [1:0] current_state;
reg [1:0] next_state;
 
    //-------------------------------------
    // 第一段：时序逻辑，状态更新 
    //-------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= A;
    end
    else 
        current_state <= next_state;
end
 
    //-------------------------------------
    // 第二段：组合逻辑，下一状态计算
    //-------------------------------------
always @(*) begin
    case (current_state)
        A:
        begin
            if (w) begin
                next_state = B;
            end
            else begin
                next_state = A;
            end
        end 
        B:
        begin
            if (w) begin
                next_state = C;
            end
            else begin
                next_state <= A;
            end
        end
        C:
        begin
            if (w) begin
                next_state = C;
            end
            else begin
                next_state = A;
            end
        end
        default: 
        begin
            next_state = A;
        end
    endcase
end
    //-------------------------------------
    // 第三段：时序逻辑，输出生成（Moore型：仅依赖当前状态）
    //-------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (rst_n) begin
        z <= 2'd0;
    end
    else begin
        case (next_state)
            A: z <= 2'd0;
            B: z <= 2'd1;
            C: z <= 2'd2;
            default: z <= 2'd0;
        endcase
    end
end
 
endmodule