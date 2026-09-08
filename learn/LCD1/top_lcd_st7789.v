
//============================================================================
// 2.0inch IPS Module (ST7789, 320x240, 4-line SPI) — 纯红点亮 Demo
// Target : DE25-nano / Agilex IV E, 50MHz
// 功能   : 上电初始化 LCD，全屏填充 RGB565 纯红 (0xF800)
// SPI    : Mode 0, MSB first, SCLK = 50MHz/4 = 12.5MHz
//============================================================================
module top_lcd_st7789 (
    input  wire clk_50m,     // 50MHz 系统时钟  PIN_V16
    input  wire sys_rst_n,   // 低电平复位       PIN_C8

    output wire lcd_sclk,    // SPI 时钟         PIN_H16
    output wire lcd_sda,     // SPI 数据(只写)   PIN_C2
    output reg  lcd_res,     // LCD 复位,低有效   PIN_Y2
    output wire lcd_dc,      // 0=命令,1=数据     PIN_L1
    output wire lcd_cs,      // 片选,低有效       PIN_P2
    output reg  lcd_blk      // 背光,1=亮         PIN_B3
);

//====================================================================
// 1. SPI 字节发送器  (4-wire: SCLK / SDA / CS / DC)
//    每个 bit 占 4 个 clk 周期 (0.5 低, 0.5 高), SCLK=12.5MHz
//====================================================================
reg        spi_start;
reg  [7:0] spi_data;
reg        spi_dc_in;
wire       spi_busy;

reg  [7:0] spi_shift;
reg  [3:0] spi_bit_cnt;
reg  [1:0] spi_div;
reg        spi_sclk_r;
reg        spi_sda_r;
reg        spi_dc_r;
reg        spi_cs_r;
reg        spi_busy_r;

assign lcd_sclk = spi_sclk_r;
assign lcd_sda  = spi_sda_r;
assign lcd_dc   = spi_dc_r;
assign lcd_cs   = spi_cs_r;
// 组合逻辑 busy: start 有效同周期即拉高, 避免等待状态首周期误退出
assign spi_busy = (spi_state != SPI_IDLE) || spi_start;

localparam [1:0] SPI_IDLE  = 2'd0;
localparam [1:0] SPI_SHIFT = 2'd1;
localparam [1:0] SPI_DONE  = 2'd2;
reg [1:0] spi_state;

always @(posedge clk_50m or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        spi_state   <= SPI_IDLE;
        spi_sclk_r  <= 1'b0;
        spi_sda_r   <= 1'b0;
        spi_dc_r    <= 1'b0;
        spi_cs_r    <= 1'b1;
        spi_busy_r  <= 1'b0;
        spi_bit_cnt <= 4'd0;
        spi_div     <= 2'd0;
        spi_shift   <= 8'd0;
    end else begin
        case (spi_state)
            SPI_IDLE: begin
                spi_sclk_r <= 1'b0;
                spi_cs_r   <= 1'b1;
                spi_busy_r <= 1'b0;
                if (spi_start) begin
                    spi_shift   <= spi_data;
                    spi_dc_r    <= spi_dc_in;   // DC 先于 CS 拉低
                    spi_bit_cnt <= 4'd0;
                    spi_div     <= 2'd0;
                    spi_busy_r  <= 1'b1;
                    spi_state   <= SPI_SHIFT;
                end
            end

            SPI_SHIFT: begin
                spi_cs_r <= 1'b0;
                case (spi_div)
                    2'd0: begin
                        spi_sclk_r <= 1'b0;
                        spi_sda_r  <= spi_shift[7]; // MSB first, 上升沿前建立
                    end
                    2'd1: spi_sclk_r <= 1'b0;
                    2'd2: spi_sclk_r <= 1'b1;         // 上升沿: LCD 采样
                    2'd3: begin
                        spi_sclk_r <= 1'b1;
                        spi_shift  <= {spi_shift[6:0], 1'b0};
                        if (spi_bit_cnt == 4'd7)
                            spi_state <= SPI_DONE;
                        else
                            spi_bit_cnt <= spi_bit_cnt + 1'b1;
                    end
                endcase
                spi_div <= spi_div + 1'b1;
            end

            SPI_DONE: begin
                spi_sclk_r <= 1'b0;
                spi_cs_r   <= 1'b1;
                spi_busy_r <= 1'b0;
                spi_state  <= SPI_IDLE;
            end
        endcase
    end
end

//====================================================================
// 2. 毫秒延时定时器  (50MHz: 1ms = 50000 周期)
//====================================================================
reg         delay_start;
reg  [7:0]  delay_ms;
wire        delay_done;
reg  [23:0] delay_cnt;
reg         delay_active;

// 组合逻辑 done: start 有效同周期即拉低, 避免等待状态首周期误退出
assign delay_done = !(delay_active || delay_start);

always @(posedge clk_50m or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        delay_cnt    <= 24'd0;
        delay_active <= 1'b0;
    end else if (delay_start) begin
        delay_cnt    <= delay_ms * 50000;
        delay_active <= 1'b1;
    end else if (delay_active) begin
        if (delay_cnt <= 24'd1)
            delay_active <= 1'b0;
        else
            delay_cnt <= delay_cnt - 1'b1;
    end
end

//====================================================================
// 3. 初始化命令表  (ST7789 标准初始化序列, 来自 LCD Wiki)
//    每条 10bit: {dc[1], is_delay[1], data[7:0]}
//      dc=0 命令字节, dc=1 数据字节
//      is_delay=1 时 data=延时毫秒数
//====================================================================
function [9:0] init_rom;
    input [6:0] idx;
    case (idx)
        7'd0 : init_rom = {1'b0,1'b0,8'h11}; // SLPOUT  退出休眠
        7'd1 : init_rom = {1'b1,1'b1,8'd120}; //         延时 120ms
        7'd2 : init_rom = {1'b0,1'b0,8'h36}; // MADCTL   显存访问方向
        7'd3 : init_rom = {1'b1,1'b0,8'h00}; //          0x00=竖屏 240x320
        7'd4 : init_rom = {1'b0,1'b0,8'h3A}; // COLMOD   接口像素格式
        7'd5 : init_rom = {1'b1,1'b0,8'h05}; //          RGB565
        7'd6 : init_rom = {1'b0,1'b0,8'hB2}; // PORCH     porch 设置
        7'd7 : init_rom = {1'b1,1'b0,8'h0C};
        7'd8 : init_rom = {1'b1,1'b0,8'h0C};
        7'd9 : init_rom = {1'b1,1'b0,8'h00};
        7'd10: init_rom = {1'b1,1'b0,8'h33};
        7'd11: init_rom = {1'b1,1'b0,8'h33};
        7'd12: init_rom = {1'b0,1'b0,8'hB7}; // GCTRL    门控
        7'd13: init_rom = {1'b1,1'b0,8'h35};
        7'd14: init_rom = {1'b0,1'b0,8'hBB}; // VCOMS    VCOM 设置
        7'd15: init_rom = {1'b1,1'b0,8'h19};
        7'd16: init_rom = {1'b0,1'b0,8'hC0}; // LCMCTRL  LCM 控制
        7'd17: init_rom = {1'b1,1'b0,8'h2C};
        7'd18: init_rom = {1'b0,1'b0,8'hC2}; // VDVVRHEN VDV/VRH 使能
        7'd19: init_rom = {1'b1,1'b0,8'h01};
        7'd20: init_rom = {1'b0,1'b0,8'hC3}; // VRHS     VRH 设置
        7'd21: init_rom = {1'b1,1'b0,8'h12};
        7'd22: init_rom = {1'b0,1'b0,8'hC4}; // VDVS     VDV 设置
        7'd23: init_rom = {1'b1,1'b0,8'h20};
        7'd24: init_rom = {1'b0,1'b0,8'hC6}; // FRCTRL2  帧率控制
        7'd25: init_rom = {1'b1,1'b0,8'h0F};
        7'd26: init_rom = {1'b0,1'b0,8'hD0}; // PWCTRL1  电源控制
        7'd27: init_rom = {1'b1,1'b0,8'hA4};
        7'd28: init_rom = {1'b1,1'b0,8'hA1};
        7'd29: init_rom = {1'b0,1'b0,8'hE0}; // PVGAMCTRL 正电压 Gamma
        7'd30: init_rom = {1'b1,1'b0,8'hD0};
        7'd31: init_rom = {1'b1,1'b0,8'h04};
        7'd32: init_rom = {1'b1,1'b0,8'h0D};
        7'd33: init_rom = {1'b1,1'b0,8'h11};
        7'd34: init_rom = {1'b1,1'b0,8'h13};
        7'd35: init_rom = {1'b1,1'b0,8'h2B};
        7'd36: init_rom = {1'b1,1'b0,8'h3F};
        7'd37: init_rom = {1'b1,1'b0,8'h54};
        7'd38: init_rom = {1'b1,1'b0,8'h4C};
        7'd39: init_rom = {1'b1,1'b0,8'h18};
        7'd40: init_rom = {1'b1,1'b0,8'h0D};
        7'd41: init_rom = {1'b1,1'b0,8'h0B};
        7'd42: init_rom = {1'b1,1'b0,8'h1F};
        7'd43: init_rom = {1'b1,1'b0,8'h23};
        7'd44: init_rom = {1'b0,1'b0,8'hE1}; // NVGAMCTRL 负电压 Gamma
        7'd45: init_rom = {1'b1,1'b0,8'hD0};
        7'd46: init_rom = {1'b1,1'b0,8'h04};
        7'd47: init_rom = {1'b1,1'b0,8'h0C};
        7'd48: init_rom = {1'b1,1'b0,8'h11};
        7'd49: init_rom = {1'b1,1'b0,8'h13};
        7'd50: init_rom = {1'b1,1'b0,8'h2C};
        7'd51: init_rom = {1'b1,1'b0,8'h3F};
        7'd52: init_rom = {1'b1,1'b0,8'h44};
        7'd53: init_rom = {1'b1,1'b0,8'h51};
        7'd54: init_rom = {1'b1,1'b0,8'h2F};
        7'd55: init_rom = {1'b1,1'b0,8'h1F};
        7'd56: init_rom = {1'b1,1'b0,8'h1F};
        7'd57: init_rom = {1'b1,1'b0,8'h20};
        7'd58: init_rom = {1'b1,1'b0,8'h23};
        7'd59: init_rom = {1'b0,1'b0,8'h21}; // INVON    显示反转开
        7'd60: init_rom = {1'b0,1'b0,8'h29}; // DISPON   开显示
        7'd61: init_rom = {1'b1,1'b1,8'd20};  //         延时 20ms
        default: init_rom = {1'b1,1'b1,8'd0};
    endcase
endfunction

localparam [6:0] INIT_ROM_SIZE = 7'd62;

//====================================================================
// 4. 显示窗口设置表  (CASET + RASET + RAMWR)
//    每条 9bit: {dc[1], data[7:0]}
//    竖屏模式: 列 0~239, 行 0~319, 覆盖整块 240x320 显存
//====================================================================
function [8:0] win_rom;
    input [3:0] step;
    case (step)
        4'd0 : win_rom = {1'b0,8'h2A}; // CASET  列地址
        4'd1 : win_rom = {1'b1,8'h00}; //   起始高字节
        4'd2 : win_rom = {1'b1,8'h00}; //   起始低字节
        4'd3 : win_rom = {1'b1,8'h00}; //   结束高字节
        4'd4 : win_rom = {1'b1,8'hEF}; //   结束低字节 = 239
        4'd5 : win_rom = {1'b0,8'h2B}; // RASET  行地址
        4'd6 : win_rom = {1'b1,8'h00};
        4'd7 : win_rom = {1'b1,8'h00};
        4'd8 : win_rom = {1'b1,8'h01};
        4'd9 : win_rom = {1'b1,8'h3F}; //   结束 = 319
        4'd10: win_rom = {1'b0,8'h2C}; // RAMWR  开始写显存
        default: win_rom = {1'b0,8'h00};
    endcase
endfunction

//====================================================================
// 5. 主控制状态机
//====================================================================
localparam [3:0] S_POR_DELAY   = 4'd0;
localparam [3:0] S_RES_LOW     = 4'd1;
localparam [3:0] S_RES_HIGH    = 4'd2;
localparam [3:0] S_INIT        = 4'd3;
localparam [3:0] S_WINDOW      = 4'd4;
localparam [3:0] S_FILL        = 4'd5;
localparam [3:0] S_DONE        = 4'd6;
localparam [3:0] S_SPI_WAIT    = 4'd7;
localparam [3:0] S_DELAY_WAIT  = 4'd8;

reg [3:0]  state;
reg [3:0]  return_state;
reg [6:0]  init_idx;
reg [3:0]  win_step;
reg [16:0] pixel_cnt;   // 0 ~ 76799 (240*320-1)
reg        pixel_byte;   // 0=高字节 0xF8, 1=低字节 0x00

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
        spi_start   <= 1'b0;     // 默认脉冲
        delay_start <= 1'b0;

        case (state)
            // 上电等待 100ms
            S_POR_DELAY: begin
                lcd_res     <= 1'b1;
                lcd_blk     <= 1'b0;
                delay_start <= 1'b1;
                delay_ms    <= 8'd100;
                return_state<= S_RES_LOW;
                state       <= S_DELAY_WAIT;
            end

            // RES 拉低 20ms (硬件复位)
            S_RES_LOW: begin
                lcd_res     <= 1'b0;
                delay_start <= 1'b1;
                delay_ms    <= 8'd20;
                return_state<= S_RES_HIGH;
                state       <= S_DELAY_WAIT;
            end

            // RES 释放, 等待 120ms
            S_RES_HIGH: begin
                lcd_res     <= 1'b1;
                delay_start <= 1'b1;
                delay_ms    <= 8'd120;
                return_state<= S_INIT;
                state       <= S_DELAY_WAIT;
            end

            // 逐条发送初始化命令表
            S_INIT: begin
                if (init_idx >= INIT_ROM_SIZE) begin
                    win_step <= 4'd0;
                    state    <= S_WINDOW;
                end else if (init_rom(init_idx)[8]) begin
                    // 延时条目
                    delay_start <= 1'b1;
                    delay_ms    <= init_rom(init_idx)[7:0];
                    init_idx    <= init_idx + 1'b1;
                    return_state<= S_INIT;
                    state       <= S_DELAY_WAIT;
                end else begin
                    // SPI 字节条目
                    spi_start   <= 1'b1;
                    spi_data    <= init_rom(init_idx)[7:0];
                    spi_dc_in   <= init_rom(init_idx)[9];
                    init_idx    <= init_idx + 1'b1;
                    return_state<= S_INIT;
                    state       <= S_SPI_WAIT;
                end
            end

            // 设置显示窗口 + 发起 RAMWR
            S_WINDOW: begin
                if (win_step > 4'd10) begin
                    pixel_cnt  <= 17'd0;
                    pixel_byte <= 1'b0;
                    lcd_blk    <= 1'b1;   // 开背光
                    state      <= S_FILL;
                end else begin
                    spi_start   <= 1'b1;
                    spi_data    <= win_rom(win_step)[7:0];
                    spi_dc_in   <= win_rom(win_step)[8];
                    win_step    <= win_step + 1'b1;
                    return_state<= S_WINDOW;
                    state       <= S_SPI_WAIT;
                end
            end

            // 填充纯红: 每像素 2 字节 0xF8 0x00, 共 240*320=76800 像素
            S_FILL: begin
                if (pixel_cnt >= 17'd76800) begin
                    state <= S_DONE;
                end else begin
                    spi_start <= 1'b1;
                    spi_dc_in <= 1'b1;
                    if (pixel_byte == 1'b0) begin
                        spi_data   <= 8'hF8;   // RRRRR GGG (高字节)
                        pixel_byte <= 1'b1;
                    end else begin
                        spi_data   <= 8'h00;   // GG BBBBB (低字节)
                        pixel_byte <= 1'b0;
                        pixel_cnt  <= pixel_cnt + 1'b1;
                    end
                    return_state <= S_FILL;
                    state        <= S_SPI_WAIT;
                end
            end

            // 完成, 保持红色
            S_DONE: ;

            // 等待 SPI 发送完成
            S_SPI_WAIT: begin
                if (!spi_busy)
                    state <= return_state;
            end

            // 等待延时完成
            S_DELAY_WAIT: begin
                if (delay_done)
                    state <= return_state;
            end
        endcase
    end
end

endmodule
