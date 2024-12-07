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
    input wire [31:0] PC_slave_addr,
    input wire [31:0] PC_addr,
    input wire [31:0] PC_val,
    output reg [31:0] PC_tx,
    output reg [1:0] next_step,
    output reg [7:0] tx_byte,
    output reg [9:0] cur_state,
    output reg [7:0] PC_rx_reg1,
    output reg [7:0] PC_rx_reg2,
    input wire [7:0] rx_byte,
    input wire ready  
    );
    
    reg ready_reg;
    reg [7:0] tx_byte_reg;
    reg [7:0] rx_byte_reg;
//    reg [9:0] cur_state;
//    reg [31:0] PC_rx_reg;
    reg [31:0] PC_tx_reg;
    reg tx_flag;
    reg byte2_flag;
    
    localparam idle_     = 9'b000000001;
    localparam start_wr  = 9'b000000010;
    localparam tx_wr     = 9'b000000100;
    localparam end_wr    = 9'b000001000;
    localparam start_rt  = 9'b000010000;
    localparam tx_rt     = 9'b000100000;
    localparam rstart_rt = 9'b001000000;
    localparam rx_rt     = 9'b010000000;
    localparam end_rt    = 9'b100000000;
    
    localparam ns_start  = 2'b01;
    localparam ns_tx     = 2'b10;
    localparam ns_rx     = 2'b11;
    localparam ns_end    = 2'b00;
    
    initial begin
        cur_state <= idle_;
        next_step <= ns_end;
        PC_rx_reg1 <= 0;
        PC_rx_reg2 <= 0;
        PC_tx_reg <= 0;
        tx_byte_reg <= 0;
        rx_byte_reg <= 0;
        tx_flag <= 1'b0;
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
                PC_rx_reg1 <= PC_rx;
                PC_rx_reg2 <= PC_rx_reg1;
                if (PC_rx_reg2[0] == 1'b0 && PC_rx_reg1[0] == 1'b1) begin
                    cur_state <= start_wr;
                end
                if (PC_rx_reg2[1] == 1'b0 && PC_rx_reg1[1] == 1'b1) begin
                    cur_state <= start_rt;
                end
            end
            //Write single byte
            start_wr: begin
                ready_reg <= ready;
                tx_byte_reg <= PC_slave_addr[7:0];
                next_step <= ns_start;                
                if (ready_reg == 1'b0 && ready == 1'b1) begin
                    cur_state <= tx_wr;
                end
            end
            tx_wr: begin
                case (tx_flag)
                    1'b0: begin
                        ready_reg <= ready;
                        tx_byte_reg <= PC_addr[7:0];
                        next_step <= ns_tx;
                        if(ready_reg == 1'b0 && ready == 1'b1) begin
                            tx_flag <= 1'b1;
                        end
                    end
                    1'b1: begin
                        ready_reg <= ready;
                        tx_byte_reg <= PC_val[7:0];
                        next_step <= ns_tx;
                        if(ready_reg == 1'b0 && ready == 1'b1) begin
                            cur_state <= end_wr;
                            tx_flag <= 1'b0;
                        end
                    end
                endcase
            end
            end_wr : begin
                tx_byte_reg <= {8{1'b0}};
                next_step <= ns_end;
                cur_state <= idle_;
            end
            //Read two byte
            start_rt: begin
                ready_reg <= ready;
                tx_byte_reg <= PC_slave_addr[7:0];
                next_step <= ns_start;                
                if (ready_reg == 1'b0 && ready == 1'b1) begin
                    cur_state <= tx_rt;
                end
            end
            tx_rt: begin
                ready_reg <= ready;
                tx_byte_reg <= PC_addr[7:0];
                next_step <= ns_tx;
                if(ready_reg == 1'b0 && ready == 1'b1) begin
                    cur_state <= rstart_rt;
                end
            end
            rstart_rt : begin
                ready_reg <= ready;
                tx_byte_reg <= (PC_slave_addr[7:0] + 1);
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
                                PC_tx_reg[7-i] <= rx_byte_reg[7-i];
                            end
                        end
                        1'b1: begin
                            byte2_flag <= 1'b0;
                            for (i=0; i<8; i = i+1) begin
                                PC_tx_reg[15-i] <= rx_byte_reg[7-i];
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
                PC_tx_reg <= 0;
             end
             default : begin
                tx_byte_reg <= {8{1'b0}};
                next_step <= ns_end;
                cur_state <= idle_;
             end
         endcase
     end            
             
    
endmodule
