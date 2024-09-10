`timescale 1ns / 1ps

module lab3_TestBench();
    //Declare wires and registers that will interface with the module under test
    //Registers are initilized to known states. Wires cannot be initilized.                 
    reg clk = 1;
    wire [7:0] led;
    reg  [31:0]button;
    
    //Invoke the module that we like to test
    FSM#(.one_sec(100),.half_sec(50)) ModuleUnderTest (.pedestrian(button),.led(led),.clk(clk));
    
    // Generate a clock signal. The clock will change its state every 5ns.
    //Remember that the test module takes sys_clkp and sys_clkn as input clock signals.
    //From these two signals a clock signal, clk, is derived.
    //The LVDS clock signal, sys_clkn, is always in the opposite state than sys_clkp.     
    always begin
        #5 clk = ~clk;
    end        
      
    initial begin          
            #0 button   <= 0;                                                      
            #4000 button <= 1;
            #500  button <= 0;
            #2000       button <= 1;
        
    end

endmodule
