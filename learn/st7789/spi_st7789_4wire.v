//============================================================================
// 4‑Wire SPI Master for ST7789 (只写模式)
// Mode0, MSB‑First, SCLK = clk / 4
// clk: 50MHz → SCLK = 12.5MHz
// 输入：start脉冲, data[7:0], dc_in(数据/命令选择)
// 输出：sclk,sda,cs_n,dc, busy忙标志
//============================================================================
module spi_st7789_4wire(
    input  wire        clk,          // 系统时钟 50MHz
    input  wire        rst_n,        // 低电平复位

    input  wire        spi_start,    // 发送启动脉冲(高1周期)
    input  wire [7:0]  spi_data,     // 待发送字节
    input  wire        spi_dc_in,    // DC电平：0=命令 1=数据

    output reg         lcd_sclk,     // SPI SCLK
    output reg         lcd_sda,      // SPI MOSI
    output reg         lcd_cs_n,     // CS 低有效
    output reg         lcd_dc,       // DC 命令/数据选择
    output wire        spi_busy      // 忙标志：1正在发送
);

localparam [1:0] SPI_IDLE  = 2'd0;
localparam [1:0] SPI_SHIFT = 2'd1;
localparam [1:0] SPI_DONE  = 2'd2;

reg [1:0] spi_state;
reg [7:0] spi_shift;
reg [3:0] spi_bit_cnt;
reg [1:0] spi_div;
reg        spi_busy_r;

assign spi_busy = (spi_state != SPI_IDLE) || spi_start;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_state   <= SPI_IDLE;
        lcd_sclk    <= 1'b0;
        lcd_sda     <= 1'b0;
        lcd_dc      <= 1'b0;
        lcd_cs_n    <= 1'b1;
        spi_busy_r  <= 1'b0;
        spi_bit_cnt <= 4'd0;
        spi_div     <= 2'd0;
        spi_shift   <= 8'd0;
    end else begin
        case (spi_state)
            SPI_IDLE: begin
                lcd_sclk  <= 1'b0;
                lcd_cs_n  <= 1'b1;
                spi_busy_r<= 1'b0;
                if(spi_start) begin
                    spi_shift   <= spi_data;
                    lcd_dc      <= spi_dc_in;
                    spi_bit_cnt <= 4'd0;
                    spi_div     <= 2'd0;
                    spi_busy_r  <= 1'b1;
                    spi_state   <= SPI_SHIFT;
                end
            end

            SPI_SHIFT: begin
                lcd_cs_n <= 1'b0;
                case(spi_div)
                    2'd0: begin
                        lcd_sclk <= 1'b0;
                        lcd_sda  <= spi_shift[7]; // MSB first，上升沿前建立数据
                    end
                    2'd1: lcd_sclk <= 1'b0;
                    2'd2: lcd_sclk <= 1'b1;   // 上升沿，LCD采样数据
                    2'd3: begin
                        lcd_sclk <= 1'b1;
                        spi_shift <= {spi_shift[6:0],1'b0};
                        if(spi_bit_cnt == 4'd7) begin
                            spi_state <= SPI_DONE;
                        end else begin
                            spi_bit_cnt <= spi_bit_cnt + 1'b1;
                        end
                    end
                endcase
                spi_div <= spi_div + 1'b1;
            end

            SPI_DONE: begin
                lcd_sclk   <= 1'b0;
                lcd_cs_n   <= 1'b1;
                spi_busy_r <= 1'b0;
                spi_state  <= SPI_IDLE;
            end
        endcase
    end
end

endmodule
