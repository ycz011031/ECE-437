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
def write_to_device(slave_addr, reg_addr, value):
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns()
    dev.SetWireInValue(0x01, slave_addr)
    dev.SetWireInValue(0x02, reg_addr) 
    dev.SetWireInValue(0x03, value)
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(0.5)
    dev.SetWireInValue(0x00, 1) # Write trigger
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(0.5)
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns()  # Update the WireIns
    
#%%
def read_from_device(slave_addr, reg_addr):
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(0.2)
    dev.SetWireInValue(0x01, slave_addr)
    dev.SetWireInValue(0x02, reg_addr)
    dev.SetWireInValue(0x00, 2)  # Read trigger
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(0.2)
    dev.UpdateWireOuts()
    read = dev.GetWireOutValue(0x20)
    if slave_addr == 0x3C:
        m_L = read // 2**8
        m_H = read - (m_L * 2**8)
        read =  m_H * 2**8 + m_L
    if read >= 2**15:
        read = read - 2**16 # deal with 2's complement
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns() 
    return read
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

#%% Reg and value constants
ctrl_reg_1_addr = 0x20
ctrl_reg_1_value = 0x37
mr_reg_m_addr = 0x02
mr_reg_m_value = 0x00
accel_slave_addr = 0x32
magnet_slave_addr = 0x3C
x_a_reg_addr = 0xA8
y_a_reg_addr = 0xAA
z_a_reg_addr = 0xAC
x_m_reg_addr = 0x03
y_m_reg_addr = 0x07
z_m_reg_addr = 0x05
#%%
# Define the two variables that will send data to the FPGA
# We will use WireIn instructions to send data to the FPGA
write_to_device(accel_slave_addr, ctrl_reg_1_addr, ctrl_reg_1_value)  # Enable output
write_to_device(magnet_slave_addr, mr_reg_m_addr, mr_reg_m_value)  # Continuous-conversion mode
while True:

    print("Send GO signal to the FSM") 
    x_a_read = read_from_device(accel_slave_addr, x_a_reg_addr)
    print("x-acceleration read is " + str(x_a_read / 16000) + " g")
    #input()
    y_a_read = read_from_device(accel_slave_addr, y_a_reg_addr)
    print("y-acceleration read is " + str(y_a_read / 16000) + " g")
    #input()
    z_a_read = read_from_device(accel_slave_addr, z_a_reg_addr)
    print("z-acceleration read is " + str(z_a_read / 16000) + " g")
    #input()
    x_m_read = read_from_device(magnet_slave_addr, x_m_reg_addr)
    print("x-magnetic read is " + str(x_m_read))
    #input()
    y_m_read = read_from_device(magnet_slave_addr, y_m_reg_addr)
    print("y-magnetic read is " + str(y_m_read))
    #input()
    z_m_read = read_from_device(magnet_slave_addr, z_m_reg_addr)
    print("z-magnetic read is " + str(z_m_read))
    #input()

dev.Close
    