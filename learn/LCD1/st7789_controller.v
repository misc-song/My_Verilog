module st7789_min_ctrl(
    input               clk,
    input               rst_n,

    input               spi_busy,
    output reg          spi_start,
    output reg [7:0]    spi_tx_data,

    output reg          lcd_res,
    output reg          lcd_dc,
    output reg          lcd_cs,

    output reg          init_done,
    input      [15:0]   fixed_color
);

reg [11:0] cmd_idx;
reg [15:0] delay_cnt;
reg [3:0] win_step;
reg       byte_sel;

reg [8:0] x;
reg [9:0] y;

localparam ST_RST        = 4'd0;
localparam ST_INIT_SEQ   = 4'd1;
localparam ST_WAIT_DELAY = 4'd2;
localparam ST_SET_WINDOW = 4'd3;
localparam ST_FILL_RED   = 4'd4;
reg [3:0] state;

// {dc_bit[8], data[7:0], delay_flag[0]}
reg [8:0] init_table [0:8];
initial begin
    init_table[0]  = {1'b0,8'h01,1'b1}; // SWRESET
    init_table[1]  = {1'b0,8'h11,1'b1}; // SLPOUT
    init_table[2]  = {1'b0,8'h3A,1'b0}; // COLMOD
    init_table[3]  = {1'b1,8'h55,1'b0}; // RGB565 16bit
    init_table[4]  = {1'b0,8'h21,1'b0}; // INV ON
    init_table[5]  = {1'b0,8'h36,1'b0}; // MADCTL
    init_table[6]  = {1'b1,8'h00,1'b0}; // <<<< 不亮就改为8'h60
    init_table[7]  = {1'b0,8'h29,1'b1}; // DISPON
    init_table[8]  = {1'b1,8'hFF,1'b0}; // END MARK
end

reg [8:0] curr_cmd;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        lcd_res    <= 1'b1;
        lcd_cs     <= 1'b1;
        lcd_dc     <= 1'b0;
        spi_start  <= 1'b0;
        spi_tx_data<= 8'd0;
        state      <= ST_RST;
        cmd_idx    <= 12'd0;
        delay_cnt  <= 16'd0;
        init_done  <= 1'b0;
        x          <= 9'd0;
        y          <= 10'd0;
        win_step   <= 4'd0;
        byte_sel   <= 1'b0;
    end
    else begin
        spi_start <= 1'b0;
        case(state)
        ST_RST: begin
            lcd_res <= 1'b0;
            lcd_cs  <= 1'b0;
            delay_cnt <= delay_cnt + 1'b1;
            if(delay_cnt >= 16'd50000) begin
                delay_cnt <= 16'd0;
                lcd_res <= 1'b1;
                state <= ST_WAIT_DELAY;
            end
        end
        ST_WAIT_DELAY: begin
            delay_cnt <= delay_cnt + 1'b1;
            if(delay_cnt >= 16'd25000) begin
                delay_cnt <= 16'd0;
                state <= ST_INIT_SEQ;
            end
        end
        ST_INIT_SEQ: begin
            curr_cmd = init_table[cmd_idx];
            if(curr_cmd[7:0]==8'hFF) begin
                state <= ST_SET_WINDOW;
                win_step <= 4'd0;
            end
            else begin
                if(!spi_busy) begin
                    lcd_cs      <= 1'b0;
                    lcd_dc      <= curr_cmd[8];
                    spi_tx_data <= curr_cmd[7:0];
                    spi_start   <= 1'b1;
                    cmd_idx     <= cmd_idx + 1'b1;
                    if(curr_cmd[0]) begin
                        state <= ST_WAIT_DELAY;
                    end
                end
            end
        end
        ST_SET_WINDOW: begin
            if(!spi_busy) begin
                case(win_step)
                    0: begin lcd_dc<=0; spi_tx_data<=8'h2A; spi_start<=1; win_step<=win_step+1'b1; end
                    1: begin lcd_dc<=1; spi_tx_data<=8'h00; spi_start<=1; win_step<=win_step+1'b1; end
                    2: begin lcd_dc<=1; spi_tx_data<=8'h00; spi_start<=1; win_step<=win_step+1'b1; end
                    3: begin lcd_dc<=1; spi_tx_data<=8'h00; spi_start<=1; win_step<=win_step+1'b1; end
                    4: begin lcd_dc<=1; spi_tx_data<=8'hEF; spi_start<=1; win_step<=win_step+1'b1; end

                    5: begin lcd_dc<=0; spi_tx_data<=8'h2B; spi_start<=1; win_step<=win_step+1'b1; end
                    6: begin lcd_dc<=1; spi_tx_data<=8'h00; spi_start<=1; win_step<=win_step+1'b1; end
                    7: begin lcd_dc<=1; spi_tx_data<=8'h00; spi_start<=1; win_step<=win_step+1'b1; end
                    8: begin lcd_dc<=1; spi_tx_data<=8'h01; spi_start<=1; win_step<=win_step+1'b1; end
                    9: begin lcd_dc<=1; spi_tx_data<=8'h3F; spi_start<=1; win_step<=win_step+1'b1; end

                    10:begin lcd_dc<=0; spi_tx_data<=8'h2C; spi_start<=1; win_step<=4'd0; init_done<=1'b1; state<=ST_FILL_RED; end
                endcase
            end
        end
        ST_FILL_RED: begin
            lcd_cs <= 1'b0;
            lcd_dc <= 1'b1;
            if(!spi_busy) begin
                if(byte_sel == 1'b0) begin
                    spi_tx_data <= fixed_color[15:8];
                    spi_start   <= 1'b1;
                    byte_sel    <= 1'b1;
                end
                else begin
                    spi_tx_data <= fixed_color[7:0];
                    spi_start   <= 1'b1;
                    byte_sel    <= 1'b0;
                    x <= x + 1'b1;
                    if(x == 9'd239) begin
                        x <= 9'd0;
                        y <= y + 1'b1;
                        if(y == 10'd319) begin
                            y <= 10'd0;
                        end
                    end
                end
            end
        end
        default: state <= ST_RST;
        endcase
    end
end

endmodule
