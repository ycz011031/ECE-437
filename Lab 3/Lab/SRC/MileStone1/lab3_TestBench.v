`timescale 1ns / 1ps

module lab3_TestBench();
    //Declare wires and registers that will interface with the module under test
    //Registers are initilized to known states. Wires cannot be initilized.                 
    reg sys_clkn=1;
    wire sys_clkp;
    wire [7:0] led;
    reg [3:0] button;
    
    //Invoke the module that we like to test
    lab3_example ModuleUnderTest (.button(button),.led(led),.sys_clkn(sys_clkn),.sys_clkp(sys_clkp));
    
    // Generate a clock signal. The clock will change its state every 5ns.
    //Remember that the test module takes sys_clkp and sys_clkn as input clock signals.
    //From these two signals a clock signal, clk, is derived.
    //The LVDS clock signal, sys_clkn, is always in the opposite state than sys_clkp.     
    assign sys_clkp = ~sys_clkn;    
    always begin
        #5 sys_clkn = ~sys_clkn;
    end        
      
    initial begin          
            #0 button <= 4'b1111;                                                      
            #200 button <= 4'b1111;
            #20 button <= 4'b1011;
            #20 button <= 4'b1101;
            #20 button <= 4'b1011;
            #20 button <= 4'b0111;
            #20 button <= 4'b1101;
            #20 button <= 4'b0111;
            #20 button <= 4'b1101;
            #20 button <= 4'b0111;
            #20 button <= 4'b1011;
            #20 button <= 4'b1101;
            #20 button <= 4'b1011;
            #20 button <= 4'b0001;            
    end

endmodule
