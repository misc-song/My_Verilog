module st7789_init_fill(
    input               clk_50m,
    input               rst_n,
    output reg          init_done,

    input               spi_busy,
    output reg          spi_start,
    output reg [7:0]    spi_tx_data,
    output reg          lcd_dc      // 0=命令，1=数据
);

localparam  IDLE        = 4'd0;
localparam  RST_WAIT    = 4'd1;
localparam  SEND_CMD    = 4'd2;
localparam  WAIT_SPI    = 4'd3;
localparam  SET_WINDOW  = 4'd4;
localparam  WINDOW_TX   = 4'd5;
localparam  WRITE_PIX   = 4'd6;
localparam  DONE        = 4'd7;

reg [3:0]   state;
reg [15:0]  cnt_delay;
reg [7:0]   cmd_idx;
reg [3:0]   win_byte_idx;   // 窗口序列发送字节索引
reg [18:0]  pixel_cnt;      // 240*320 = 76800 pixels

// ST7789 4‑wire SPI初始化序列 {dc, data_byte}
reg [8:0] init_table[0:23];
initial begin
init_table[0]  = {1'b0, 8'h01}; // Software Reset
init_table[1]  = {1'b1, 8'h00}; // dummy
init_table[2]  = {1'b0, 8'h11}; // Sleep Out
init_table[3]  = {1'b0, 8'h3A}; // COLMOD: Pixel Format
init_table[4]  = {1'b1, 8'h55}; // 16bit RGB565
init_table[5]  = {1'b0, 8'h21}; // Inversion ON
init_table[6]  = {1'b0, 8'h26}; // Gamma set
init_table[7]  = {1'b1, 8'h04};
init_table[8]  = {1'b0, 8'hB2}; // Porch setting
init_table[9]  = {1'b1, 8'h0C};
init_table[10] = {1'b1, 8'h0C};
init_table[11] = {1'b1, 8'h00};
init_table[12] = {1'b1, 8'h33};
init_table[13] = {1'b1, 8'h33};
init_table[14] = {1'b0, 8'hB7}; // Gate control
init_table[15] = {1'b1, 8'h35};
init_table[16] = {1'b0, 8'hBB}; // VCOM
init_table[17] = {1'b1, 8'h19};
init_table[18] = {1'b0, 8'hC0}; // LCM Control
init_table[19] = {1'b1, 8'h2C};
init_table[20] = {1'b0, 8'hC2}; // VDV
init_table[21] = {1'b1, 8'h01};
init_table[22] = {1'b0, 8'h29}; // Display ON
init_table[23] = {1'b1, 8'h00};
end

// 窗口设置序列：CASET + RASET + RAMWR 一共 1+4 +1+4 +1 =11字节 {dc,data}
reg [8:0] win_table[0:10];
initial begin
win_table[0]  = {1'b0,8'h2A};   // CASET
win_table[1]  = {1'b1,8'h00};
win_table[2]  = {1'b1,8'h00};
win_table[3]  = {1'b1,8'h00};
win_table[4]  = {1'b1,8'hEF};

win_table[5]  = {1'b0,8'h2B};   // RASET
win_table[6]  = {1'b1,8'h00};
win_table[7]  = {1'b1,8'h00};
win_table[8]  = {1'b1,8'h01};
win_table[9]  = {1'b1,8'h3F};

win_table[10] = {1'b0,8'h2C};   // RAMWR
end

always @(posedge clk_50m or negedge rst_n) begin
if(!rst_n) begin
    state       <= IDLE;
    cnt_delay   <= 16'd0;
    cmd_idx     <= 8'd0;
    spi_start   <= 1'b0;
    spi_tx_data <= 8'd0;
    lcd_dc      <= 1'b0;
    init_done   <= 1'b0;
    pixel_cnt   <= 19'd0;
    win_byte_idx<= 4'd0;
end
else begin
    spi_start <= 1'b0;
    case(state)
    IDLE: begin
        cnt_delay <= 16'd50000; // 1ms delay
        state <= RST_WAIT;
    end

    RST_WAIT: begin
        if(cnt_delay == 16'd0) begin
            cmd_idx <= 8'd0;
            state <= SEND_CMD;
        end
        else cnt_delay <= cnt_delay - 1'b1;
    end

    SEND_CMD: begin
        if(cmd_idx > 8'd23) begin
            win_byte_idx <=4'd0;
            state <= SET_WINDOW;
        end
        else begin
            lcd_dc      <= init_table[cmd_idx][8];
            spi_tx_data <= init_table[cmd_idx][7:0];
            spi_start   <= 1'b1;
            state       <= WAIT_SPI;
        end
    end

    WAIT_SPI: begin
        if(spi_busy == 1'b0) begin
            case(state)
                SEND_CMD: cmd_idx <= cmd_idx + 1'b1;
                WINDOW_TX: win_byte_idx <= win_byte_idx + 1'b1;
                WRITE_PIX: pixel_cnt <= pixel_cnt + 1'b1;
            endcase
            // 返回对应状态
            if(state == SEND_CMD) state <= SEND_CMD;
            else if(state == WINDOW_TX) begin
                if(win_byte_idx > 4'd10) begin
                    pixel_cnt <= 19'd0;
                    state <= WRITE_PIX;
                end
                else state <= WINDOW_TX;
            end
            else if(state == WRITE_PIX) begin
                if(pixel_cnt >= 19'd76800) begin
                    state <= DONE;
                end
                else state <= WRITE_PIX;
            end
        end
    end

    SET_WINDOW: begin
        state <= WINDOW_TX;
    end

    WINDOW_TX: begin
        lcd_dc      <= win_table[win_byte_idx][8];
        spi_tx_data <= win_table[win_byte_idx][7:0];
        spi_start   <= 1'b1;
        state       <= WAIT_SPI;
    end

    WRITE_PIX: begin
        // RGB565 全白 0xFFFF，先发高字节0xFF，再低字节0xFF
        lcd_dc      <= 1'b1;
        // 奇数像素输出高字节，偶数输出低字节
        if(pixel_cnt[0]==1'b0) begin
            spi_tx_data <= 8'hFF;
        end else begin
            spi_tx_data <= 8'hFF;
        end
        spi_start   <= 1'b1;
        state       <= WAIT_SPI;
    end

    DONE: begin
        init_done <= 1'b1;
    end
    default: state <= IDLE;
    endcase
end
end
endmodule
