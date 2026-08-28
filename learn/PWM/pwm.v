module pwm(
    input clk,
    input rst_n,
    input wire [15:0] period,
    input wire [15:0] duty,
    output reg pwm_out
);
reg [15:0] counter;
always @(posedge clk) begin
    if(rst_n == 0) 
        counter <= 0; 
    else if(counter >= period -1)
        counter <= 0;
    else 
        counter <= counter + 1;
end

always @(posedge clk) begin
    if(rst_n == 0)
        pwm_out <= 0;
    else if(counter < duty)
        pwm_out <= 1;
    else
        pwm_out <= 0;
end






endmodule