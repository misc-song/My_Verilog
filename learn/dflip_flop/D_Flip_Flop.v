module D_Flip_Flop(in,clk,reset,out);

input in,clk,reset;
output reg out;
always @(posedge clk) begin
    if(reset== 1'b0) begin
        out <= 1'b0;
    end
    else begin
        out <= in;
    end

end
endmodule