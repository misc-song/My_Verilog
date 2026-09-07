module spi_master #(
    parameter SPI_CNT_MAX = 5
)(
    input               clk,
    input               rst_n,

    input               start,
    input      [7:0]    tx_data,
    output reg          busy,

    output reg          sclk,
    output reg          sda
);

reg [3:0]   bit_cnt;
reg [7:0]   shift_reg;
reg [3:0]   prescaler;

localparam IDLE = 1'b0;
localparam TX   = 1'b1;
reg state;
reg sclk_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        busy <= 1'b0;
        sclk <= 1'b0;
        sda  <= 1'b0;
        bit_cnt <= 4'd0;
        prescaler <= 4'd0;
        shift_reg <= 8'd0;
        state <= IDLE;
        sclk_reg <= 1'b0;
    end else begin
        case(state)
        IDLE: begin
            sclk_reg <= 1'b0;
            sclk <= sclk_reg;
            busy <= 1'b0;
            if(start) begin
                busy <= 1'b1;
                shift_reg <= tx_data;
                bit_cnt <= 4'd7;
                prescaler <= 4'd0;
                state <= TX;
            end
        end
        TX: begin
            prescaler <= prescaler + 1'b1;
            if(prescaler == SPI_CNT_MAX) begin
                prescaler <= 0;
                sclk_reg <= ~sclk_reg;
                sclk <= sclk_reg;

                if(sclk_reg == 1'b0) begin
                    sda <= shift_reg[7];
                    shift_reg <= {shift_reg[6:0],1'b0};
                end
                else begin
                    if(bit_cnt == 0) begin
                        state <= IDLE;
                    end else begin
                        bit_cnt <= bit_cnt - 1'b1;
                    end
                end
            end
        end
        endcase
    end
end

endmodule
