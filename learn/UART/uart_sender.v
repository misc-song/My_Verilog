module uart_sender(clk,reset,tx_data,en_sig,tx_done,tx);
   input clk;
   input reset;
   input en_sig;
   input [9:0] tx_data;         // 10bit 数据包含其实和停止位
   output reg tx_done;
   output reg tx;

   parameter baudrate = 9600;       // baudrate
   parameter clk_freq = 50_000_000; // 50MHz
   parameter clk_div = clk_freq/baudrate; // 时钟分频



    reg [3:0] current_state;
    reg [3:0] next_state;
    parameter IDLE = 4'b0001;
    parameter START = 4'b0010;
    parameter STOP = 4'b1000;
    //状态机 状态传递 部分
    always@(posedge clk or negedge reset) begin
        if(reset == 0) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end
    //状态机 状态切换 部分
    always@(*) begin
        case(current_state)
            IDLE: begin
                if(en_sig == 1'b1) begin
                    next_state = START;
                end
                else begin
                    next_state = IDLE;
                end
            end
            START: begin
                if(bit_cnt == 4'b1010) begin
                    next_state = STOP;
                end
                else begin
                    next_state = START;
                end
            end
            STOP: begin
                next_state = IDLE;
            end
        endcase
    end
    // 状态机 状态输出 部分
    always@(posedge clk or negedge reset) begin
        if(reset == 0) begin
            tx_done <= 1'b0;
        end
        case(current_state)
            IDLE: begin
                tx_done <= 1'b0;
            end
            START: begin
                tx_done <= 1'b0;
                tx <= tx_data[9-bit_cnt];
            end
            STOP: begin
                tx_done <= 1'b1;
            end
        endcase
    end


    reg [12:0] div_cnt;
    //分频计数器
    always@(posedge clk or negedge reset) begin
        if(reset == 0)begin
          div_cnt <= 13'b0;
        end
        else if(current_state == START) begin
            if(div_cnt == clk_div)begin
                div_cnt <= 13'b0;
            end
            else begin
                div_cnt <= div_cnt + 1'b1;
            end
        end
        else 
            div_cnt <= 13'b0;
    end


    reg [3:0] bit_cnt;
    //数据位计数器
    always@(posedge clk or negedge reset) begin
        if(reset == 0)begin
          bit_cnt <= 4'b0;
        end
        else if(current_state == START ) begin
            if(div_cnt == clk_div)begin
                if(bit_cnt == 4'b1010) begin
                    bit_cnt <= 4'b0;
                end
                else begin
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end
        end
        else 
            bit_cnt <= 4'b0;
    end
endmodule

        



