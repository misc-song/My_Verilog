`timescale 10ns/10ns
// `include "Three_To_Eight_Decoder.v"
module Three_To_Eight_Decoder_tb();

reg [2:0] a;
wire [7:0] y;
Three_To_Eight_Decoder dut(a,y);
initial begin
    $dumpfile("Three_To_Eight_Decoder.vcd");
    $dumpvars(0, Three_To_Eight_Decoder_tb);
end
initial begin
    a=3'b000;
    #10 a=3'b001;
    #10 a=3'b010;
    #10 a=3'b011;
    #10 a=3'b100;
    #10 a=3'b101;
    #10 a=3'b110;
    #10 a=3'b111;
    #10 $finish;
end
endmodule

