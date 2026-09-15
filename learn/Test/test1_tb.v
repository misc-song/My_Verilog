`timescale 1ns/1ns
`include "test1.v"
module test1_tb();
    reg [31:0] data;
    wire [31:0] res;
test1 tes1(.x(data),.y(res));

initial begin
    // $dumpfile("test1.vcd");
    // $dumpvars(0, test1_tb);
     $monitor("res: %b",res);
end


initial begin
    // data = 32'b10101010011101101010111001010100;


    // data = 32'b10000000000000000000000000000000;
   data = 32'b10010000101010011010100100100;
   
end





endmodule