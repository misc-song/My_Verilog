module de25_lcd_top
#(
    parameter SYS_CLK_FREQ = 50_000_000,
    parameter SPI_CLK_FREQ = 1_000_000,   // SPI速率1MHz，ST7789
    parameter PIX_W = 240,
    parameter PIX_H = 320
)(
    input               clk,            // 50MHz 系统时钟
    input               sys_rst_n,      // PIN_C8 【低电平复位】

    output              lcd_sclk,       // H16 GPIO_0[0]
    output              lcd_sda,        // C2  GPIO_0[2]
    output              lcd_res,        // Y2  GPIO_0[4]
    output              lcd_dc,         // L1  GPIO_0[6]
    output              lcd_cs,         // P2  GPIO_0[8]
    output              lcd_blk         // B3  GPIO_0[9]
);

// ---------------- 内部信号 ----------------
wire                    spi_busy;
reg  [15:0]             pixel_color;
reg  [9:0]              pix_x;
reg  [9:0]              pix_y;
wire                    pix_valid;
wire                    init_done;

// ST7789初始化 + 写像素控制
st7789_controller #(
    .SYS_CLK_FREQ(SYS_CLK_FREQ),
    .SPI_CLK_FREQ(SPI_CLK_FREQ),
    .WIDTH(PIX_W),
    .HEIGHT(PIX_H)
) u_st7789 (
    .clk        (clk),
    .rst_n      (sys_rst_n),         // 传入低电平复位

    .sclk       (lcd_sclk),
    .sda        (lcd_sda),
    .res        (lcd_res),
    .dc         (lcd_dc),
    .cs         (lcd_cs),
    .blk        (lcd_blk),

    .init_done  (init_done),
    .busy       (spi_busy),

    .px_x       (pix_x),
    .px_y       (pix_y),
    .px_wdata   (pixel_color),
    .px_wen     (pix_valid)
);

// ===================== 图像生成：水平红‑黄‑蓝渐变 RGB565 =====================
// RGB565: R[15:11], G[10:5], B[4:0]
always @(posedge clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        pix_x <= 10'd0;
        pix_y <= 10'd0;
    end
    else if(init_done && !spi_busy) begin
        pix_valid <= 1'b1;

        if(pix_x < PIX_W - 1) begin
            pix_x <= pix_x + 1'b1;
        end else begin
            pix_x <= 10'd0;
            if(pix_y < PIX_H -1) begin
                pix_y <= pix_y + 1'b1;
            end else begin
                pix_y <= 10'd0; // 循环刷新全屏
            end
        end

        reg [8:0] x_scaled;
        x_scaled = {pix_x[8:1]}; // 0~119

        reg [4:0] r_val;
        reg [5:0] g_val;
        reg [4:0] b_val;

        if(x_scaled < 60) begin
            r_val = 5'd31;
            g_val = x_scaled[5:0];
            b_val = 5'd0;
        end
        else if(x_scaled < 120) begin
            r_val = 5'd31 - (x_scaled - 60'd0);
            g_val = 6'd63;
            b_val = (x_scaled - 60'd0);
        end
        else begin
            r_val = 5'd0;
            g_val = 6'd63 - (x_scaled - 120'd0);
            b_val = 5'd31;
        end
        pixel_color <= {r_val, g_val, b_val};
    end
    else begin
        pix_valid <= 1'b0;
    end
end

endmodule
