`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/22 11:22:46
// Design Name: 
// Module Name: I2C_TB
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


module I2C_TB();

    reg clk = 1;
    wire [7:0] led;
    wire ADT7420_A0;
    wire ADT7420_A1;
    wire I2C_SCL;
    wire I2C_SDA;
    
    wire ACK;
    wire SCL;
    wire SDA;
    
    wire [5:0] State;
    reg  [7:0] tx_byte;
    wire [7:0] rx_byte;
    reg  [1:0] next_step;
    wire  ready;
    
    I2C_driver I2C_driver(
        .clk(clk),
        .led(led),
        .ADT7420_A0(ADT7420_A0),
        .ADT7420_A1(ADT7420_A1),
        .I2C_SCL_0(I2C_SCL),
        .I2C_SDA_0(I2C_SDA),
        .ACK(ACK),
        .SCL(SCL),
        .SDA(SDA),
        .State(State),
        .tx_byte(tx_byte),
        .rx_byte(rx_byte),
        .next_step(next_step),
        .ready(ready));
        
    
    always begin
        #5 clk = ~clk;
    end
    
    initial begin
        #0 tx_byte <= 8'd255;
        #0 next_step <= 2'b01;  //start
        #400 next_step <= 2'b10;    //tx
        
    end     
    




endmodule
