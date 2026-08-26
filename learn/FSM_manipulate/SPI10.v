module SPI(sys_clk,reset_n,en_sig,cs,out);

input sys_clk;
input en_sig;
input reset_n;
output reg out;
output reg cs;

reg [1:0] current_status;
reg [1:0]   next_status;
// 初始化状态
parameter [1:0] IDLE    = 2'b00;
parameter [1:0] PREPAR  = 2'b01;
parameter [1:0] SEND    = 2'b10;
parameter [1:0] RELEASE = 2'b11;
parameter [7:0] data    = 8'b10101010;


reg spi_clk;
always@ (posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		spi_clk <= 0;
	end
	else if(current_status == SEND) begin 
		spi_clk <= spi_clk + 1'b1;
	end
end

reg [3:0] count;                


//状态切换计数
always@ (posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		count <= 4'b0000;
	end
	else if(count == 4'b1111) begin
		count <= 4'b0000;
	end
    else if(current_status != current_status) begin
        count <= 4'b0000;   // ******状态切换时清零
    end
	else begin
		count <= count + 1'b1;
	end
end
//第一段 时序逻辑 状态转换
always @ (posedge sys_clk or negedge reset_n) begin
	if(!reset_n) begin
		current_status <= IDLE;
	end
	else begin
		current_status <= next_status;
	end
end
//第二段 组合逻辑 更新状态
always @ (*) begin
    case(current_status)
    IDLE: begin
        next_status = en_sig ? PREPAR : IDLE;           //改用三目表达式 避免latch
    end
    PREPAR: begin
        next_status = (count == 4'b1111) ? SEND : PREPAR;
    end
    SEND: begin
        next_status = (count == 4'b1111) ? RELEASE : SEND;
    end
    RELEASE: begin
        next_status = (count == 4'b1111) ? IDLE : RELEASE;
    end
    default: begin
        next_status = IDLE;
    end
endcase
end
//第三段 输出 时序逻辑
always @ (posedge sys_clk or negedge reset_n) begin
    if(!reset_n) begin
        cs <= 1;
		out <= 0;           // **** out清零
	end
	else begin
        case(current_status)
            IDLE: begin
                cs <= 1;
                out <=  0;
            end
            PREPAR: begin
                cs <= 0;
                out <=  0;
            end
            SEND: begin
                cs <= 0;
                out <= data[7-bit_count];
            end
            RELEASE: begin
                cs <= 0;
                out <= 0;
            end
            default: begin
                cs <= 1;
                out <= 0;
            end
        endcase
    end
end


reg [2:0] bit_count;
always @ (posedge sys_clk or negedge reset_n) begin
    if(!reset_n) begin
        bit_count <= 3'b000;
    end
    else if(bit_count == 3'b111) begin
        bit_count <= 3'b000;
    end
    else if(current_status == SEND && spi_clk == 1)
        bit_count <= bit_count + 1'b1;
   
end


endmodule

