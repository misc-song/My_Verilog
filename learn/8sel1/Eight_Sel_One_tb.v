`timescale 10ns/1ns
// `include "Eight_Sel_One.v"
module Eight_Sel_One_tb();


reg [7:0] a;
reg [2:0] s;
wire y;
Eight_Sel_One dut(.data(a),.sel(s),.y(y));
initial begin
    $dumpfile("wave.vcd");  // 波形文件名
    $dumpvars(0, Eight_Sel_One_tb);  // 记录当前模块所有信号
end

initial begin
	a = 8'b10101010;
	s = 3'b000;
	# 100;
	s = 3'b001;
	# 100;
	s = 3'b010;
	# 100;
	s = 3'b011;
	# 100;
	s = 3'b100;
	# 100;
	s = 3'b101;
	# 100;
	s = 3'b110;
	# 100;
	s = 3'b111;
	# 100;
	$finish;
end





endmodule