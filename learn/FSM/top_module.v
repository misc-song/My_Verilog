module top_module(
    input in,
    input [1:0] state,
    output [1:0] next_state,
    output out); //
	//0. 初始化参数
    parameter A=0, B=1, C=2, D=3;
	//1. 传递状态
    // State transition logic: next_state = f(state, in)
    // always@(*) begin
    //    state <= next_state;
    // end
    
    //2. 确定下一个状态
    always@(*) begin
        case(state)
            A: begin
                if(in) next_state = B;
                else next_state = A;
            end
            B: begin
                if(in) next_state = B;
                else next_state = C;
            end
            C: begin
                if(in) next_state = D;
                else next_state = A;
            end
            D: begin
                if(in) next_state = B;
                else next_state = C;
            end
        endcase
    end
        
    //3. 确定输出
    // Output logic:  out = f(state) for a Moore state machine
    always@(*) begin
        case(state)
            A: out = 0;
            B: out = 0;
            C: out = 0;
            D: out = 1;
        endcase
    end

endmodule


//组合电路的状态机