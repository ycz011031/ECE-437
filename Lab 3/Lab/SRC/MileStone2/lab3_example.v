`timescale 1ns / 1ps
module lab3_example(
    input [3:0] button,
    output [7:0] led,
    input sys_clkn,
    input sys_clkp  
    );

    reg [1:0] state = 0;
    reg [7:0] led_register = 0;
    reg [3:0] button_reg;    
                
    wire clk;
    IBUFGDS osc_clk(
        .O(clk),
        .I(sys_clkp),
        .IB(sys_clkn)
    );
    
    assign led = ~led_register; //map led wire to led_register
    localparam STATE_INIT       = 2'd0;
    localparam STATE_ALPHA      = 2'd1;
    localparam STATE_BRAVO      = 2'd2;
    localparam STATE_CHARLIE    = 2'd3;                 
      
    always @(posedge clk)
    begin       
        button_reg = ~button;
        if (button_reg [3:0] == 4'b1110) state <= STATE_INIT;
        else
        begin
            case (state)
                STATE_INIT : begin
                    if (button_reg == (4'b0100)) state <= STATE_ALPHA;                    
                    else if (button_reg == 4'b1000) state <= STATE_BRAVO;
                    else led_register <= 8'b00000011;                                                                        
                end

                STATE_ALPHA : begin
                    if (button_reg == 4'b1000) state <= STATE_CHARLIE;                    
                    else if (button_reg == 4'b0010) state <= STATE_INIT;
                    else led_register <= 8'b00001111;                                                                        
                end

                STATE_BRAVO : begin
                    if (button_reg == 4'b0100) state <= STATE_CHARLIE;                    
                    else if (button_reg == 4'b0010) state <= STATE_INIT;
                    else led_register <= 8'b11110000;                                                                        
                end

                STATE_CHARLIE : begin
                    if (button_reg == 4'b0010) state <= STATE_INIT;                    
                    else led_register <= 8'b10101010;                                                                        
                end
                
                default: state <= STATE_INIT;
                
            endcase
        end                           
    end    
endmodule

