module st7789_driver
#(
    parameter SYS_CLK_FREQ  = 50_000_000,
    parameter SPI_CLK_FREQ  = 1_000_000,
    parameter WIDTH         = 240,
    parameter HEIGHT        = 320
)(
    input               clk,
    input               rst_n,          // 低电平复位

    output reg          sclk,
    output reg          sda,
    output reg          res,
    output reg          dc,
    output reg          cs,
    output reg          blk,

    output reg          init_done,
    output reg          busy,

    input       [9:0]   px_x,
    input       [9:0]   px_y,
    input       [15:0]  px_wdata,
    input               px_wen
);

localparam CLK_DIV_CNT = SYS_CLK_FREQ / (SPI_CLK_FREQ * 2);

localparam S_RST_DELAY      = 0;
localparam S_INIT_CMD       = 1;
localparam S_WAIT_INIT      = 2;
localparam S_IDLE           = 3;
localparam S_SET_WINDOW     = 4;
localparam S_SEND_PIXEL     = 5;

reg [4:0] state;
reg [31:0] delay_cnt;
reg [7:0]  cmd_idx;

reg [8:0] spi_tx_buf;
reg [3:0] spi_bit_cnt;
reg [$clog2(CLK_DIV_CNT):0] clk_div;

// ST7789 初始化命令表 {DC, CMD, delay_ms}
reg [16:0] init_table[0:22];
initial begin
    init_table[0]  = {1'b0, 8'h01, 10'd150}; // SW reset
    init_table[1]  = {1'b0, 8'h11, 10'd120}; // sleep out
    init_table[2]  = {1'b0, 8'h3A, 10'd0};
    init_table[3]  = {1'b1, 8'h55, 10'd10}; // RGB565
    init_table[4]  = {1'b0, 8'h36, 10'd0};
    init_table[5]  = {1'b1, 8'h00, 10'd10}; // MADCTL 0°
    init_table[6]  = {1'b0, 8'h21, 10'd10}; // color invert ON
    init_table[7]  = {1'b0, 8'h2A, 10'd0}; // CASET column
    init_table[8]  = {1'b1, 8'h00, 10'd0};
    init_table[9]  = {1'b1, 8'h00, 10'd0};
    init_table[10] = {1'b1, 8'h00, 10'd0};
    init_table[11] = {1'b1, 8'hEF, 10'd10}; // 239
    init_table[12] = {1'b0, 8'h2B, 10'd0}; // RASET row
    init_table[13] = {1'b1, 8'h00, 10'd0};
    init_table[14] = {1'b1, 8'h00, 10'd0};
    init_table[15] = {1'b1, 8'h01, 10'd0};
    init_table[16] = {1'b1, 8'h3F, 10'd10}; //319
    init_table[17] = {1'b0, 8'h29, 10'd120}; // display on
    init_table[18] = {1'b1, 8'h00, 10'd0};
    init_table[19] = {1'b1, 8'h00, 10'd0};
    init_table[20] = {1'b1, 8'h00, 10'd0};
    init_table[21] = {1'b1, 8'h00, 10'd0};
    init_table[22] = {1'b1, 8'h00, 10'd0};
end

reg [16:0] cur_cmd;
reg spi_tx_en;
reg spi_tx_finish;

// SPI移位发送 9bit (dc + 8bit)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sclk <= 1'b1;
        sda  <= 1'b1;
        spi_bit_cnt <= 4'd0;
        clk_div <= 0;
        spi_tx_finish <= 1'b0;
    end
    else begin
        spi_tx_finish <= 1'b0;
        if(spi_tx_en) begin
            clk_div <= clk_div + 1'b1;
            if(clk_div >= CLK_DIV_CNT) begin
                clk_div <= 0;
                sclk <= ~sclk;
                if(sclk == 1'b1) begin // 下降沿移出
                    sda <= spi_tx_buf[8];
                    spi_tx_buf <= {spi_tx_buf[7:0],1'b0};
                    spi_bit_cnt <= spi_bit_cnt + 1'b1;
                    if(spi_bit_cnt == 4'd8) begin
                        spi_tx_en <= 1'b0;
                        spi_tx_finish <= 1'b1;
                    end
                end
            end
        end
        else begin
            sclk <= 1'b1;
        end
    end
end

// 主状态机
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= S_RST_DELAY;
        res <= 1'b0;
        cs <= 1'b1;
        blk <= 1'b0;
        dc <= 1'b0;
        busy <= 1'b1;
        init_done <= 1'b0;
        delay_cnt <= 0;
        cmd_idx <= 0;
        spi_tx_en <= 1'b0;
    end
    else begin
        case(state)
        S_RST_DELAY: begin
            res <= 1'b0;
            delay_cnt <= delay_cnt + 1'b1;
            if(delay_cnt >= SYS_CLK_FREQ / 1000 * 20) begin //20ms复位
                res <= 1'b1;
                delay_cnt <= 0;
                state <= S_INIT_CMD;
            end
        end

        S_INIT_CMD: begin
            cs <= 1'b0;
            cur_cmd <= init_table[cmd_idx];
            dc <= cur_cmd[16];
            spi_tx_buf <= {cur_cmd[16], cur_cmd[15:8]};
            spi_tx_en <= 1'b1;
            state <= S_WAIT_INIT;
        end

        S_WAIT_INIT: begin
            if(spi_tx_finish) begin
                spi_tx_en <= 1'b0;
                delay_cnt <= 0;
                if(cur_cmd[7:0] > 0) begin
                    delay_cnt <= delay_cnt + 1'b1;
                    if(delay_cnt >= SYS_CLK_FREQ / 1000 * cur_cmd[7:0]) begin
                        cmd_idx <= cmd_idx + 1'b1;
                        if(cmd_idx >= 8'd22) begin
                            cs <= 1'b1;
                            blk <= 1'b1;
                            init_done <= 1'b1;
                            busy <= 1'b0;
                            state <= S_IDLE;
                        end else begin
                            state <= S_INIT_CMD;
                        end
                    end
                end else begin
                    cmd_idx <= cmd_idx + 1'b1;
                    if(cmd_idx >= 8'd22) begin
                        cs <= 1'b1;
                        blk <= 1'b1;
                        init_done <= 1'b1;
                        busy <= 1'b0;
                        state <= S_IDLE;
                    end else begin
                        state <= S_INIT_CMD;
                    end
                end
            end
        end

        S_IDLE: begin
            busy <= 1'b0;
            if(px_wen && init_done) begin
                busy <= 1'b1;
                state <= S_SET_WINDOW;
            end
        end

        S_SET_WINDOW: begin
            cs <= 1'b0;
            dc <= 1'b0; spi_tx_buf <= {1'b0,8'h2C}; spi_tx_en <=1'b1;
            @(posedge spi_tx_finish);
            dc <=1'b1; spi_tx_buf <= {1'b1, px_wdata[15:8]}; spi_tx_en <=1'b1;
            @(posedge spi_tx_finish);
            dc <=1'b1; spi_tx_buf <= {1'b1, px_wdata[7:0]}; spi_tx_en <=1'b1;
            @(posedge spi_tx_finish);

            cs <= 1'b1;
            busy <= 1'b0;
            state <= S_IDLE;
        end
        default: state <= S_IDLE;
        endcase
    end
end

endmodule
