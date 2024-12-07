`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/03 11:05:11
// Design Name: 
// Module Name: CVM300_driver
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


module CVM300_driver(
    input clk,
    
    input  CVM300_CLK_OUT,  
    output CVM300_CLK_IN,
    output CVM300_SYS_RES_N,
    output CVM300_FRAME_REQ,
    output CVM300_SPI_EN,
    output CVM300_SPI_CLK,
    input  CVM300_SPI_OUT,
    output CVM300_SPI_IN,
    input  CVM300_LVAL,
    input  CVM300_DVAL,
    input [9:0] CVM300_D,
    
    input  [31:0]PC_rx,
    output [31:0]PC_tx,
    input  [31:0]PC_command,
    input  [31:0]PC_addr,
    input  [31:0]PC_val,
    
    output  FIFO_wr_clk,
    output  FIFO_read_reset,
    output  FIFO_write_reset,
    output  FIFO_wr_enable,
    output  [31:0]FIFO_data_in,
    output  FRAME_REQ,
    
    input   FIFO_full, // currently not used
    input   FIFO_BT,
    
    output USB_ready   
    );


    wire [3:0] SPI_state;
    wire busy;
    wire command_read;
    wire rx_read;
    wire tx_read;
    wire [1:0] Spi_rw;
    wire [7:0] Spi_rx_reg;
    wire [7:0] Spi_tx_reg;
    wire [9:0] controller_state;
    //SPI SERDES
    SPI_driver SPI_driver(
    .clk(clk),
    .cur_state(SPI_state),
    
    .SPI_MISO(CVM300_SPI_OUT),
    .SPI_MOSI(CVM300_SPI_IN),
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
    //SPI controller
    SPI_controller SPI_controller(
    .clk(clk),
    .PC_rx(PC_rx),
    .PC_addr(PC_addr),
    .PC_val(PC_val),
    .PC_tx(PC_tx),
    .command_read(command_read),
    .rx_read(rx_read),
    .tx_read(tx_read),
    .rw(Spi_rw),
    .tx_byte(Spi_tx_reg),
    .rx_byte(Spi_rx_reg),
    .busy(busy),
    .cur_state(controller_state)
    );

    // Reset control////////////////////////////////////////////////////////////////
    
    // Clock generation//////////////////////////////////////////////////////////////////
    reg CVM_Clk;

    reg [23:0] ClkDivCVM = 24'd0;
    assign CVM300_CLK_IN = CVM_Clk;

    always @(posedge clk) begin        
        if (ClkDivCVM == 4) begin
            CVM_Clk <= !CVM_Clk;                       
            ClkDivCVM <= 0;
        end else begin                        
            ClkDivCVM <= ClkDivCVM + 1'b1;
        end
    end
    
    // Frame request && Reset set/////////////////////////
    reg reset = 1;
    reg started = 0;
    reg frame_request = 0;
    reg [15:0] HS_counter = 0;
    assign FRAME_REQ = frame_request;
    always @(posedge CVM_Clk) begin        
        if (PC_command[0] == 1) begin
            reset <= 1;
            started <= 1;
            HS_counter <= 16'd1;
        end
        else begin
            if (started) reset <= 0;
            else reset <= 1;
        end
        
        if (PC_command[16:1] == HS_counter && started == 1'b1) begin
            HS_counter <= HS_counter + 1;
            frame_request <= 1'b1;
        end
        else begin
            frame_request <= 1'b0;    
        end
        
    end
    assign CVM300_SYS_RES_N = ~reset;
    assign CVM300_FRAME_REQ = frame_request;
    assign FIFO_read_reset = frame_request;
    assign FIFO_write_reset = frame_request;
    reg[31:0] FIFO_data_in_reg;
    reg FIFO_ready_reg;
    reg FIFO_wrena_reg;
    reg read_flag=1'b0;
    reg CMV_clk_CDC;
    reg CMV_clk;
    reg CMV_clk_reg;
    
    always @(posedge clk) begin
        CMV_clk_CDC <= CVM300_CLK_OUT;
        CMV_clk <= CMV_clk_CDC;
        CMV_clk_reg <= CMV_clk;
        if (CMV_clk ==1'b0 && CMV_clk_reg == 1'b1) begin
            if (CVM300_LVAL == 1'b1 && CVM300_DVAL == 1'b1) begin
                FIFO_data_in_reg[9:0] <= CVM300_D;
                FIFO_data_in_reg[31:10] <= 0;
                read_flag <= 1'b1;
                FIFO_wrena_reg <= 1'b1;
            end
        end
        else FIFO_wrena_reg <= 1'b0;    
        if (CVM300_LVAL == 1'b0 && CVM300_DVAL == 1'b0) begin
            if (read_flag == 1'b1) FIFO_ready_reg <= 1'b1;  
            read_flag <= 1'b0;
        end
        if (FIFO_BT == 1'b1) FIFO_ready_reg <= 1'b0;    
    end
    
    assign FIFO_data_in = FIFO_data_in_reg;
    assign FIFO_wr_enable = FIFO_wrena_reg;
    assign FIFO_wr_clk = clk;
    assign USB_ready = FIFO_ready_reg;
    
    
endmodule