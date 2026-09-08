//============================================================================
// Top: ST7789 2.0inch IPS 320x240 4‑SPI 纯红填充Demo
// Target: DE25‑nano Agilex5 50MHz
// 实例化子模块：SPI控制器、ms延时、命令ROM
// 功能：上电复位LCD → 初始化序列 → 设置窗口 → 全屏填充RGB565纯红0xF800
//============================================================================
module top_lcd_st7789 (
    input  wire clk_50m,        // 50MHz系统时钟 PIN_V16
    input  wire sys_rst_n,      // 低电平复位 PIN_C8

    output wire lcd_sclk,       // SPI时钟 PIN_H16
    output wire lcd_sda,        // SPI MOSI PIN_C2
    output reg  lcd_res,        // LCD硬件复位，低有效 PIN_Y2
    output wire lcd_dc,         // DC：0命令/1数据 PIN_L1
    output wire lcd_cs,         // CS片选低有效 PIN_P2
    output reg  lcd_blk         // 背光 1点亮 PIN_B3
);

//==================== 内部连线 ====================
wire        spi_busy;
wire        delay_done;

reg         spi_start;
reg [7:0]   spi_data;
reg         spi_dc_in;

reg         delay_start;
reg [7:0]   delay_ms;

wire [9:0]  init_rom_out;
wire [8:0]  win_rom_out;

reg [6:0]   init_idx;
reg [3:0]   win_step;
reg [16:0]  pixel_cnt;
reg         pixel_byte;

//==================== 实例化子模块 ====================
spi_st7789_4wire u_spi_master(
    .clk(clk_50m),
    .rst_n(sys_rst_n),
    .spi_start(spi_start),
    .spi_data(spi_data),
    .spi_dc_in(spi_dc_in),
    .lcd_sclk(lcd_sclk),
    .lcd_sda(lcd_sda),
    .lcd_cs_n(lcd_cs),
    .lcd_dc(lcd_dc),
    .spi_busy(spi_busy)
);

ms_delay_timer u_ms_delay(
    .clk(clk_50m),
    .rst_n(sys_rst_n),
    .delay_start(delay_start),
    .delay_ms(delay_ms),
    .delay_done(delay_done)
);

st7789_init_rom u_st7789_rom(
    .init_idx(init_idx),
    .init_data(init_rom_out),
    .win_step(win_step),
    .win_data(win_rom_out)
);

localparam [6:0] INIT_ROM_SIZE = 7'd62;

//==================== 主状态机定义 ====================
localparam [3:0] S_POR_DELAY    = 4'd0;
localparam [3:0] S_RES_LOW      = 4'd1;
localparam [3:0] S_RES_HIGH     = 4'd2;
localparam [3:0] S_INIT         = 4'd3;
localparam [3:0] S_WINDOW       = 4'd4;
localparam [3:0] S_FILL         = 4'd5;
localparam [3:0] S_DONE         = 4'd6;
localparam [3:0] S_SPI_WAIT     = 4'd7;
localparam [3:0] S_DELAY_WAIT   = 4'd8;

reg [3:0] state;
reg [3:0] return_state;

always @(posedge clk_50m or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        state        <= S_POR_DELAY;
        return_state <= S_DONE;
        init_idx     <= 7'd0;
        win_step     <= 4'd0;
        pixel_cnt    <= 17'd0;
        pixel_byte   <= 1'b0;
        lcd_res      <= 1'b1;
        lcd_blk      <= 1'b0;
        spi_start    <= 1'b0;
        spi_data     <= 8'd0;
        spi_dc_in    <= 1'b0;
        delay_start  <= 1'b0;
        delay_ms     <= 8'd0;
    end else begin
        spi_start   <= 1'b0;
        delay_start <= 1'b0;

        case (state)
            S_POR_DELAY: begin // 上电等待100ms POR稳定
                lcd_res     <= 1'b1;
                lcd_blk     <= 1'b0;
                delay_start <= 1'b1;
                delay_ms    <= 8'd100;
                return_state<= S_RES_LOW;
                state       <= S_DELAY_WAIT;
            end

            S_RES_LOW: begin // LCD复位拉低20ms
                lcd_res     <= 1'b0;
                delay_start <= 1'b1;
                delay_ms    <= 8'd20;
                return_state<= S_RES_HIGH;
                state       <= S_DELAY_WAIT;
            end

            S_RES_HIGH: begin // 释放复位，等待120ms
                lcd_res     <= 1'b1;
                delay_start <= 1'b1;
                delay_ms    <= 8'd120;
                return_state<= S_INIT;
                state       <= S_DELAY_WAIT;
            end

            S_INIT: begin // 逐条执行初始化序列
                if(init_idx >= INIT_ROM_SIZE) begin
                    win_step <= 4'd0;
                    state    <= S_WINDOW;
                end else if(init_rom_out[8]) begin
                    // ROM条目是延时
                    delay_start <= 1'b1;
                    delay_ms    <= init_rom_out[7:0];
                    init_idx    <= init_idx + 1'b1;
                    return_state<= S_INIT;
                    state       <= S_DELAY_WAIT;
                end else begin
                    // ROM条目是SPI发送
                    spi_start   <= 1'b1;
                    spi_data    <= init_rom_out[7:0];
                    spi_dc_in   <= init_rom_out[9];
                    init_idx    <= init_idx + 1'b1;
                    return_state<= S_INIT;
                    state       <= S_SPI_WAIT;
                end
            end

            S_WINDOW: begin // 设置显示窗口，发送RAMWR写显存命令
                if(win_step > 4'd10) begin
                    pixel_cnt  <= 17'd0;
                    pixel_byte <= 1'b0;
                    lcd_blk    <= 1'b1; // 打开背光
                    state      <= S_FILL;
                end else begin
                    spi_start   <= 1'b1;
                    spi_data    <= win_rom_out[7:0];
                    spi_dc_in   <= win_rom_out[8];
                    win_step    <= win_step + 1'b1;
                    return_state<= S_WINDOW;
                    state       <= S_SPI_WAIT;
                end
            end

            S_FILL: begin // 全屏填充RGB565纯红 0xF800
                if(pixel_cnt >= 17'd76800) begin
                    state <= S_DONE;
                end else begin
                    spi_start <= 1'b1;
                    spi_dc_in <= 1'b1;
                    if(pixel_byte == 1'b0) begin
                        spi_data   <= 8'hF8;
                        pixel_byte <= 1'b1;
                    end else begin
                        spi_data   <= 8'h00;
                        pixel_byte <= 1'b0;
                        pixel_cnt  <= pixel_cnt + 1'b1;
                    end
                    return_state <= S_FILL;
                    state        <= S_SPI_WAIT;
                end
            end

            S_DONE: begin
                // 填充完成，保持画面
            end

            S_SPI_WAIT: begin
                if(!spi_busy) state <= return_state;
            end

            S_DELAY_WAIT: begin
                if(delay_done) state <= return_state;
            end
        endcase
    end
end

endmodule
