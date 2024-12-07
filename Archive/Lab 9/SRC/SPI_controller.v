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


module SPI_controller(
    input clk,
    
    input wire [31:0] PC_rx,
    input wire [31:0] PC_addr,
    input wire [31:0] PC_val,
    output reg [31:0] PC_tx,
    output reg command_read,
    output reg rx_read,
    output reg tx_read,
    output reg [7:0] tx_byte,
    output reg [1:0] rw,
    output reg [9:0] cur_state,
    input wire [7:0] rx_byte,
    input wire busy  
    );
    
    reg busy_reg = 0;
    reg [7:0] tx_byte_reg;
    reg [7:0] rx_byte_reg;
    reg [2:0] read_counter;
    reg [31:0] PC_rx_reg1, PC_rx_reg2;
    
    localparam idle_     = 10'b0000000001;
    localparam start_wr  = 10'b0000000010;
    localparam tx_wr1    = 10'b0000000100;
    localparam tx_wr2    = 10'b0000001000;
    localparam end_wr    = 10'b0000010000;
    localparam start_rt  = 10'b0000100000;
    localparam tx_rt     = 10'b0001000000;
    localparam rx_rt     = 10'b0010000000;
    localparam wait_rt   = 10'b0100000000;
    localparam end_rt    = 10'b1000000000;
    
    initial begin
        cur_state <= idle_;
        PC_rx_reg1 <= 0;
        PC_rx_reg2 <= 0;
        tx_byte_reg <= 0;
        rx_byte_reg <= 0;
        busy_reg <= 1'b0;
        read_counter <= 0;
    end
    
    integer i;

    always @(posedge clk) begin
        for (i=0; i<8; i=i+1) begin
            tx_byte[i] <= tx_byte_reg[i];
            rx_byte_reg[i] <= rx_byte[i];
        end
    end        
    

    always @(posedge clk) begin
        case (cur_state)
            idle_ : begin
                command_read <= 1'b0;
                tx_read <= 1'b0;
                rx_read <= 1'b0;
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
                tx_byte_reg <= {1'b1, PC_addr[6:0]};
                cur_state <= tx_wr1;
            end
            tx_wr1: begin
                tx_byte_reg <= PC_val[7:0];
                command_read <= 1'b1;
                rw <= 2'b01;
                tx_read <= 1'b1;
                cur_state <= tx_wr2;
            end
            tx_wr2: begin
                command_read <= 1'b1;
                rw <= 2'b01;
                tx_read <= 1'b1;
                cur_state <= end_wr;
            end
            end_wr : begin
                tx_byte_reg <= {8{1'b0}};
                command_read <= 1'b0;
                tx_read <= 1'b0;
                cur_state <= idle_;
            end
            //Read two byte
            start_rt: begin
                tx_byte_reg <= {1'b0, PC_addr[6:0]};
                cur_state <= tx_rt;
            end
            tx_rt: begin
                command_read <= 1'b1;
                rw <= 2'b01;
                tx_read <= 1'b1;
                cur_state <= rx_rt;
            end
            rx_rt : begin
                command_read <= 1'b1;
                tx_read <= 1'b0;
                rw <= 2'b10;
                cur_state <= wait_rt;
            end
            wait_rt : begin
                tx_byte_reg <= {8{1'b0}};
                command_read <= 1'b0;
                rw <= 2'b00;
                busy_reg <= busy;
                if (busy_reg == 1'b1 && busy == 1'b0) begin
                    rx_read <= 1'b1;
                    cur_state <= end_rt;
                end
            end
            end_rt: begin
                rx_read <= 1'b0;
                read_counter <= read_counter + 1;
                if (read_counter == 2) begin
                    PC_tx[7:0] <= rx_byte_reg;
                    read_counter <= 0;
                    cur_state <= idle_;
                end
            end
            default : begin
                tx_byte_reg <= {8{1'b0}};
                cur_state <= idle_;
            end
         endcase
     end            
             
    
endmodule
