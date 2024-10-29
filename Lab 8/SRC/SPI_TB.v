`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/22/2024 06:39:44 PM
// Design Name: 
// Module Name: SPI_TB
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


module SPI_TB();
    reg clk = 1;
    //inputs
    reg command_read;
    reg rx_read;
    reg tx_read;
    reg [1:0] Spi_rw;
    reg [7:0] Spi_tx_reg;
    //outputs
    wire [2:0] SPI_state;
    wire busy;
    wire [7:0] Spi_rx_reg;
    //SPI SERDES
    wire CVM300_SPI_IN;
    wire CVM300_SPI_OUT;
    wire CVM300_SPI_CLK;
    wire CVM300_SPI_EN;
       
    SPI_driver SPI_driver(
    .clk(clk),
    .cur_state(SPI_state),
    
    .SPI_MISO(CVM300_SPI_IN),
    .SPI_MOSI(CVM300_SPI_OUT),
    .SPI_CLK(CVM300_SPI_CLK),
    .SPI_EN(CVM300_SPI_EN),
    
    .busy(busy),
    .command_read(command_read),
    .rx_read(rx_read),
    .tx_read(tx_read),    
    .Spi_rw(Spi_rw),
    .Spi_rx_reg(Spi_rx_reg),
    .Spi_tx_reg(Spi_tx_reg)  
    );
    
    always begin
        #5 clk = ~clk;
    end
    
    initial begin
        #0 command_read = 0;
        #0 rx_read <= 0;
        #0 tx_read <= 0;
        #0 Spi_rw <= 0;
        #0 Spi_tx_reg <= 0;
        #20 Spi_rw <= 2'b01;
        command_read <= 1;
        Spi_tx_reg <= 8'b10011110;
        tx_read <= 1;
        #10 Spi_tx_reg <= 8'b00111100;
        tx_read <= 1;
        #10 command_read <= 0;
        tx_read <= 0;
    end    
endmodule
