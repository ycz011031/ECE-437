`timescale 1ns / 1ps

module Main(   
    output [7:0] led,
    input sys_clkn,
    input sys_clkp,  
    output ADT7420_A0,
    output ADT7420_A1,
    output I2C_SCL_0,
    inout I2C_SDA_0,
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
    wire [112:0]    okHE;   
    wire [64:0]     okEH;     
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
    okWireOut wire20 (  .okHE(okHE), 
                        .okEH(okEHx[ 0*65 +: 65 ]),
                        .ep_addr(8'h20), 
                        .ep_datain(PC_tx));                 
                         
    // PC communication////////////////////////////////////////////////////////////////
  
    
    //I2C SERDES///////////////////////////////////////////////////////////////////////
    wire SCL, SDA,ACK; 
    wire [5:0] State;
    wire [7:0] tx_byte,rx_byte;
    wire [1:0] next_step;
    wire ready;
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
    
    //Instantiate the ILA module
    ila_0 ila_sample12 ( 
        .clk(ILA_Clk),
        .probe0({State, SDA, SCL, ACK}));                        
endmodule