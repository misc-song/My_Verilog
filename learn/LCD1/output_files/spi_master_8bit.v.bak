module spi_master_8bit(
    input               clk_50m,
    input               rst_n,

    input               start,
    input      [7:0]    tx_data,
    output reg          busy,

    output reg          sclk,
    output reg          sda
);

reg [3:0] div_cnt;
reg [3:0] bit_cnt;
reg [7:0] shift_reg;

always @(posedge clk_50m or negedge rst_n) begin
if(!rst_n) begin
    busy        <= 1'b0;
    sclk        <= 1'b0;
    sda         <= 1'b0;
    div_cnt     <= 4'd0;
    bit_cnt     <= 4'd0;
    shift_reg   <= 8'd0;
end
else begin
    if(start && !busy) begin
        busy        <= 1'b1;
        shift_reg   <= tx_data;
        div_cnt     <= 4'd0;
        bit_cnt     <= 4'd0;
        sclk        <= 1'b0;
    end
    else if(busy) begin
        div_cnt <= div_cnt + 1'b1;
        if(div_cnt == 4'd7) begin // 50M/8 =6.25MHz SPI SCLK
            div_cnt <= 4'd0;
            sclk <= ~sclk;
            if(sclk == 1'b0) begin // sclk下降沿更新sda，CPOL=0 CPHA=0
                sda <= shift_reg[7];
                shift_reg <= {shift_reg[6:0],1'b0};
                bit_cnt <= bit_cnt + 1'b1;
                if(bit_cnt == 4'd8) begin
                    busy <= 1'b0;
                end
            end
        end
    end
end
end
endmodule
