# -*- coding: utf-8 -*-

#%%
# import various libraries necessary to run your Python code
import time   # time related library
import sys,os    # system related library
import numpy as np
import matplotlib.pyplot as plt
ok_sdk_loc = "C:\\Program Files\\Opal Kelly\\FrontPanelUSB\\API\\Python\\x64"
ok_dll_loc = "C:\\Program Files\\Opal Kelly\\FrontPanelUSB\\API\\lib\\x64"

sys.path.append(ok_sdk_loc)   # add the path of the OK library
os.add_dll_directory(ok_dll_loc)

import ok     # OpalKelly library
#%%
def reset_image_sensor():
    dev.SetWireInValue(0x01, 1)
    dev.UpdateWireIns()
    time.sleep(0.5)
    dev.SetWireInValue(0x01, 0)
    dev.UpdateWireIns()
    time.sleep(0.1)
#%%
def write_to_device(reg_addr, value):
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns()
    dev.SetWireInValue(0x02, reg_addr) 
    dev.SetWireInValue(0x03, value)
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(0.1)
    dev.SetWireInValue(0x00, 1) # Write trigger
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(0.1)
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns()  # Update the WireIns
    
#%%
def read_from_device(reg_addr):
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(0.1)
    dev.SetWireInValue(0x02, reg_addr)
    dev.SetWireInValue(0x00, 2)  # Read trigger
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(0.1)
    dev.UpdateWireOuts()
    read = dev.GetWireOutValue(0x20)
#    if slave_addr == 0x3C:
#        m_L = read // 2**8
#        m_H = read - (m_L * 2**8)
#        read =  m_H * 2**8 + m_L
#    if read >= 2**15:
#        read = read - 2**16 # deal with 2's complement
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns() 
    return read
#%%
def setup_image_sensor():
    print("setting up...")
    reset_image_sensor()
    write_to_device(3, 8)
    write_to_device(4, 160)
    write_to_device(57, 3)
    write_to_device(58, 44)
    write_to_device(59, 240)
    write_to_device(60, 10)
    write_to_device(69, 9)
    write_to_device(80, 2)
    write_to_device(83, 187)
    write_to_device(97, 240)
    write_to_device(98, 10)
    write_to_device(100, 112)
    write_to_device(101, 98)
    write_to_device(102, 34)
    write_to_device(103, 64)
    write_to_device(106, 94)
    write_to_device(107, 110)
    write_to_device(108, 91)
    write_to_device(109, 82)
    write_to_device(110, 80)
    write_to_device(117, 91)
    print("setting up done")
#%%
def read_a_frame(HS_counter):
    buf = bytearray(315392)
    dev.SetWireInValue(0x01, HS_counter)
    dev.UpdateWireIns()
    dev.ReadFromBlockPipeOut(0xa0, 1024, buf)
    return buf
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
HS_counter = 0
#%%
# Define the two variables that will send data to the FPGA
# We will use WireIn instructions to send data to the FPGA
time.sleep(1)
setup_image_sensor()
while (True):    
    input()
    HS_counter = HS_counter + 2
    buf = read_a_frame(HS_counter)
    width, height = 648, 480
    arr = np.frombuffer(buf, dtype=np.uint8, count=314928)
    arr = arr.reshape(486, 648)
    plt.imshow(arr, cmap = 'gray')
    plt.show()
#  # Read data from BT PipeOut

#for i in range (0, 1024, 1):    
#   result = buf[i];
#   print (result)

dev.Close
    