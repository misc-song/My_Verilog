module chip_74595(input in,input clk,input control,input reset,output reg[7:0] out);
    reg [7:0] temp;
    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            temp <= 8'b0;
        end 
        else if(control!=1) begin
            temp <= {temp[6:0],in}; //将输入数据移入寄存器 舍去最高位
        end
        else begin    // control为1时，输出寄存器中的数据
            out <= temp; //将寄存器中的数据输出
        end
    end
endmodule