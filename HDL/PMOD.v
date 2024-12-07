`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/21 10:45:31
// Design Name: 
// Module Name: PMOD
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module PMOD_driver(
    input wire clk,
    output reg[3:0] motor_fb,
    
    output wire PMOD_1,
    output wire PMOD_2,
    input wire PMOD_3,
    input wire PMOD_4,
    output wire PMOD_7,
    output wire PMOD_8,
    input wire PMOD_9,
    input wire PMOD_10,
    
    input wire[31:0] PMOD_UTIL
    );

// deconcanate input signal    
wire[1:0] motor_sel;
wire[1:0] dir_sel;
wire[27:0] cycle_set;

// internal counter
reg[28:0] cycle_counter;
reg[18:0] clock_counter;

//CDC utilities
reg[31:0] CDC_REG1;
reg[31:0] CDC_REG2;

//Latches
reg[1:0] motor_sel_reg;
reg[27:0] cycle_set_reg;
reg[1:0] dir_sel_reg;

reg PMOD_CLK;
reg CLK_EN;

initial begin
    cycle_counter <= 29'd0;
    clock_counter <= 19'd0;
    motor_sel_reg <= 2'd0;
    cycle_set_reg <= 28'd0;
    PMOD_CLK <= 1'b0;
    CLK_EN   <= 1'b0;
end

always @(posedge clk)begin
        CDC_REG1 <= PMOD_UTIL;
        CDC_REG2 <= CDC_REG1;
        motor_fb <= {PMOD_3,PMOD_4,PMOD_9,PMOD_10};
end

//deconcatenate input signal vector
assign motor_sel = CDC_REG2[31:30];
assign dir_sel   = CDC_REG2[29:28];
assign cycle_set = CDC_REG2[27:0];

//settting output signal
assign PMOD_1 = PMOD_CLK & motor_sel_reg[0];
assign PMOD_2 = dir_sel_reg[0];
assign PMOD_7 = PMOD_CLK & motor_sel_reg[1];
assign PMOD_8 = dir_sel_reg[1];


always @(posedge clk) begin
    case (CLK_EN)
        1'd0 : begin
            if (motor_sel) begin
                cycle_counter <= 30'd0;
                clock_counter <= 19'd0;
                motor_sel_reg <= motor_sel;
                cycle_set_reg <= cycle_set;
                dir_sel_reg   <= dir_sel;
                CLK_EN <= 1'd1;
            end
        end
        1'd1 : begin
            case (clock_counter)
                19'd0 : begin
                    clock_counter <= clock_counter + 1;
                    cycle_counter <= cycle_counter + 1;
                    PMOD_CLK <= ~PMOD_CLK;
                end
                19'd499999 : begin
                    clock_counter <= 19'd0;
                    if(cycle_counter[28:1] == cycle_set_reg)begin
                        cycle_counter <= 30'd0;
                        motor_sel_reg <= 2'd0;
                        cycle_set_reg <= 28'd0;
                        dir_sel_reg   <= 2'd0;
                        CLK_EN        <= 1'd0;
                        PMOD_CLK      <= 1'd0;
                    end
                end
                default : clock_counter <= clock_counter + 1;
            endcase       
        end                    
    endcase                    
end                        

                          
endmodule
