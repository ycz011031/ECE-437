`timescale 1ns / 1ps

module Main(   
    output [7:0] led,
    input sys_clkn,
    input sys_clkp,
      
    output CVM300_CLK_OUT,
    output CVM300_SYS_RES_N,
    output CVM300_FRAME_REQ,
    output CVM300_SPI_EN,
    output CVM300_SPI_CLK,
    input CVM300_SPI_OUT,
    output  CVM300_SPI_IN,
    
    input  [4:0] okUH,
    output [2:0] okHU,
    inout  [31:0] okUHU,
    inout  okAA
);

    
    // Clock generation//////////////////////////////////////////////////////////////////
    reg ILA_Clk;
    reg CVM_Clk;
    wire clk;
    reg [23:0] ClkDivILA = 24'd0;
    reg [23:0] ClkDivCVM = 24'd0;
    assign CVM300_CLK_OUT = CVM_Clk;
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
    always @(posedge clk) begin        
        if (ClkDivCVM == 4) begin
            CVM_Clk <= !CVM_Clk;                       
            ClkDivCVM <= 0;
        end else begin                        
            ClkDivCVM <= ClkDivCVM + 1'b1;
        end
    end
    //PC communication/////////////////////////////////////////////////////////////////
    // TODO verify OK communication function
    wire [31:0]     PC_rx;
    wire [31:0]     PC_tx;
    wire [31:0]     PC_pipe_out;
    wire [31:0]     PC_reset;
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
                        .ep_dataout(PC_reset));
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
//    okPipeOut pipe0 (  .okHE(okHE), 
//                        .okEH(okEHx[ 0*65 +: 65 ]),
//                        .ep_addr(8'hA0), 
//                        .ep_datain(PC_pipe_out),
//                        .ep_read(ready_to_read));    
    // Reset control////////////////////////////////////////////////////////////////
    reg reset = 1;
    reg started = 0;
    always @(posedge CVM_Clk) begin        
        if (PC_reset[0] == 1) begin
            reset <= 1;
            started <= 1;
        end
        else begin
            if (started) reset <= 0;
            else reset <= 1;
        end
    end
    assign CVM300_SYS_RES_N = ~reset;
    
    // PC communication////////////////////////////////////////////////////////////////
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

    //Instantiate the ILA module
    ila_0 ila_sample12 ( 
        .clk(clk),
        .probe0({CVM300_SPI_EN, CVM300_SPI_CLK, CVM300_SPI_OUT, CVM300_SPI_IN, CVM300_CLK_OUT, CVM300_SYS_RES_N, CVM300_FRAME_REQ, busy}),
        .probe1(PC_rx),
        .probe2(PC_tx),
        .probe3(SPI_state),
        .probe4(controller_state));
endmodule