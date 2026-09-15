module spi_clk(
    input sys_clk,
    input reset_n,
    output reg spi_clk
);
reg [1:0] counter;

always@(posedge sys_clk or negedge reset_n) begin
    if(reset_n == 0)
        spi_clk <= 0;
    else if(counter == 2'b11)
        spi_clk <= 1;
    else
        spi_clk <= 0;
end

always@(posedge sys_clk or negedge reset_n) begin
    if(reset_n == 0)
        counter <= 2'b00;
    else if(counter == 2'b11)
        counter <= 2'b00;
    else
        counter <= counter + 1'b1;
end


endmodule;