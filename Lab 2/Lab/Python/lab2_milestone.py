# -*- coding: utf-8 -*-

#%%
# import various libraries necessary to run your Python code
import time   # time related library
import sys,os    # system related library
ok_sdk_loc = "C:\\Program Files\\Opal Kelly\\FrontPanelUSB\\API\\Python\\x64"
ok_dll_loc = "C:\\Program Files\\Opal Kelly\\FrontPanelUSB\\API\\lib\\x64"

sys.path.append(ok_sdk_loc)   # add the path of the OK library
os.add_dll_directory(ok_dll_loc)

import ok     # OpalKelly library

#%% 
# Define FrontPanel device variable, open USB communication and
# load the bit file in the FPGA
dev = ok.okCFrontPanel()  # define a device for FrontPanel communication
SerialStatus=dev.OpenBySerial("")      # open USB communication with the OK board
ConfigStatus=dev.ConfigureFPGA("lab2.bit"); # Configure the FPGA with this bit file

# Check if FrontPanel is initialized correctly and if the bit file is loaded.
# Otherwise terminate the program
print("----------------------------------------------------")
if SerialStatus == 0:
    print ("FrontPanel host interface was successfully initialized.")
else:    
    print ("FrontPanel host interface not detected. The error code number is:" + str(int(SerialStatus)))
    print("Exiting the program.")
    sys.exit ()

if ConfigStatus == 0:
    print ("Your bit file is successfully loaded in the FPGA.")
else:
    print ("Your bit file did not load. The error code number is:" + str(int(ConfigStatus)))
    print ("Exiting the progam.")
    sys.exit ()
print("----------------------------------------------------")
print("----------------------------------------------------")
#%% 
control_variable = 2; # control_variable is initialized to digital number 2
clock_divider = 50000000; # # clock_divider is initialized to digital number 10000000
for i in range(100):
    dev.UpdateWireOuts()
    counter = dev.GetWireOutValue(0x21)  # Transfer the received data in result_sum variable
    # result_difference = dev.GetWireOutValue(0x21)  # Transfer the received data in result_difference variable
    print("The counter value is " + str(int(counter))) 
    # print("The difference between the two numbers is " + str(int(result_difference)))

    print("clock_divider is initialized to " + str(int(clock_divider)))
    if counter >= 100:
        print("control_variable is initialized to " + str(5))
        dev.SetWireInValue(0x00, 5) #Input data for Variable 1 using memory space 0x00
    else:
        print("control_variable is initialized to " + str(int(control_variable)))
        dev.SetWireInValue(0x00, control_variable) #Input data for Variable 1 using memory space 0x00
    dev.SetWireInValue(0x01, clock_divider) #Input data for Variable 2 using memory space 0x01
    dev.UpdateWireIns()  # Update the WireIns
    #control_variable = (control_variable + 1) % 4
    time.sleep(0.5)                 
control_variable = 3
for i in range(100):
    dev.UpdateWireOuts()
    counter = dev.GetWireOutValue(0x21)  # Transfer the received data in result_sum variable
    # result_difference = dev.GetWireOutValue(0x21)  # Transfer the received data in result_difference variable
    print("The counter value is " + str(int(counter))) 
    # print("The difference between the two numbers is " + str(int(result_difference)))

    print("clock_divider is initialized to " + str(int(clock_divider)))
    if counter >= 100:
        print("control_variable is initialized to " + str(5))
        dev.SetWireInValue(0x00, 5) #Input data for Variable 1 using memory space 0x00
    else:
        print("control_variable is initialized to " + str(int(control_variable)))
        dev.SetWireInValue(0x00, control_variable) #Input data for Variable 1 using memory space 0x00
    dev.SetWireInValue(0x01, clock_divider) #Input data for Variable 2 using memory space 0x01
    dev.UpdateWireIns()  # Update the WireIns
    #control_variable = (control_variable + 1) % 4
    time.sleep(0.5)                 
    


dev.Close
    
#%%