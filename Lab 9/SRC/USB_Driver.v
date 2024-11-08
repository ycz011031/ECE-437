`timescale 1 ps / 1 ps


module USB_Driver(
    input clk,
    

    input   wire    [4:0] okUH,
    output  wire    [2:0] okHU,
    inout   wire    [31:0] okUHU,
    inout   wire    okAA,
    
    output [31:0]PC_rx,
    input  [31:0]PC_tx,
    output [31:0]PC_command,
    output [31:0]PC_addr,
    output [31:0]PC_val,
    
    input   FIFO_wr_clk,
    input   FIFO_read_reset,
    input   FIFO_write_reset,
    input   FIFO_wr_enable,
    input   [31:0]FIFO_data_in,
    output  FIFO_full, // currently not used
    output  FIFO_BT,
    output FIFO_read_enable,
    input USB_ready 
    );
    
    wire okClk;            //These are FrontPanel wires needed to IO communication    
    wire [112:0]    okHE;  //These are FrontPanel wires needed to IO communication    
    wire [64:0]     okEH;  //These are FrontPanel wires needed to IO communication     
    //This is the OK host that allows data to be sent or recived    
    okHost hostIF (
        .okUH(okUH),
        .okHU(okHU),
        .okUHU(okUHU),
        .okClk(okClk),
        .okAA(okAA),
        .okHE(okHE),
        .okEH(okEH)
    );
        
    //Depending on the number of outgoing endpoints, adjust endPt_count accordingly.
    //In this example, we have 1 output endpoints, hence endPt_count = 1.
    localparam  endPt_count = 2;
    wire [endPt_count*65-1:0] okEHx;  
    okWireOR # (.N(endPt_count)) wireOR (okEH, okEHx);    
                                                                      
    //Wire In/////////////////////////////
    okWireIn wire10 (   .okHE(okHE), 
                        .ep_addr(8'h00), 
                        .ep_dataout(PC_rx));
    okWireIn wire11 (   .okHE(okHE), 
                        .ep_addr(8'h01), 
                        .ep_dataout(PC_command));
    okWireIn wire12 (   .okHE(okHE), 
                        .ep_addr(8'h02), 
                        .ep_dataout(PC_addr));
    okWireIn wire13 (   .okHE(okHE), 
                        .ep_addr(8'h03), 
                        .ep_dataout(PC_val));
                        
                        
    //Wire Out//////////////////////////////////
    okWireOut wire20 (  .okHE(okHE), 
                        .okEH(okEHx[ 0*65 +: 65 ]),
                        .ep_addr(8'h20), 
                        .ep_datain(PC_tx));  
   
    wire [31:0] FIFO_data_out;
    wire prog_full;
    fifo_generator_0 FIFO_for_Counter_BTPipe_Interface (
        .wr_clk(FIFO_wr_clk),
        .wr_rst(FIFO_write_reset),
        .rd_clk(okClk),
        .rd_rst(FIFO_read_reset),
        .din(FIFO_data_in[9:2]),
        .wr_en(FIFO_wr_enable),
        .rd_en(FIFO_read_enable),
        .dout(FIFO_data_out),
        .full(FIFO_full),
        .prog_full(prog_full),
        .empty(FIFO_empty)    
    );
      
    okBTPipeOut CounterToPC (
        .okHE(okHE), 
        .okEH(okEHx[ 1*65 +: 65 ]),
        .ep_addr(8'ha0), 
        .ep_datain(FIFO_data_out), 
        .ep_read(FIFO_read_enable),
        .ep_blockstrobe(FIFO_BT), 
        .ep_ready(prog_full)
    );                                                                     
endmodule
