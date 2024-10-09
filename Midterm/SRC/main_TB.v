`timescale 1ns / 1ps

module Main_TB();
    
    //I2C SERDES///////////////////////////////////////////////////////////////////////
    wire SCL, SDA, ACK; 
    wire [5:0] State;
    wire [7:0] tx_byte,rx_byte;
    wire [1:0] next_step;
    wire ready;
    wire ADT7420_A0;
    wire ADT7420_A1;
    wire I2C_SCL_0;
    wire I2C_SDA_0;
    reg [31:0]     PC_rx;
    wire [31:0]     PC_tx;
    reg clk = 1;
    I2C_driver I2C_SERDES (        
        .led(led),
        .clk(clk),
        .ADT7420_A0(ADT7420_A0),
        .ADT7420_A1(ADT7420_A1),
        .I2C_SCL_0(I2C_SCL_0),
        .I2C_SDA_0(I2C_SDA_0),             

        .ACK(ACK),
        .SCL(SCL),
        .SDA(SDA),
        .State(State),
        
        .tx_byte(tx_byte),
        .rx_byte(rx_byte),
        .next_step(next_step),
        .ready(ready)
        );
    // I2C SERDES ////////////////////////////////////////////////////////////////////////
    
    
    //Sensor Controller///////////////////////////////////////////////////////////////////
    TS_controller TS_controller(
        .clk(clk),
        
        .PC_rx(PC_rx),
        .PC_tx(PC_tx),
        
        .next_step(next_step),
        .tx_byte(tx_byte),
        .rx_byte(rx_byte),
        .ready(ready)
    );
    //Sensor Controller/////////////////////////////////////////////////////////////////////    
    
        
    always begin
        #5 clk = ~clk;
    end
    
    initial begin
        #0 PC_rx <= 0;
        #400 PC_rx <= 1;
    end                    
endmodule