`timescale 1ns / 1ps

module Main(   
    output [7:0] led,
    input sys_clkn,
    input sys_clkp,
      
    output CVM300_SPI_EN,
    output CVM300_SPI_CLK,
    output CVM300_SPI_OUT,
    inout  CVM300_SPI_IN,
    
    input  [4:0] okUH,
    output [2:0] okHU,
    inout  [31:0] okUHU,
    inout  okAA
);

    
    // Clock generation//////////////////////////////////////////////////////////////////
    reg ILA_Clk;
    wire clk;
    reg [23:0] ClkDivILA = 24'd0;
    IBUFGDS osc_clk(
        .O(clk),
        .I(sys_clkp),
        .IB(sys_clkn)
    ); 
    always @(posedge clk) begin        
        if (ClkDivILA == 10) begin
            ILA_Clk <= !ILA_Clk;                       
            ClkDivILA <= 0;
        end else begin                        
            ClkDivILA <= ClkDivILA + 1'b1;
        end
    end
    // Clock generation; ///////////////////////////////////////////////////////////////
    
    //PC communication/////////////////////////////////////////////////////////////////
    // TODO verify OK communication function
    wire [31:0]     PC_rx;
    wire [31:0]     PC_tx;
    wire [31:0]     PC_pipe_out;
    wire [31:0]     PC_slave_addr;
    wire [31:0]     PC_addr;
    wire [31:0]     PC_val;
    // wire [31:0]     PMOD_UTIL;
    wire [112:0]    okHE;   
    wire [64:0]     okEH;     
    wire ready_to_read;
    localparam  endPt_count = 2;
    wire [endPt_count*65-1:0] okEHx;  
    okWireOR # (.N(endPt_count)) wireOR (okEH, okEHx);
      
    okHost hostIF (
        .okUH(okUH),
        .okHU(okHU),
        .okUHU(okUHU),
        .okClk(okClk),
        .okAA(okAA),
        .okHE(okHE),
        .okEH(okEH)
    );
    okWireIn wire10 (   .okHE(okHE), 
                        .ep_addr(8'h00), 
                        .ep_dataout(PC_rx));
    okWireIn wire11 (   .okHE(okHE), 
                        .ep_addr(8'h01), 
                        .ep_dataout(PC_slave_addr));
    okWireIn wire12 (   .okHE(okHE), 
                        .ep_addr(8'h02), 
                        .ep_dataout(PC_addr));
    okWireIn wire13 (   .okHE(okHE), 
                        .ep_addr(8'h03), 
                        .ep_dataout(PC_val));
    // okWireIn wire14 (   .okHE(okHE), 
    //                     .ep_addr(8'h04), 
    //                     .ep_dataout(PMOD_UTIL));                    
    okWireOut wire20 (  .okHE(okHE), 
                        .okEH(okEHx[ 0*65 +: 65 ]),
                        .ep_addr(8'h20), 
                        .ep_datain(PC_tx));                 
    okPipeOut pipe0 (  .okHE(okHE), 
                        .okEH(okEHx[ 0*65 +: 65 ]),
                        .ep_addr(8'hA0), 
                        .ep_datain(PC_pipe_out),
                        .ep_read(ready_to_read));    
    // PC communication////////////////////////////////////////////////////////////////
    wire [2:0] SPI_state;
    wire busy;
    wire command_read;
    wire rx_read;
    wire tx_read;
    wire [1:0] Spi_rw;
    wire [7:0] Spi_rx_reg;
    wire [7:0] Spi_tx_reg;
    //SPI SERDES
    SPI_driver(
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
    //SPI controller
    SPI_controller(
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
    .busy(busy)
    );
    //I2C SERDES///////////////////////////////////////////////////////////////////////
//    wire SCL, SDA,ACK; 
//    wire [5:0] State;
//    wire [7:0] tx_byte,rx_byte;
//    wire [1:0] next_step;
//    wire ready;
//    wire busy;
//    I2C_driver I2C_SERDES ( 
//        .busy(busy),
               
//        .led(led),
//        .clk(clk),
//        .ADT7420_A0(ADT7420_A0),
//        .ADT7420_A1(ADT7420_A1),
//        .I2C_SCL_0(I2C_SCL_1),
//        .I2C_SDA_0(I2C_SDA_1),             

//        .ACK(ACK),
//        .SCL(SCL),
//        .SDA(SDA),
//        .State(State),
        
//        .tx_byte(tx_byte),
//        .rx_byte(rx_byte),
//        .next_step(next_step),
//        .ready(ready)
//        );
//    // I2C SERDES ////////////////////////////////////////////////////////////////////////
//    wire [9:0] cur_state;
//    wire [31:0] PC_rx_reg1;
//    wire [31:0] PC_rx_reg2;
//    wire [3:0] motor_fb;
//    //Sensor Controller///////////////////////////////////////////////////////////////////
//    TS_controller TS_controller(
//        .clk(clk),
//        .PC_rx(PC_rx),
//        .PC_tx(PC_tx),
//        .PC_slave_addr(PC_slave_addr),
//        .PC_addr(PC_addr),
//        .PC_val(PC_val),
//        .next_step(next_step),
//        .tx_byte(tx_byte),
//        .rx_byte(rx_byte),
//        .cur_state(cur_state),
//        .PC_rx_reg1(PC_rx_reg1),
//        .PC_rx_reg2(PC_rx_reg2),
//        .ready(ready)
//    );
//    //Sensor Controller///////////////////////////////////////////////////////////////////// 
    
//    //PMOD Interface////////////////////////////////////////////////////////////////////////
//    PMOD_driver PMOD_driver(
//        .clk(clk),
        
//        .PMOD_1(PMOD_A1),
//        .PMOD_2(PMOD_A2),
//        .PMOD_3(PMOD_A3),
//        .PMOD_4(PMOD_A4),
//        .PMOD_7(PMOD_A7),
//        .PMOD_8(PMOD_A8),
//        .PMOD_9(PMOD_A9),
//        .PMOD_10(PMOD_A10),
//        .motor_fb(motor_fb),
//        .PMOD_UTIL(PMOD_UTIL)
//    );     
    
    //Instantiate the ILA module
    ila_0 ila_sample12 ( 
        .clk(clk),
        .probe0({PMOD_A1,PMOD_A2,PMOD_A3,PMOD_A4,PMOD_A7,PMOD_A8,PMOD_A9,PMOD_A10}),
        .probe1(PMOD_UTIL),
        .probe2(motor_fb),
        .probe3(cur_state));
endmodule