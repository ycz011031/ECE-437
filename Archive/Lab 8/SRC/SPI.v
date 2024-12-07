`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/19 12:59:21
// Design Name: 
// Module Name: SPI
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


module SPI_driver(
    input  wire clk,
    output reg [2:0] cur_state,
    
    input wire  SPI_MISO,
    output reg  SPI_MOSI,
    output reg  SPI_CLK,
    output reg  SPI_EN,
    
    output reg busy,
    input wire command_read,
    input wire rx_read,
    input wire tx_read,    
    input wire [1:0] Spi_rw,
    output reg [7:0] Spi_rx_reg,
    input wire [7:0] Spi_tx_reg  
    );

localparam IDLE  = 3'b000;
localparam SPITX = 3'b001;
localparam SPIRX = 3'b010;
localparam SPIED = 3'b100;


reg [1:0] command_FIFO[15:0];
reg [7:0] tx_FIFO[15:0];
reg [7:0] rx_FIFO[15:0];
reg [3:0] command_addrw;
reg [3:0] command_addrr;
reg [3:0] tx_addrw;
reg [3:0] tx_addrr;
reg [3:0] rx_addrw;
reg [3:0] rx_addrr;
wire command_empty;
wire tx_empty;
wire rx_empty;

initial begin
    cur_state = 7'd0;
    SPI_MOSI = 1'b0;
    SPI_CLK = 1'b0;
    SPI_EN = 1'b0;
    busy = 1'b0;
    command_addrw = 4'b0;
    command_addrr = 4'd0;
    tx_addrw = 4'd0;
    tx_addrr = 4'd0;
    rx_addrw = 4'd0;
    rx_addrr = 4'd0;
end

assign tx_empty = &(~(tx_addrr^tx_addrw));
assign rx_empty = &(~(rx_addrr^rx_addrw));
assign command_empty = &(~(command_addrr^command_addrw));

always @(posedge clk) begin
    if (command_read == 1'b1) begin
        command_FIFO[command_addrw] <= Spi_rw;
        command_addrw <= command_addrw + 1;
    end
    if (tx_read == 1'b1) begin
        tx_FIFO[tx_addrw] <= Spi_tx_reg;
        tx_addrw <= tx_addrw + 1;
    end
    if (rx_read == 1'b1) begin
        if(rx_empty != 1'b1) begin
            Spi_rx_reg <= rx_FIFO[rx_addrr];
            rx_addrr <= rx_addrr + 1;
        end else begin
            Spi_rx_reg <= 8'b11111111;
        end
    end
end


reg[2:0] bit_counter;
reg[2:0] clk_counter;
reg[7:0] rx_temp_reg;

always @(posedge clk) begin    
        case(cur_state)
            IDLE : begin
                busy <= 1'b0;
                if(command_empty == 1'b0)begin
                    if(command_FIFO[command_addrr] == 2'b01)begin
                        command_addrr  <= command_addrr + 1;
                        cur_state      <= SPITX;
                        clk_counter    <= 3'b000;
                        bit_counter    <= 3'b111;
                        busy <= 1'b1;
                    end
                    //add error detection if the first command out of IDLE is rx, this is incorrectly set by the controller
                    // also add error detection if when entering TX, check for TX_FIFO empty, if not, controller is incorrectly set
                end
            end
            SPITX: begin    
                case(clk_counter)
                    3'b000 : begin
                        SPI_EN   <= 1'b1;
                        SPI_CLK  <= 1'b0;
                        SPI_MOSI <= tx_FIFO[tx_addrr][bit_counter];
                        busy <= 1'b1;
                        clk_counter <= clk_counter + 1;
                    end
                    3'b100 : begin
                        SPI_CLK <= 1'b1;
                        clk_counter <= clk_counter + 1;
                    end    
                    3'b111 : begin
                        if(bit_counter != 3'b000) begin
                            bit_counter <= bit_counter -1;
                            clk_counter <= 3'b000;
                        end else begin
                            bit_counter <= 3'b111;
                            clk_counter <= 3'b000;
                            tx_addrr <= tx_addrr + 1;
                            if(command_empty == 1'b1)cur_state   <= SPIED;
                            else begin
                                if (command_FIFO[command_addrr] == 2'b01) cur_state <= SPITX;
                                else cur_state <= SPIRX;
                                command_addrr <= command_addrr + 1;
                                //add error detection if 2'b10 or 2'b01 is not the data read from the FIFO
                            end
                        end 
                    end
                    default : begin 
                        clk_counter <= clk_counter + 1;        
                    end
                endcase                                  
            end
            SPIRX: begin
                case(clk_counter)
                    3'b000 : begin
                        SPI_EN  <= 1'b1;
                        SPI_CLK <= 1'b0;                
                        clk_counter <= clk_counter + 1;    
                    end
                    3'b100 : begin
                        SPI_CLK  <= 1'b1;
                        rx_temp_reg[bit_counter] <= SPI_MISO;
                        clk_counter <= clk_counter +1;
                    end
                    3'b111 : begin
                        if(bit_counter != 3'b000) begin
                            bit_counter <= bit_counter - 1;
                            clk_counter <= 3'b000;
                        end else begin
                            bit_counter <= 3'b111;
                            clk_counter <= 3'b000;
                            rx_FIFO[rx_addrw] <= rx_temp_reg;
                            rx_addrw <= rx_addrw + 1;
                            if(command_empty == 1'b1) cur_state <= SPIED;
                            else begin
                                if(command_FIFO[command_addrr] == 2'b01) cur_state <= SPITX;
                                else cur_state <= SPIRX;
                                command_addrr <= command_addrr + 1;
                            end
                        end        
                    end
                    default : begin
                        clk_counter <= clk_counter + 1;
                    end
                endcase
            end
            SPIED : begin
                case(clk_counter)
                    3'b000 : begin
                        SPI_EN  <=1'b1;
                        SPI_CLK <=1'b0;
                        clk_counter <= clk_counter + 1;
                    end
                    3'b100 : begin
                        SPI_EN   <= 1'b0;
                        SPI_CLK  <= 1'b0;
                        SPI_MOSI <= 1'b0;
                        clk_counter <= 3'b000;
                        cur_state <= IDLE;
                    end   
                    default : begin
                        clk_counter <= clk_counter + 1;
                    end
                endcase
            end         
        endcase
end                        
                            
endmodule    