`define MAX_COUNTER 7'd49
module Flow_LED(clk, rst, led);
input clk, rst;
output reg [7:0] led;
// reg [25:0] counter;
reg [6:0] counter;
always @(posedge clk or posedge rst) begin
	if(rst == 1)
		counter <= 0;
	else if(counter == `MAX_COUNTER)  //26'd49_000_000
		counter <= 0;
	else
		counter <= counter + 1;
end
always @(posedge clk or posedge rst ) begin
	if(rst == 1)
		led <= 8'b0000_0001;             //初始状态
	else if(counter == `MAX_COUNTER)		// 使用宏时 不能忘记 ` 符号
		led <= led << 1;                 //左移一位
	else if(led == 0)
		led <= 8'b0000_0001;   			 //左移溢出时候置位
	else
		led <= led;
end

endmodule

