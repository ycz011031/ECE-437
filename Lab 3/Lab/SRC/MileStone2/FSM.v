`timescale 1ns / 1ps

module FSM
    #( parameter one_sec = 100000000,
                 half_sec = 50000000)
    (
    input  wire clk,
    input  wire[31:0] pedestrian,
    output wire[7:0] led
    );
    
    localparam STATE_Y1      = 3'd1;
    localparam STATE_G1      = 3'd2;
    localparam STATE_Y2      = 3'd3;
    localparam STATE_G2      = 3'd4;
    localparam STATE_PE1     = 3'd5;
    localparam STATE_PE2     = 3'd6;
    
    reg [3:0]       state = 0;
    reg [7:0]       led_register = 0; //R1, Y1, G1, R2, Y2, G2, R3, G3.
    reg [27:0]      counter = 0;
    reg             cross = 0;
    reg             pedestrain_reg = 1; // initialized to 1 to prevent USB set up triggering pedestrian event
    
    assign led = ~led_register; //map led wire to led_register

    always @(posedge clk)
    begin
        pedestrain_reg <= pedestrian[0];
        if ((pedestrain_reg == 1'b0) && (pedestrian[0] == 1'b1))
        begin
            cross <= 1'b1;
        end 
               
        case (state)
            STATE_G1 : begin
                led_register <= 8'b00110010;
                if (counter >= one_sec)
                begin
                     state <= STATE_Y1;
                     counter <= 0;
                end
                else 
                begin
                    counter <= counter + 1;
                end
            end
            STATE_Y1 : begin
                led_register <= 8'b01010010;
                if (counter >= half_sec && cross)
                begin
                    state <= STATE_PE1;
                    counter <= 0;
                    cross <= 0;
                end
                else if (counter >= half_sec) 
                begin
                    state <= STATE_G2;
                    counter <= 0;
                end
                else 
                begin
                    counter <= counter + 1;
                end
            end
            STATE_G2 : begin
                led_register <= 8'b10000110;
                if (counter >= one_sec)
                begin
                     state <= STATE_Y2;
                     counter <= 0;
                end               
                else 
                begin
                    counter <= counter + 1;
                end
            end
            STATE_Y2 : begin
            led_register <= 8'b10001010;
                if (counter >= half_sec && cross)
                begin
                    state <= STATE_PE2;
                    counter <= 0;
                    cross <= 0;
                end
                else if (counter >= half_sec) 
                begin
                    state <= STATE_G1;
                    counter <= 0;
                end
                else 
                begin
                    counter <= counter + 1;
                end                                                                    
            end
            STATE_PE1 : begin
                led_register <= 8'b10010001;
                if (counter >= one_sec)
                begin
                     state <= STATE_G2;
                     counter <= 0;
                end
                else 
                begin                    
                    counter <= counter + 1;
                end                                                                 
            end
            STATE_PE2 : begin
                led_register <= 8'b10010001;
                if (counter >= one_sec)
                begin
                     state <= STATE_G1;
                     counter <= 0;
                end
                else 
                begin
                    counter <= counter + 1;
                end                                                                           
            end
            default: state <= STATE_G1;
        endcase
    end
    
    
    
    
endmodule
















