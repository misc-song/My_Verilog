module serial_fsm_module(
    input clk,
    input in,
    input reset,    // Synchronous reset
    output done
); 
    parameter IDLE,BUSY;
    reg state,next_state;
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE; // Reset to IDLE state
        end else begin
            state <= next_state; // Transition to the next state
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if (in) begin
                    next_state = BUSY;
                end else begin
                    next_state = IDLE;
                end
            end
            BUSY: begin
                next_state = IDLE;
            end
        endcase
    end
    assign done = (state == BUSY); // Output done when in BUSY state
    
    

endmodule