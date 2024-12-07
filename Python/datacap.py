# -*- coding: utf-8 -*-

#%%
# import various libraries necessary to run your Python code
import time   # time related library
import sys,os    # system related library
import util
import cv2
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt

ok_sdk_loc = "C:\\Program Files\\Opal Kelly\\FrontPanelUSB\\API\\Python\\x64"
ok_dll_loc = "C:\\Program Files\\Opal Kelly\\FrontPanelUSB\\API\\lib\\x64"
sys.path.append(ok_sdk_loc)   # add the path of the OK library
os.add_dll_directory(ok_dll_loc)
import ok     # OpalKelly library

#%% 
# OpalKelly interface documentation:
# WireIn:
# wireIn0 -> PC_rx for triggering SPI read/write
# wireIn1 -> PC_command[0] for image sensor and accel/magne sensor initialization/reset
#          PC_command[16:1] for HS_counter for each image and sensor reading request
# wireIn2 -> PC_addr for SPI read/write reg address
# wireIn3 -> PC_val for SPI write value
# wireIn4 -> 
# WireOut:
# wireOut0 -> PC_tx for SPI read from image sensor
# wireOut1-6 -> Accel/Magn reading from sensor in order (accel-x, accel-y, accel-z, magn_x, magn_y, magn_z) 
# Pipe:
# okBTPipeOut -> Image data output from image sensor
def main():
    dev = ok.okCFrontPanel()  # define a device for FrontPanel communication
    SerialStatus=dev.OpenBySerial("")      # open USB communication with the OK board
    print("----------------------------------------------------")
    # Check if FrontPanel is initialized correctly and if the bit file is loaded.
    # Otherwise terminate the program
    if SerialStatus == 0:
        print ("FrontPanel host interface was successfully initialized.")
    else:
        print ("FrontPanel host interface not detected. The error code number is:" + str(int(SerialStatus)))
        print("Exiting the program.")
        sys.exit()
    power_supply = util.instrumentation_setup()
    width, height = 648, 486    # Define image dimensions
    HS_counter = 0
    time.sleep(1)
    util.setup_sensors(dev)
    # Initialize KCF Tracker and Start Tracking
    intencities_50_50 = np.array([])
    x_a_list = np.array([])
    y_a_list = np.array([])
    z_a_list = np.array([])
    z_a_list_max = np.array([])
    z_a_list_min = np.array([])
    x_m_list = np.array([])
    y_m_list = np.array([])
    z_m_list = np.array([])
    output_voltage = np.arange(3, 5.5, 0.5)
    power_supply.write("OUTPUT ON")
    for v in output_voltage:
        power_supply.write("APPLy P6V, %0.2f, 1" % v)
        util.run_motor(dev, 1, 300)
        time.sleep(0.1)
        z_list = np.array([])
        for i in range(10):
            time.sleep(0.1)
            HS_counter = HS_counter + 2
            arr, read_output = util.read_a_frame(dev, HS_counter)
            z_a_read = read_output[1]
            z_list = np.append(z_list, z_a_read)
        
        HS_counter = HS_counter + 2
        arr, read_output = util.read_a_frame(dev, HS_counter)
        x_a_read = read_output[0]
        x_a_list = np.append(x_a_list, x_a_read)
        #print("x-acceleration read is " + str(x_a_read / 16000) + " g")
        y_a_read = read_output[1]
        y_a_list = np.append(y_a_list, y_a_read)

        #print("y-acceleration read is " + str(y_a_read / 16000) + " g")
        z_a_read = read_output[2]
        z_a_list = np.append(z_a_list, z_a_read)

        #print("z-acceleration read is " + str(z_a_read / 16000) + " g")
        x_m_read = read_output[3]
        x_m_list = np.append(x_m_list, x_m_read)

        #print("x-magnetic read is " + str(x_m_read))
        y_m_read = read_output[4]
        y_m_list = np.append(y_m_list, y_m_read)

        #print("y-magnetic read is " + str(y_m_read))
        z_m_read = read_output[5]
        z_m_list = np.append(z_m_list, np.mean(z_list))
        z_a_list_max = np.append(z_a_list_max, np.max(z_list))
        z_a_list_min = np.append(z_a_list_min, np.min(z_list))
        time.sleep(2)
        #print("z-magnetic read is " + str(z_m_read))
        # Display result
        #if i == 50:
        #    print("standard deviation: ", np.std(arr))
        #    print("mean: ", np.mean(arr))
        #    print("spatial noise: ", np.std(arr) / np.mean(arr))
        #    print("SNR: ", 20 * np.log10(np.mean(arr) / np.std(arr)), " dB")
        #intencities_50_50 = np.append(intencities_50_50, arr[50][50])
        #cv2.imshow("image tracking", arr)
        #cv2.waitKey(1)
    #print("x acceleration reading mean: ", np.mean(x_a_list))
    #print("y acceleration reading mean: ", np.mean(y_a_list))
    #print("z acceleration reading mean: ", np.mean(z_a_list))
    #print("x magnetic reading mean: ", np.mean(x_m_list))
    #print("y magnetic reading mean: ", np.mean(y_m_list))
    #print("z magnetic reading mean: ", np.mean(z_m_list))
    #print("x acceleration reading noise: ", np.std(x_a_list))
    #print("y acceleration reading noise: ", np.std(y_a_list))
    #print("z acceleration reading noise: ", np.std(z_a_list))
    #print("x magnetic reading noise: ", np.std(x_m_list))
    #print("y magnetic reading noise: ", np.std(y_m_list))
    #print("z magnetic reading noise: ", np.std(z_m_list))
    #print("temporal noise: ", np.std(intencities_50_50))
    plt.figure()
    plt.plot(output_voltage, z_a_list)
    plt.title("Applied Volts vs. average Acceleration")
    plt.xlabel("Applied Volts [V]")
    plt.ylabel("Measured Acceleration [g]")
    plt.draw()
    plt.show()
    plt.figure()
    plt.plot(output_voltage, z_a_list_max)
    plt.title("Applied Volts vs. max Acceleration")
    plt.xlabel("Applied Volts [V]")
    plt.ylabel("Measured Acceleration [g]")
    plt.draw()
    plt.show()
    plt.figure()
    plt.plot(output_voltage, z_a_list_min)
    plt.title("Applied Volts vs. min Acceleration")
    plt.xlabel("Applied Volts [V]")
    plt.ylabel("Measured Acceleration [g]")
    plt.draw()
    plt.show()
    dev.Close

# def reading_thread(dev):
#     while True:
#         read_output = util.I2C_read_from_device(dev)
#         x_a_read = read_output[0]
#         print("x-acceleration read is " + str(x_a_read / 16000) + " g")
#         y_a_read = read_output[1]
#         print("y-acceleration read is " + str(y_a_read / 16000) + " g")
#         z_a_read = read_output[2]
#         print("z-acceleration read is " + str(z_a_read / 16000) + " g")
#         x_m_read = read_output[3]
#         print("x-magnetic read is " + str(x_m_read))
#         y_m_read = read_output[4]
#         print("y-magnetic read is " + str(y_m_read))
#         z_m_read = read_output[5]
#         print("z-magnetic read is " + str(z_m_read))
#         time.sleep(0.005)
main()