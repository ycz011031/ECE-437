`timescale 1ns / 1ps
module lab3_example(
    input   wire    [4:0] okUH,
    output  wire    [2:0] okHU,
    inout   wire    [31:0] okUHU,
    inout   wire    okAA,
    output [7:0] led,
    input sys_clkn,
    input sys_clkp  
    );

    reg [3:0]       state = 0;
    reg [7:0]       led_register = 0; //R1, Y1, G1, R2, Y2, G2, R3, G3.
    reg [27:0]      counter = 0;
    reg             cross = 0;
    wire [31:0]pedestrian;
    wire okClk;            //These are FrontPanel wires needed to IO communication    
    wire [112:0]    okHE;  //These are FrontPanel wires needed to IO communication    
    wire [64:0]     okEH;  //These are FrontPanel wires needed to IO communication           
    wire clk;
    reg             pedestrain_reg = 1; // initialized to 1 to prevent USB set up triggering pedestrian event
    
    IBUFGDS osc_clk(
        .O(clk),
        .I(sys_clkp),
        .IB(sys_clkn)
    );
    
    okHost hostIF (
        .okUH(okUH),
        .okHU(okHU),
        .okUHU(okUHU),
        .okClk(okClk),
        .okAA(okAA),
        .okHE(okHE),
        .okEH(okEH)
    );
    
    localparam  endPt_count = 1;
    wire [endPt_count*65-1:0] okEHx;  
    okWireOR # (.N(endPt_count)) wireOR (okEH, okEHx);
    
    okWireIn wire10 (   .okHE(okHE), 
                        .ep_addr(8'h00), 
                        .ep_dataout(pedestrian));
                        
    assign led = ~led_register; //map led wire to led_register
    localparam STATE_Y1      = 3'd1;
    localparam STATE_G1      = 3'd2;
    localparam STATE_Y2      = 3'd3;
    localparam STATE_G2      = 3'd4;
    localparam STATE_PE1     = 3'd5;
    localparam STATE_PE2     = 3'd6;

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
                if (counter >= 100000000)
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
                if (counter >= 50000000 && cross)
                begin
                    state <= STATE_PE1;
                    counter <= 0;
                    cross <= 0;
                end
                else if (counter >= 50000000) 
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
                if (counter >= 100000000)
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
                if (counter >= 50000000 && cross)
                begin
                    state <= STATE_PE2;
                    counter <= 0;
                    cross <= 0;
                end
                else if (counter >= 50000000) 
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
                if (counter >= 100000000)
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
                if (counter >= 100000000)
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

