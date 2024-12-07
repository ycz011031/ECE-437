`timescale 1ns / 1ps

module Main(   
    output [7:0] led,
    input sys_clkn,
    input sys_clkp,
    
    output ADT7420_A0,
    output ADT7420_A1,
    output I2C_SCL_1,
    inout  I2C_SDA_1,
    
    input  CVM300_CLK_OUT,  
    output CVM300_CLK_IN,
    output CVM300_SYS_RES_N,
    output CVM300_FRAME_REQ,
    output CVM300_SPI_EN,
    output CVM300_SPI_CLK,
    input  CVM300_SPI_OUT,
    output CVM300_SPI_IN,
    input  CVM300_Line_valid,
    input  CVM300_Data_valid,
    input [9:0] CVM300_D,
    
    output PMOD_A1,
    output PMOD_A2,
    input  PMOD_A3,
    input  PMOD_A4,
    output PMOD_A7,
    output PMOD_A8,
    input  PMOD_A9,
    input  PMOD_A10,    
    
    input  [4:0] okUH,
    output [2:0] okHU,
    inout  [31:0] okUHU,
    inout  okAA
);

    wire clk;

    IBUFGDS osc_clk(
        .O(clk),
        .I(sys_clkp),
        .IB(sys_clkn)
    ); 
    
    
    
    wire [31:0]PC_rx;
    wire [31:0]PC_tx;
    wire [31:0]PC_command;
    wire [31:0]PC_addr;
    wire [31:0]PC_val;
    wire [31:0]PC_pmod;
    
    wire [31:0]PC_acl_x;
    wire [31:0]PC_acl_y;
    wire [31:0]PC_acl_z;
    wire [31:0]PC_mag_x;
    wire [31:0]PC_mag_y;
    wire [31:0]PC_mag_z;
     
    wire FIFO_wr_clk;
    wire FIFO_wr_enable;
    wire [31:0]FIFO_data_in;
    wire FIFO_full;
    wire FIFO_BT;
    wire FIFO_read_enable;
    wire FIFO_read_reset;
    wire FIFO_write_reset;
    wire USB_ready;
    
    //PC communication/////////////////////////////////////////////////////////////////
    USB_Driver USB_Driver(
        .clk(clk),
        
        .okUH(okUH),
        .okHU(okHU),
        .okUHU(okUHU),
        .okAA(okAA),
        
        .PC_rx(PC_rx),
        .PC_tx(PC_tx),
        .PC_command(PC_command),
        .PC_addr(PC_addr),
        .PC_val(PC_val),
        .PC_pmod(PC_pmod),
        
        .FIFO_wr_clk(FIFO_wr_clk),
        .FIFO_read_reset(FIFO_read_reset),
        .FIFO_write_reset(FIFO_write_reset),
        .FIFO_wr_enable(FIFO_wr_enable),
        .FIFO_data_in(FIFO_data_in),
        .FIFO_full(FIFO_full),
        .FIFO_BT(FIFO_BT),
        .FIFO_read_enable(FIFO_read_enable),
        
        .PC_acl_x(PC_acl_x),
        .PC_acl_y(PC_acl_y),
        .PC_acl_z(PC_acl_z),
        .PC_mag_x(PC_mag_x),
        .PC_mag_y(PC_mag_y),
        .PC_mag_z(PC_mag_z),
        
        .USB_ready(USB_ready));


    wire FRAME_REQ;
    // PC communication////////////////////////////////////////////////////////////////
    CVM300_driver CVM300_driver (
        .clk(clk),
        .CVM300_CLK_OUT(CVM300_CLK_OUT),
        .CVM300_CLK_IN(CVM300_CLK_IN),
        .CVM300_SYS_RES_N(CVM300_SYS_RES_N),
        .CVM300_FRAME_REQ(CVM300_FRAME_REQ),
        .CVM300_SPI_EN(CVM300_SPI_EN),
        .CVM300_SPI_CLK(CVM300_SPI_CLK),
        .CVM300_SPI_OUT(CVM300_SPI_OUT),
        .CVM300_SPI_IN(CVM300_SPI_IN),
        .CVM300_LVAL(CVM300_Line_valid),
        .CVM300_DVAL(CVM300_Data_valid),
        .CVM300_D(CVM300_D),
        
        .PC_rx(PC_rx),
        .PC_tx(PC_tx),
        .PC_command(PC_command),
        .PC_addr(PC_addr),
        .PC_val(PC_val),
        
        .FIFO_wr_clk(FIFO_wr_clk),
        .FIFO_read_reset(FIFO_read_reset),
        .FIFO_write_reset(FIFO_write_reset),
        .FIFO_wr_enable(FIFO_wr_enable),
        .FIFO_data_in(FIFO_data_in),
        .FIFO_full(FIFO_full),
        .FIFO_BT(FIFO_BT),
        .FRAME_REQ(FRAME_REQ),
        
        .USB_ready(USB_ready));
        
    // Instantiate the Sensor Driver for magnetic and acceleration module
    wire[4:0] debug_I2C_c_state;
    wire[9:0] debug_sensor_state;
    Sensor_driver Sensor_driver(
        .clk(clk),
        
        .PC_command(PC_command),    
        .PC_acl_x(PC_acl_x),        
        .PC_acl_y(PC_acl_y),
        .PC_acl_z(PC_acl_z),
        .PC_mag_x(PC_mag_x),
        .PC_mag_y(PC_mag_y),
        .PC_mag_z(PC_mag_z),
        
        .ADT7420_A0(ADT7420_A0),
        .ADT7420_A1(ADT7420_A1),
        
        .I2C_SCL(I2C_SCL_1),
        .I2C_SDA(I2C_SDA_1),
        
        .debug_I2C_c_state(debug_I2C_c_state),
        .debug_sensor_state(debug_sensor_state)
        ); 
        
    //Instantiate the PMOD driver for motor control
    PMOD_driver PMOD_driver(
        .clk(clk),
        
        .PMOD_1(PMOD_A1),
        .PMOD_2(PMOD_A2),
        .PMOD_3(PMOD_A3),
        .PMOD_4(PMOD_A4),
        .PMOD_7(PMOD_A7),
        .PMOD_8(PMOD_A8),
        .PMOD_9(PMOD_A9),
        .PMOD_10(PMOD_A10),
        .motor_fb(motor_fb),
        .PMOD_UTIL(PC_pmod)
    );
    
     
    ila_0 ILA(
        .clk(clk),
        
        .probe0({I2C_SCL_1, FRAME_REQ}),
        .probe1({CVM300_SPI_OUT,CVM300_SPI_IN}),
        .probe2(CVM300_D),
        .probe3(PC_acl_x),
        .probe4(PC_command),
        .probe5(debug_I2C_c_state),
        .probe6(debug_sensor_state),
        .probe7(PC_acl_y)
        );    
        
        
        
    //Instantiate the ILA module

endmodule