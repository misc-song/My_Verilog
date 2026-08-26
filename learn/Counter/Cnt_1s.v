module Cnt_1s(clk,rst,counter,led);
input clk,rst;
output reg [25:0] counter;
output reg led;
always @(posedge clk) begin
    if(rst == 1) begin
        counter <= 0;
         led <= 0;
    end
    else if(counter == 49_999_999) begin  // 1s = 50M/50 = 1M
        counter <= 0;
        led <= ~led;
    end
    else
        counter <= counter + 1;
end

endmodule