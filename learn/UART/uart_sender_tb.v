`timescale 1ns/1ns
module uart_sender_tb;
reg clk;
reg rst;
reg [9:0] data;
reg enable;
wire tx_done;
wire tx;
uart_sender dut(

	.clk(clk),
	.reset(rst),
	.tx_data(data),
	.en_sig(enable),
    .tx_done(tx_done),
	.tx(tx)
);
initial begin

	$dumpfile("uart_sender_tb.vcd");
	$dumpvars(0, uart_sender_tb);
end



initial begin
	clk = 0;
	rst = 0;
	data = 10'b0101010100;
	enable = 0;
    # 10 rst = 1;
    # 10 enable = 1;
    # 1000000  
    $finish;
end
always #5 clk = ~clk;

endmodule