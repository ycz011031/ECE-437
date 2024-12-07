import time   # time related library
import pyvisa as visa # You should pip install pyvisa and restart the kernel.
import numpy as np
import cv2


def reset_sensors(dev):
    dev.SetWireInValue(0x01, 1)
    dev.UpdateWireIns()
    time.sleep(0.5)
    dev.SetWireInValue(0x01, 0)
    dev.UpdateWireIns()
    time.sleep(0.1)

def SPI_write_to_device(dev, reg_addr, value):
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
    

def SPI_read_from_device(dev, reg_addr):
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(0.1)
    dev.SetWireInValue(0x02, reg_addr)
    dev.SetWireInValue(0x00, 2)  # Read trigger
    dev.UpdateWireIns()  # Update the WireIns
    time.sleep(0.1)
    dev.UpdateWireOuts()
    read = dev.GetWireOutValue(0x20)
    dev.SetWireInValue(0x00, 0) 
    dev.UpdateWireIns() 
    return read

def setup_sensors(dev):
    print("setting up...")
    reset_sensors(dev)
    SPI_write_to_device(dev, 3, 8)
    SPI_write_to_device(dev, 4, 160)
    SPI_write_to_device(dev, 57, 3)
    SPI_write_to_device(dev, 58, 44)
    SPI_write_to_device(dev, 59, 240)
    SPI_write_to_device(dev, 60, 10)
    SPI_write_to_device(dev, 69, 9)
    SPI_write_to_device(dev, 80, 2)
    SPI_write_to_device(dev, 83, 187)
    SPI_write_to_device(dev, 97, 240)
    SPI_write_to_device(dev, 98, 10)
    SPI_write_to_device(dev, 100, 112)
    SPI_write_to_device(dev, 101, 98)
    SPI_write_to_device(dev, 102, 34)
    SPI_write_to_device(dev, 103, 64)
    SPI_write_to_device(dev, 106, 94)
    SPI_write_to_device(dev, 107, 110)
    SPI_write_to_device(dev, 108, 91)
    SPI_write_to_device(dev, 109, 82)
    SPI_write_to_device(dev, 110, 80)
    SPI_write_to_device(dev, 117, 91)
    print("setting up done")

def read_a_frame(dev, HS_counter):
    width, height = 648, 486    # Define image dimensions
    buf = bytearray(315392)
    dev.SetWireInValue(0x01, HS_counter)
    dev.UpdateWireIns()
    dev.ReadFromBlockPipeOut(0xa0, 1024, buf)
    arr = np.frombuffer(buf, dtype=np.uint8, count=314928)
    arr = arr.reshape(height, width)
    arr = cv2.cvtColor(arr,cv2.COLOR_GRAY2RGB)
    read_output = I2C_read_from_device(dev)
    return arr, read_output

# dir = 0 => forward, dir = 1 => backward
# motor running time = duration / 200 seconds
def run_motor(dev, direction, duration):
    pmod_util = duration + 3 * 2 ** 30
    pmod_util = pmod_util + (3 * direction) * 2 ** 28
    dev.SetWireInValue(0x04, pmod_util)
    dev.UpdateWireIns()
    time.sleep(0.001)
    dev.SetWireInValue(0x04, 0)
    dev.UpdateWireIns()

def I2C_read_from_device(dev):
    dev.UpdateWireOuts()
    read_output = [0,0,0,0,0,0]
    for i in range(6):
        read = dev.GetWireOutValue(0x21 + i)
        if i >= 3:
            m_L = read // 2**8
            m_H = read - (m_L * 2**8)
            read =  m_H * 2**8 + m_L
        if read >= 2**15:
            read = read - 2**16 # deal with 2's complement
        read_output[i] = read
    return read_output

def instrumentation_setup():
    # This section of the code cycles through all USB connected devices to the computer.
    # The code figures out the USB port number for each instrument.
    # The port number for each instrument is stored in a variable named “instrument_id”
    # If the instrument is turned off or if you are trying to connect to the 
    # keyboard or mouse, you will get a message that you cannot connect on that port.
    # Only need power supply for final
    device_manager = visa.ResourceManager()
    devices = device_manager.list_resources()
    number_of_device = len(devices)
    power_supply_id = -1

    # assumes only the DC power supply is connected
    for i in range (0, number_of_device):
    # check that it is actually the power supply
        try:
            device_temp = device_manager.open_resource(devices[i])
            print("Instrument connect on USB port number [" + str(i) + "] is " + device_temp.query("*IDN?"))
            if (device_temp.query("*IDN?") == 'HEWLETT-PACKARD,E3631A,0,3.2-6.0-2.0HEWLETT-PACKARD,E3631A,0,3.2-6.0-2.0\r\n'):
                power_supply_id = i
            if (device_temp.query("*IDN?") == 'HEWLETT-PACKARD,E3631A,0,3.0-6.0-2.0\r\n'):
                power_supply_id = i
            device_temp.close()
        except:
            print("Instrument on USB port number [" + str(i) + "] cannot be connected. The instrument might be powered of or you are trying to connect to a mouse or keyboard.\n")
        
    # Open the USB communication port with the power supply.
    # The power supply is connected on USB port number power_supply_id.
    # If the power supply ss not connected or turned off, the program will exit.
    # Otherwise, the power_supply variable is the handler to the power supply
        
    if (power_supply_id == -1):
        print("Power supply instrument is not powered on or connected to the PC.")    
    else:
        print("Power supply is connected to the PC.")
        power_supply = device_manager.open_resource(devices[power_supply_id]) 
    return power_supply