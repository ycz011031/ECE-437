`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/22 14:34:42
// Design Name: 
// Module Name: TS_controller
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


module TS_controller(
    input clk,
    
    input wire [31:0] PC_rx,
    output reg [31:0] PC_tx,
     
    output reg [1:0] next_step,
    output reg [7:0] tx_byte,
    input wire [7:0] rx_byte,
    input wire ready  
    );
    
    reg ready_reg;
    reg [7:0] tx_byte_reg;
    reg [7:0] rx_byte_reg;
    reg [5:0] cur_state;
    reg [31:0] PC_rx_reg;
    reg [31:0] PC_tx_reg;
    
    reg byte2_flag;
    
    localparam idle_     = 6'b000000;
    localparam start_rt  = 6'b000001;
    localparam tx_rt     = 6'b000010;
    localparam rstart_rt = 6'b000100;
    localparam rx_rt     = 6'b001000;
    localparam end_rt    = 6'b010000;
    
    localparam ns_start  = 2'b01;
    localparam ns_tx     = 2'b10;
    localparam ns_rx     = 2'b11;
    localparam ns_end    = 2'b00;
    
    localparam device_addr_wr = 8'b10010000;
    localparam device_addr_rd = 8'b10010001;
    localparam temp_reg_addr  = 8'b00000000; 
    
    initial begin
        cur_state <= idle_;
        next_step <= ns_end;
        PC_rx_reg <= 0;
        PC_tx_reg <= 0;
        tx_byte_reg <= 0;
        rx_byte_reg <= 0;
        byte2_flag  <= 1'b0;
        ready_reg <= 1'b1;
    end
    
    integer i;
    always @(posedge clk) begin
        for (i=0; i<8; i=i+1) begin
            tx_byte[i] <= tx_byte_reg[7-i];
            rx_byte_reg[i] <= rx_byte[7-i];
        end
    end        
    
    
    always @(posedge clk) begin
        case (cur_state)
            idle_ : begin
                PC_rx_reg <= PC_rx;
                if (PC_rx_reg != PC_rx) begin
                    cur_state <= start_rt;
                end
            end
            start_rt: begin
                ready_reg <= ready;
                tx_byte_reg <= device_addr_wr;
                next_step <= ns_start;                
                if (ready_reg == 1'b0 && ready == 1'b1) begin
                    cur_state <= tx_rt;
                end
            end
            tx_rt: begin
                ready_reg <= ready;
                tx_byte_reg <= temp_reg_addr;
                next_step <= ns_tx;
                if(ready_reg == 1'b0 && ready == 1'b1) begin
                    cur_state <= rstart_rt;
                end
            end
            rstart_rt : begin
                ready_reg <= ready;
                tx_byte_reg <= device_addr_rd;
                next_step <= ns_start;
                if (ready_reg == 1'b0 && ready == 1'b1) begin
                    cur_state <= rx_rt;
                end
            end
            rx_rt : begin
                ready_reg <= ready;
                tx_byte_reg <= {8{byte2_flag}};
                next_step <= ns_rx;
                if (ready_reg == 1'b0 && ready == 1'b1) begin
                    case(byte2_flag)
                        1'b0: begin
                            byte2_flag <= 1'b1;
                            for (i=0; i<8; i =i+1) begin
                                PC_tx_reg[12-i] <= rx_byte_reg[7-i];
                            end
                        end
                        1'b1: begin
                            byte2_flag <= 1'b0;
                            for (i=0; i<5; i = i+1) begin
                                PC_tx_reg[4-i] <= rx_byte_reg[7-i];
                            end
                            cur_state <= end_rt;
                        end
                    endcase
                end
             end
             end_rt : begin
                tx_byte_reg <= {8{1'b0}};
                next_step <= ns_end;
                cur_state <= idle_;
                PC_tx <= PC_tx_reg;
             end
             default : begin
                tx_byte_reg <= {8{1'b0}};
                next_step <= ns_end;
                cur_state <= idle_;
             end
         endcase
     end            
             
    
endmodule
