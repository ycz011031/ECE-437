`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/22 02:36:21
// Design Name: 
// Module Name: I2C
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


module I2C_driver(
    output [7:0] led,
    input  clk,
    output ADT7420_A0,
    output ADT7420_A1,
    output I2C_SCL_0,
    inout  I2C_SDA_0,
    
    output reg ACK,
    output reg SCL,
    output reg SDA,
    output reg busy,
    
    output reg [5:0] State,
    input  wire [7:0] tx_byte,
    output reg [7:0] rx_byte,
    input  wire [1:0] next_step,
    output reg ready
    );
    
    localparam idle_   = 6'b000000;
    localparam start_  = 6'b000001;
    localparam tx      = 6'b000010;
    localparam tx_ack  = 6'b000100;
    localparam rx      = 6'b001000;
    localparam rx_ack  = 6'b010000;
    localparam end_    = 6'b100000;
    localparam error_  = 6'b111111;
    
    reg [2:0] bit_counter;
    reg [9:0] clk_counter;
    
    reg [7:0] rx_byte_reg;
    reg [7:0] tx_byte_reg;
    
    reg error;
    
    assign led[7] = ACK;
    assign led[6] = SCL;
    assign led[5] = SDA;
    assign led[4:0] = {5{error}};
    assign I2C_SCL_0 = SCL;
    assign I2C_SDA_0 = SDA;
    assign ADT7420_A0 = 1'b0;
    assign ADT7420_A1 = 1'b0; 
    
    initial begin
        SCL = 1'b1;
        SDA = 1'b1;
        ACK = 1'b1;
        error = 1'b0;
        ready = 1'b1;
        State = idle_;
        rx_byte = 8'b00000000;
        rx_byte_reg = 0;
        tx_byte_reg = 0;
    end
    
    always @(posedge clk) begin
        case (State)
            idle_ : begin
                busy <= 1'b0;
                if (next_step == 2'b01)begin
                     busy <= 1'b1;
                     State <= start_;
                     clk_counter <= 10'd400;
                     bit_counter <= 0;
                end
            end
            start_: begin
                case (clk_counter)
                    10'd0   : begin
                        SCL <= 1'b0;
                        SDA <= 1'bz;
                        clk_counter <= clk_counter + 1;
                    end
                    10'd400 : begin
                        SCL <= 1'b1;
                        clk_counter <= clk_counter + 1;
                    end    
                    10'd600 : begin
                        SCL <= 1'b1;
                        SDA <= 1'b0;
                        clk_counter <= clk_counter + 1;
                    end
                    10'd799 : begin
                        State <= tx;
                        tx_byte_reg <= tx_byte;
                        clk_counter <= 10'd0;
                    end
                    default : begin
                        clk_counter <= clk_counter + 1;
                    end
                endcase
            end    
                
            tx: begin
                case (clk_counter)
                    10'd0 : begin   
                        SCL <= 1'b0;
                        clk_counter <= clk_counter + 1;
                    end    
                    10'd200 : begin
                        SDA <= tx_byte_reg[bit_counter];
                        SCL <= 1'b0;
                        clk_counter <= clk_counter + 1;
                    end    
                    10'd400 : begin
                        SCL <= 1'b1;
                        clk_counter <= clk_counter + 1;
                    end
                    10'd799 : begin
                        if (bit_counter == 3'd7) begin
                            rx_byte <= rx_byte_reg;
                            State <= tx_ack;
                            bit_counter <= 3'd0;
                            end                               
                        else begin
                            bit_counter <= bit_counter + 1;
                        end
                        clk_counter <= 10'd0;
                    end
                    default : begin
                        clk_counter <= clk_counter + 1;
                    end
                endcase
            end                
                                             
            tx_ack : begin
                case (clk_counter)
                    10'd0 : begin
                        SCL <= 1'b0;
                        SDA <= 1'bz;
                        clk_counter <= clk_counter + 1;
                    end
                    10'd400 : begin
                        SCL <= 1'b1;
                        ACK <= SDA;
                        clk_counter <= clk_counter + 1;
                    end
                    10'd799 : begin
                        tx_byte_reg <= tx_byte;
                        clk_counter <= 10'd0;
                        case (next_step)
                            2'b00: begin
                                State <= end_;
                            end
                            2'b01: begin
                                State <= start_;
                            end
                            2'b10: begin
                                State <= tx;
                            end    
                            2'b11: begin
                                State <= rx;          
                            end
                        endcase
                    end
                    default : begin
                        clk_counter <= clk_counter + 1;
                    end
                endcase
            end
            
            rx: begin
                case (clk_counter)
                    10'd0 : begin
                        SCL <= 1'b0;
                        SDA <= 1'bz;
                        clk_counter <= clk_counter + 1;
                    end
                    10'd400 : begin
                        SCL <= 1'b1;
                        clk_counter <= clk_counter + 1;
                    end
                    10'd500 : begin
                        rx_byte_reg[bit_counter] <= SDA;
                        clk_counter <= clk_counter + 1;
                    end
                    10'd799 : begin
                        if (bit_counter == 3'd7) begin
                            rx_byte <= rx_byte_reg;
                            State <= rx_ack;
                            bit_counter <= 3'd0;
                        end else begin
                            bit_counter <= bit_counter + 1;
                        end
                        clk_counter <= 10'd0;
                    end
                    default : begin
                        clk_counter <= clk_counter + 1;
                    end
                endcase
            end            
            
            rx_ack : begin
                case (clk_counter)
                    10'd0 : begin
                        SCL <= 1'b0;
                        clk_counter <= clk_counter + 1;
                    end
                    10'd200: begin
                        SDA <= tx_byte_reg[0];
                        clk_counter <= clk_counter + 1;
                    end
                    10'd400 : begin
                        SCL <= 1'b1;
                        clk_counter <= clk_counter + 1;
                    end            
                    10'd799 : begin
                        clk_counter <= 10'd0;
                        tx_byte_reg <= tx_byte;
                        case (next_step)
                                2'b00: begin
                                    State <= end_;
                                end
                                2'b01: begin
                                    State <= start_;
                                end
                                2'b10: begin
                                    State <= tx;
                                end    
                                2'b11: begin
                                    State <= rx;           
                                end
                        endcase    
                    end
                    default : begin
                        clk_counter <= clk_counter + 1;
                    end    
                endcase
            end
            
            end_ : begin
                case (clk_counter)
                    10'd0: begin
                        SCL <= 1'b0;
                        SDA <= 1'b0;
                        clk_counter <= clk_counter + 1;
                    end
                    10'd400: begin
                        SCL <= 1'b1;
                        SDA <= 1'b0;
                        clk_counter <= clk_counter + 1;
                    end       
                    10'd600 : begin
                        SCL <= 1'b1;
                        SDA <= 1'b1;
                        clk_counter <= 10'd0;
                        State <= idle_;
                    end
                    default : begin
                        clk_counter <= clk_counter + 1;
                    end
                endcase
             end    
         default : begin
            error <= 1'b1;
         end
       endcase
    end

    always @(posedge clk) begin
        case (State)
            tx : ready <= 1'b0;
            rx : ready <= 1'b0;
            default : ready <=1'b1;
         endcase
    end         
        
        
endmodule
