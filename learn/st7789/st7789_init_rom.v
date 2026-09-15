//============================================================================
// ST7789 初始化命令ROM & 窗口配置ROM
// init_rom: {dc[1], is_delay[1], data[7:0]}
//      dc=0:命令字节 dc=1:数据字节
//      is_delay=1: data字段代表延时ms
// win_rom: 窗口设置序列 CASET RASET RAMWR
//============================================================================
module st7789_init_rom(
    input  wire [6:0] init_idx,     // 初始化序列索引
    output reg  [9:0] init_data,    // {dc,is_delay,data[7:0]}

    input  wire [3:0] win_step,     // 窗口配置步骤索引
    output reg  [8:0] win_data      // {dc, data[7:0]}
);

localparam [6:0] INIT_ROM_SIZE = 7'd62;

always @(*) begin
    case(init_idx)
        7'd0 : init_data = {1'b0,1'b0,8'h11};  // SLPOUT 退出休眠
        7'd1 : init_data = {1'b1,1'b1,8'd120}; // 延时120ms
        7'd2 : init_data = {1'b0,1'b0,8'h36};  // MADCTL 显存访问方向
        7'd3 : init_data = {1'b1,1'b0,8'h00};  // 0x00竖屏240x320
        7'd4 : init_data = {1'b0,1'b0,8'h3A};  // COLMOD像素格式
        7'd5 : init_data = {1'b1,1'b0,8'h05};  // RGB565
        7'd6 : init_data = {1'b0,1'b0,8'hB2};  // PORCH
        7'd7 : init_data = {1'b1,1'b0,8'h0C};
        7'd8 : init_data = {1'b1,1'b0,8'h0C};
        7'd9 : init_data = {1'b1,1'b0,8'h00};
        7'd10: init_data = {1'b1,1'b0,8'h33};
        7'd11: init_data = {1'b1,1'b0,8'h33};
        7'd12: init_data = {1'b0,1'b0,8'hB7};  // GCTRL门控
        7'd13: init_data = {1'b1,1'b0,8'h35};
        7'd14: init_data = {1'b0,1'b0,8'hBB};  // VCOMS
        7'd15: init_data = {1'b1,1'b0,8'h19};
        7'd16: init_data = {1'b0,1'b0,8'hC0};  // LCMCTRL
        7'd17: init_data = {1'b1,1'b0,8'h2C};
        7'd18: init_data = {1'b0,1'b0,8'hC2};  // VDVVRHEN
        7'd19: init_data = {1'b1,1'b0,8'h01};
        7'd20: init_data = {1'b0,1'b0,8'hC3};  // VRHS
        7'd21: init_data = {1'b1,1'b0,8'h12};
        7'd22: init_data = {1'b0,1'b0,8'hC4};  // VDVS
        7'd23: init_data = {1'b1,1'b0,8'h20};
        7'd24: init_data = {1'b0,1'b0,8'hC6};  // FRCTRL2帧率
        7'd25: init_data = {1'b1,1'b0,8'h0F};
        7'd26: init_data = {1'b0,1'b0,8'hD0};  // PWCTRL1电源
        7'd27: init_data = {1'b1,1'b0,8'hA4};
        7'd28: init_data = {1'b1,1'b0,8'hA1};
        7'd29: init_data = {1'b0,1'b0,8'hE0};  // PVGAMCTRL正Gamma
        7'd30: init_data = {1'b1,1'b0,8'hD0};
        7'd31: init_data = {1'b1,1'b0,8'h04};
        7'd32: init_data = {1'b1,1'b0,8'h0D};
        7'd33: init_data = {1'b1,1'b0,8'h11};
        7'd34: init_data = {1'b1,1'b0,8'h13};
        7'd35: init_data = {1'b1,1'b0,8'h2B};
        7'd36: init_data = {1'b1,1'b0,8'h3F};
        7'd37: init_data = {1'b1,1'b0,8'h54};
        7'd38: init_data = {1'b1,1'b0,8'h4C};
        7'd39: init_data = {1'b1,1'b0,8'h18};
        7'd40: init_data = {1'b1,1'b0,8'h0D};
        7'd41: init_data = {1'b1,1'b0,8'h0B};
        7'd42: init_data = {1'b1,1'b0,8'h1F};
        7'd43: init_data = {1'b1,1'b0,8'h23};
        7'd44: init_data = {1'b0,1'b0,8'hE1};  // NVGAMCTRL负Gamma
        7'd45: init_data = {1'b1,1'b0,8'hD0};
        7'd46: init_data = {1'b1,1'b0,8'h04};
        7'd47: init_data = {1'b1,1'b0,8'h0C};
        7'd48: init_data = {1'b1,1'b0,8'h11};
        7'd49: init_data = {1'b1,1'b0,8'h13};
        7'd50: init_data = {1'b1,1'b0,8'h2C};
        7'd51: init_data = {1'b1,1'b0,8'h3F};
        7'd52: init_data = {1'b1,1'b0,8'h44};
        7'd53: init_data = {1'b1,1'b0,8'h51};
        7'd54: init_data = {1'b1,1'b0,8'h2F};
        7'd55: init_data = {1'b1,1'b0,8'h1F};
        7'd56: init_data = {1'b1,1'b0,8'h1F};
        7'd57: init_data = {1'b1,1'b0,8'h20};
        7'd58: init_data = {1'b1,1'b0,8'h23};
        7'd59: init_data = {1'b0,1'b0,8'h21};  // INVON显示反转
        7'd60: init_data = {1'b0,1'b0,8'h29};  // DISPON开显示
        7'd61: init_data = {1'b1,1'b1,8'd20};  // 延时20ms
        default: init_data = {1'b1,1'b1,8'd0};
    endcase
end

always @(*) begin
    case(win_step)
        4'd0 : win_data = {1'b0,8'h2A}; // CASET 列地址
        4'd1 : win_data = {1'b1,8'h00}; // 起始高字节
        4'd2 : win_data = {1'b1,8'h00}; // 起始低字节
        4'd3 : win_data = {1'b1,8'h00}; // 结束高字节
        4'd4 : win_data = {1'b1,8'hEF}; // 结束低字节 239
        4'd5 : win_data = {1'b0,8'h2B}; // RASET 行地址
        4'd6 : win_data = {1'b1,8'h00};
        4'd7 : win_data = {1'b1,8'h00};
        4'd8 : win_data = {1'b1,8'h01};
        4'd9 : win_data = {1'b1,8'h3F}; // 结束行319
        4'd10: win_data = {1'b0,8'h2C}; // RAMWR开始写显存
        default: win_data = {1'b0,8'h00};
    endcase
end

endmodule
