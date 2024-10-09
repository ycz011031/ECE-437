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
# We will NOT load the bit file because it will be loaded using JTAG interface from Vivado

# Check if FrontPanel is initialized correctly and if the bit file is loaded.
# Otherwise terminate the program
print("----------------------------------------------------")
if SerialStatus == 0:
    print ("FrontPanel host interface was successfully initialized.")
else:    
    print ("FrontPanel host interface not detected. The error code number is:" + str(int(SerialStatus)))
    print("Exiting the program.")
    sys.exit ()


#%% 
# Define the two variables that will send data to the FPGA
# We will use WireIn instructions to send data to the FPGA
dev.SetWireInValue(0x00, 0) 
dev.UpdateWireIns()  # Update the WireIns
time.sleep(1)
dev.SetWireInValue(0x00, 1) 
dev.UpdateWireIns()  # Update the WireIns
while True:

    print("Send GO signal to the FSM") 
    #%% 
    # Since we are using a slow clock on the FPGA to compute the results
    # we need to wait for the result to be computed
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(1)
    dev.SetWireInValue(0x00, 2) 
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(1)                 
    
    dev.UpdateWireOuts()
    x_read = dev.GetWireOutValue(0x20)
    
    print("x-axis read is " + str(x_read))
    #PC_Control = 0; # send a "stop" signal to the FSM
    #dev.SetWireInValue(0x00, PC_Control) 
    #dev.UpdateWireIns()  # Update the WireIns
    #print("Send STOP signal to the FSM")

dev.Close
    
#%%
def write_to_device(reg_addr, value):
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(1)
    dev.SetWireInValue(0x00, 1) 
    dev.SetWireInValue(0x01, value) 
    dev.UpdateWireIns()  # Update the WireIns
#%%
def read_from_device(reg_addr):
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(1)
    dev.SetWireInValue(0x00, 2) 
    dev.UpdateWireIns()  # Update the WireIns
