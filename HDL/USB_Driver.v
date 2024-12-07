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
    output [31:0]PC_pmod,
    
    input [31:0]PC_acl_x,
    input [31:0]PC_acl_y,
    input [31:0]PC_acl_z,
    input [31:0]PC_mag_x,
    input [31:0]PC_mag_y,
    input [31:0]PC_mag_z,
    
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
    localparam  endPt_count = 8;
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
    okWireIn wire14 (   .okHE(okHE), 
                        .ep_addr(8'h04), 
                        .ep_dataout(PC_pmod));
                                            
                        
                        
                        
    //Wire Out//////////////////////////////////
    okWireOut wire20 (  .okHE(okHE), 
                        .okEH(okEHx[ 0*65 +: 65 ]),
                        .ep_addr(8'h20), 
                        .ep_datain(PC_tx));
                        
    okWireOut wire21 (  .okHE(okHE), 
                        .okEH(okEHx[ 2*65 +: 65 ]),
                        .ep_addr(8'h21), 
                        .ep_datain(PC_acl_x));                    
                          
    okWireOut wire22 (  .okHE(okHE), 
                        .okEH(okEHx[ 3*65 +: 65 ]),
                        .ep_addr(8'h22), 
                        .ep_datain(PC_acl_y));
   
    okWireOut wire23 (  .okHE(okHE), 
                        .okEH(okEHx[ 4*65 +: 65 ]),
                        .ep_addr(8'h23), 
                        .ep_datain(PC_acl_z));
   
    okWireOut wire24 (  .okHE(okHE), 
                        .okEH(okEHx[ 5*65 +: 65 ]),
                        .ep_addr(8'h24), 
                        .ep_datain(PC_mag_x));                    
                          
    okWireOut wire25 (  .okHE(okHE), 
                        .okEH(okEHx[ 6*65 +: 65 ]),
                        .ep_addr(8'h25), 
                        .ep_datain(PC_mag_y));
   
    okWireOut wire26 (  .okHE(okHE), 
                        .okEH(okEHx[ 7*65 +: 65 ]),
                        .ep_addr(8'h26), 
                        .ep_datain(PC_mag_z));                    
                        
                        
                        
                        
                        
                        
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
        .ep_datain({FIFO_data_out[7:0], FIFO_data_out[15:8], FIFO_data_out[23:16], FIFO_data_out[31:24]}), 
        .ep_read(FIFO_read_enable),
        .ep_blockstrobe(FIFO_BT), 
        .ep_ready(prog_full)
    );                                                                     
endmodule
