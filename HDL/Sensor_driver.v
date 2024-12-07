`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/24 15:34:37
// Design Name: 
// Module Name: Sensor_driver
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


module Sensor_driver(
    input clk,
    
    input wire[31:0] PC_command,
    
    output reg[31:0] PC_acl_x,
    output reg[31:0] PC_acl_y,
    output reg[31:0] PC_acl_z,
    
    output reg[31:0] PC_mag_x,
    output reg[31:0] PC_mag_y,
    output reg[31:0] PC_mag_z,
    
    output wire ADT7420_A0,
    output wire ADT7420_A1,
    
    output I2C_SCL,
    inout  I2C_SDA,
    
    output wire[4:0] debug_sensor_state,
    output wire[9:0] debug_I2C_c_state      
    );
    
    reg [31:0] PC_rx;
    wire [31:0] PC_tx;
    reg [31:0] PC_slave_addr;
    reg [31:0] PC_addr;
    reg [31:0] PC_val;
    
    wire SCL,SDA,ACK;
    wire [7:0] tx_byte, rx_byte;
    wire [1:0] next_step;
    wire ready;
    wire busy;
    wire[9:0] cur_state;
    
    localparam read_rx  = 31'd2;
    localparam write_rx = 31'd1;
    localparam idle_rx  = 31'd0;
    
    localparam ctrl_reg_1_addr  = 31'h20;
    localparam ctrl_reg_1_value = 31'h37;
    localparam mr_reg_m_addr  = 31'h02;
    localparam mr_reg_m_value = 31'h00;
    localparam accel_slave_addr = 31'h32;
    localparam magnet_slave_addr = 31'h3C;
    localparam x_a_reg_addr = 31'hA8;
    localparam y_a_reg_addr = 31'hAA;
    localparam z_a_reg_addr = 31'hAC;
    localparam x_m_reg_addr = 31'h03;
    localparam y_m_reg_addr = 31'h07;
    localparam z_m_reg_addr = 31'h05;
    
    
    I2C_driver I2C_SERDES ( 
        .busy(busy),
               
        .led(led),
        .clk(clk),
        .ADT7420_A0(ADT7420_A0),
        .ADT7420_A1(ADT7420_A1),
        .I2C_SCL_0(I2C_SCL),
        .I2C_SDA_0(I2C_SDA),             

        .ACK(ACK),
        .SCL(SCL),
        .SDA(SDA),
        .State(State),
        
        .tx_byte(tx_byte),
        .rx_byte(rx_byte),
        .next_step(next_step),
        .ready(ready)
        );
        
    I2C_controller I2C_controller(
        .clk(clk),
        .PC_rx(PC_rx),
        .PC_tx(PC_tx),
        .PC_slave_addr(PC_slave_addr),
        .PC_addr(PC_addr),
        .PC_val(PC_val),
        .next_step(next_step),
        .tx_byte(tx_byte),
        .rx_byte(rx_byte),
        .cur_state(cur_state),
        .PC_rx_reg1(PC_rx_reg1),
        .PC_rx_reg2(PC_rx_reg2),
        .ready(ready)
    );
    
    reg started = 1'b0;   
    reg [4:0] steps = 5'd0;
    reg [9:0] cur_state_reg;
    reg [15:0] HS_counter = 16'd1;
    reg [15:0] program_counter = 16'd0;
    
    
    localparam idle   = 5'b00000;
    localparam init_1 = 5'b00001;
    localparam init_2 = 5'b00010;
    localparam read_1 = 5'b00100;
    localparam read_2 = 5'b01000;
    
    always @(posedge clk) begin
        case (steps) 
            5'b00000 : begin
                PC_rx           <= 31'd0;
                PC_slave_addr   <= 31'd0;
                PC_addr         <= 31'd0;
                PC_val          <= 31'd0;
                program_counter <= 16'd0;
                if (PC_command [0] == 1) begin
                    started <= 1'b1;
                    HS_counter <= 16'd1;
                    steps <= init_1;
                end                            
                if (PC_command[16:1] == HS_counter && started == 1'b1) begin
                    HS_counter <= HS_counter + 1;
                    steps <= read_1;
                end
            end    
            5'b00001 : begin
                 case (program_counter)
                    16'd0: begin
                        PC_slave_addr <=  accel_slave_addr;
                        PC_addr       <= ctrl_reg_1_addr;
                        PC_val        <= ctrl_reg_1_value;
                        PC_rx         <= 31'd1;
                        steps         <= init_2;
                        program_counter <= program_counter + 1;
                    end
                    16'd1: begin
                        PC_slave_addr <= magnet_slave_addr;
                        PC_addr       <= mr_reg_m_addr;
                        PC_val        <= mr_reg_m_value;
                        PC_rx         <= 31'd1;
                        steps         <= init_2;
                        program_counter <= program_counter + 1;
                    end
                    default : begin
                        steps <= idle;
                    end    
                 endcase
            end
            5'b00010 : begin
                PC_rx <= 31'd0;
                cur_state_reg <= cur_state;
                if (cur_state == 10'd0 && cur_state_reg != cur_state) begin
                    if (program_counter == 16'd01)steps <= init_1;
                    else steps <= idle;
                end
            end
            5'b00100 : begin            
                PC_rx <= 31'd2;
                steps <= read_2;
                case (program_counter)                        
                    16'd0 : begin
                        PC_slave_addr <= accel_slave_addr;
                        PC_addr       <= x_a_reg_addr;
                    end
                    16'd1 : begin
                        PC_slave_addr <= accel_slave_addr;
                        PC_addr       <= y_a_reg_addr;
                    end
                    16'd2 : begin
                        PC_slave_addr <= accel_slave_addr;
                        PC_addr       <= z_a_reg_addr;
                    end
                    16'd3 : begin
                        PC_slave_addr <= magnet_slave_addr;
                        PC_addr       <= x_m_reg_addr;
                    end
                    16'd4 : begin
                        PC_slave_addr <= magnet_slave_addr;
                        PC_addr       <= y_m_reg_addr;
                    end
                    16'd5 : begin
                        PC_slave_addr <= magnet_slave_addr;
                        PC_addr       <= z_m_reg_addr;
                    end                             
                endcase           
            end
            5'b01000 : begin
                PC_rx <= 31'd0;
                cur_state_reg <= cur_state;
                if (cur_state == 10'd0 && cur_state_reg != cur_state) begin
                    program_counter <= program_counter + 1;
                    case (program_counter)
                        16'd0 : PC_acl_x <= PC_tx;
                        16'd1 : PC_acl_y <= PC_tx;
                        16'd2 : PC_acl_z <= PC_tx;
                        16'd3 : PC_mag_x <= PC_tx;
                        16'd4 : PC_mag_y <= PC_tx;
                        16'd5 : PC_mag_z <= PC_tx;
                    endcase
                    if (program_counter < 16'd5) steps <= read_1;
                    else steps <= idle;                               
                end
            end
        endcase
    end                
    
    
    
    //debug
    assign debug_sensor_state = steps;
    assign debug_I2C_c_state = cur_state;
    
endmodule
