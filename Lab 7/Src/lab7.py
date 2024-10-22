# -*- coding: utf-8 -*-

#%%
# import various libraries necessary to run your Python code
import pyvisa as visa # You should pip install pyvisa and restart the kernel.
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import time   # time related library
import sys,os    # system related library
ok_sdk_loc = "C:\\Program Files\\Opal Kelly\\FrontPanelUSB\\API\\Python\\x64"
ok_dll_loc = "C:\\Program Files\\Opal Kelly\\FrontPanelUSB\\API\\lib\\x64"
mpl.style.use('ggplot')
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
    time.sleep(0.05)
    dev.SetWireInValue(0x01, slave_addr)
    dev.SetWireInValue(0x02, reg_addr)
    dev.SetWireInValue(0x00, 2)  # Read trigger
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(0.05)
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
# dir = 0 => forward, dir = 1 => backward
def run_motor(direction, duration):
    pmod_util = duration + 3 * 2 ** 30
    pmod_util = pmod_util + (3 * direction) * 2 ** 28
    dev.SetWireInValue(0x04, pmod_util)
    dev.UpdateWireIns()
    time.sleep(0.2)
    dev.SetWireInValue(0x04, 0)
    dev.UpdateWireIns()
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
# This section of the code cycles through all USB connected devices to the computer.
# The code figures out the USB port number for each instrument.
# The port number for each instrument is stored in a variable named “instrument_id”
# If the instrument is turned off or if you are trying to connect to the 
# keyboard or mouse, you will get a message that you cannot connect on that port.
device_manager = visa.ResourceManager()
devices = device_manager.list_resources()
number_of_device = len(devices)

power_supply_id = -1
waveform_generator_id = -1
digital_multimeter_id = -1
oscilloscope_id = -1

# assumes only the DC power supply is connected
for i in range (0, number_of_device):

# check that it is actually the power supply
    try:
        device_temp = device_manager.open_resource(devices[i])
        print("Instrument connect on USB port number [" + str(i) + "] is " + device_temp.query("*IDN?"))
        if (device_temp.query("*IDN?") == 'HEWLETT-PACKARD,E3631A,0,3.2-6.0-2.0\r\n'):
            power_supply_id = i
        if (device_temp.query("*IDN?") == 'HEWLETT-PACKARD,E3631A,0,3.0-6.0-2.0\r\n'):
            power_supply_id = i
        if (device_temp.query("*IDN?") == 'Agilent Technologies,33511B,MY52301259,3.03-1.19-2.00-52-00\n'):
            waveform_generator_id = i
        if (device_temp.query("*IDN?") == 'Agilent Technologies,34461A,MY53208026,A.01.10-02.25-01.10-00.35-01-01\n'):
            digital_multimeter_id = i 
        if (device_temp.query("*IDN?") == 'Keysight Technologies,34461A,MY53212931,A.02.08-02.37-02.08-00.49-01-01\n'):
            digital_multimeter_id = i
        if (device_temp.query("*IDN?") == 'KEYSIGHT TECHNOLOGIES,MSO-X 3024T,MY54440318,07.50.2021102830\n'):
            oscilloscope_id = i
        device_temp.close()
    except:
        print("Instrument on USB port number [" + str(i) + "] cannot be connected. The instrument might be powered of or you are trying to connect to a mouse or keyboard.\n")
    
#%%
# Open the USB communication port with the power supply.
# The power supply is connected on USB port number power_supply_id.
# If the power supply ss not connected or turned off, the program will exit.
# Otherwise, the power_supply variable is the handler to the power supply
    
if (power_supply_id == -1):
    print("Power supply instrument is not powered on or connected to the PC.")    
else:
    print("Power supply is connected to the PC.")
    power_supply = device_manager.open_resource(devices[power_supply_id]) 
    
#%%
# Open the USB communication port with the power supply.
# The power supply is connected on USB port number power_supply_id.
# If the power supply ss not connected or turned off, the program will exit.
# Otherwise, the power_supply variable is the handler to the power supply
    
if (digital_multimeter_id == -1):
    print("Digital multimeter instrument is not powered on or connected to the PC.")    
else:
    print("Digital multimeter is connected to the PC.")
    digital_multimeter = device_manager.open_resource(devices[digital_multimeter_id]) 
    
#%%
# Open the USB communication port with the power supply.
# The power supply is connected on USB port number power_supply_id.
# If the power supply ss not connected or turned off, the program will exit.
# Otherwise, the power_supply variable is the handler to the power supply
    
if (oscilloscope_id == -1):
    print("Oscilloscope instrument is not powered on or connected to the PC.")    
else:
    print("Oscilloscope is connected to the PC.")
    oscilloscope = device_manager.open_resource(devices[oscilloscope_id]) 
    
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
print(power_supply.write("OUTPUT ON"))
write_to_device(accel_slave_addr, ctrl_reg_1_addr, ctrl_reg_1_value)  # Enable output
write_to_device(magnet_slave_addr, mr_reg_m_addr, mr_reg_m_value)  # Continuous-conversion mode
output_voltage = np.arange(3, 5.5, 0.5)
measured_accel = np.array([]) # create an empty list to hold our values
timer = np.arange(0.1, 1.1, 0.1)
try:
    for v in output_voltage:    
        accels = np.array([])
        power_supply.write("APPLy P25V, %0.2f, 0.1" % v)
        run_motor(0, 400)
        time.sleep(2)
        run_motor(1, 200)
        for i in range(10):
            accels = np.append(accels, abs(read_from_device(accel_slave_addr, z_a_reg_addr)))
        measured_accel = np.append(measured_accel, np.max(accels))
        time.sleep(1)
except KeyboardInterrupt:
    pass
print(power_supply.write("OUTPUT OFF"))

plt.figure()
plt.plot(output_voltage, measured_accel)
plt.title("Applied Volts vs. Measured Acceleration")
plt.xlabel("Applied Volts [V]")
plt.ylabel("Measured Acceleration [g]")
plt.draw()
#%%
# Define the two variables that will send data to the FPGA
# We will use WireIn instructions to send data to the FPGA
write_to_device(accel_slave_addr, ctrl_reg_1_addr, ctrl_reg_1_value)  # Enable output
write_to_device(magnet_slave_addr, mr_reg_m_addr, mr_reg_m_value)  # Continuous-conversion mode
while True:
    run_motor(1, 400)
    time.sleep(0.2)
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
    run_motor(0, 400)
    time.sleep(0.2)
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