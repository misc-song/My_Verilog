//实现spi全擦除 W25Q16 模块


module spi(sys_clk,reset,en_sig,cs,spi_clk,out);
input sys_clk;                      // 系统时钟    50M
input reset;                        // 复位信号
input en_sig;                       // 擦除使能信号

output reg spi_clk;                 // spi时钟    

output reg cs;                      // 片选信号
reg [7:0]Mosi;                      // 主机发送数据
output reg out;
parameter WR_EN_IN = 8'h06;               // 写使能命令
parameter BE_IN  = 8'hC7;                 // 全擦除指令

// status
parameter IDLE = 4'b0001;
parameter WREN = 4'b0010;
parameter DELAY = 4'b0100;
parameter BE = 4'b1000;




reg [2:0] devider_count;               //分频计数器
//产生串行时钟 12.5Mhz 对50Mhz的系统时钟进行4分频
always @(posedge sys_clk or negedge reset) begin
    if(reset == 1'b0) 
        devider_count <= 3'b0;
    else if(devider_count == 3'b11) 
        devider_count <= 1'b0;
    else
        devider_count <= devider_count+ 1'b1;
end

//时钟输出
always @(posedge sys_clk or negedge reset) begin
    if(reset == 1'b0) begin
        spi_clk <= 3'b0;
    end
    else if(devider_count == 3'b10) 
        spi_clk <= 1'b1;
    else
        spi_clk <= 1'b0;
end

reg [2:0] bit_count;               //数据位计数器
reg [3:0] state;                   //状态机状态
reg [2:0] state_count;             //状态计数器
reg [2:0] spi_count;               //spi计数器 没计数8个时钟时候切换一次状态

always@(posedge spi_clk or negedge reset) begin
    if(reset == 1'b0 ) begin
        spi_count <= 3'b0;
    end
    else if(spi_count == 3'b111) begin
        spi_count <= 3'b0;
    end
    else if(en_sig == 1'b1 ) begin
        spi_count <= spi_count + 1'b1;      //使能信号有效时候 状态计数器开始计数
    end
end


always@(posedge spi_clk or negedge reset) begin
    if(reset == 1'b0 ) begin
        state_count <= 3'b0;
    end
    else if( en_sig == 1'b1 && spi_count == 3'b111) begin
        state_count <= state_count + 1'b1;      //使能信号有效时候 状态计数器开始计数
    end
  
end

always@(posedge spi_clk or negedge reset) begin
    if(reset == 1'b0) begin
        state <= IDLE;
    end
    else begin
        case(state)
            IDLE: begin
                if(en_sig == 1'b1 && state_count == 3'b001) begin
                    state <= WREN;
                end
                else begin
                    state <= IDLE;
                end
            end
            WREN: begin
                if(state_count == 3'b100) begin
                    state <= DELAY;
                end
                 
            end
            DELAY: begin
                if(state_count == 3'b110) begin
                    state <= BE;
                end
            end
            BE: begin
                if(state_count == 3'b111) begin
                    state <= IDLE;
                end
            end
        endcase
    end
end

// data sender
always@(posedge spi_clk or negedge reset) begin
    if(reset == 1'b0) begin
        cs <= 1'b1;
        Mosi <= 8'b0;
    end
    else begin
        case(state)
            WREN: begin
                cs <= 1'b0;
                Mosi <= WR_EN_IN;
            end
            BE: begin
                cs <= 1'b0;
                Mosi <= BE_IN;
            end
            default: begin
                cs <= 1'b1;
                Mosi <= 8'b0;
            end
        endcase
    end
end

always@(posedge spi_clk or negedge reset) begin
    if(reset == 1'b0) begin
        out <= 1'b0;
        bit_count <= 3'b0;
    end
    else if(state == WREN ) begin
        out <=  Mosi[7-bit_count];
        bit_count <= bit_count + 1'b1;
    end
    else if(state == BE) begin
        out <=  Mosi[7-bit_count];
        bit_count <= bit_count + 1'b1;
    end
    else begin
        out <= 1'b0;
        bit_count <= 3'b0;
    end
end


endmodule