# -*- coding: utf-8 -*-

#%%
# import various libraries necessary to run your Python code
import time   # time related library
import sys,os    # system related library
import util
import cv2
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
    # power_supply = util.instrumentation_setup()
    width, height = 648, 486    # Define image dimensions
    HS_counter = 0
    time.sleep(1)
    util.setup_sensors(dev)
    HS_counter = HS_counter + 2
    arr, output = util.read_a_frame(dev, HS_counter)
    roi = cv2.selectROI(arr, False)    
    # Initialize KCF Tracker and Start Tracking
    tracker = cv2.legacy.TrackerKCF_create()   # Create a KCF Tracker
    flag = tracker.init(arr, roi)   # Initialize KCF Tracker with grayscale image and ROI
    last_time = 0;
    while (True):
        
        HS_counter = HS_counter + 2
        arr, read_output = util.read_a_frame(dev, HS_counter)
        x_a_read = read_output[0]
        print("x-acceleration read is " + str(x_a_read / 16000) + " g")
        y_a_read = read_output[1]
        print("y-acceleration read is " + str(y_a_read / 16000) + " g")
        z_a_read = read_output[2]
        print("z-acceleration read is " + str(z_a_read / 16000) + " g")
        x_m_read = read_output[3]
        print("x-magnetic read is " + str(x_m_read))
        y_m_read = read_output[4]
        print("y-magnetic read is " + str(y_m_read))
        z_m_read = read_output[5]
        print("z-magnetic read is " + str(z_m_read))
        flag, roi = tracker.update(arr)
        if not(flag):
            print("Tracking failure")
            # cv2.putText(frame,"Tracking failure occured!",(10,30),cv2.FONT_HERSHEY_DUPLEX,0.75,(0,255,0),2)
        p1 = (int(roi[0]), int(roi[1]))
        p2 = (int(roi[0] + roi[2]), int(roi[1] + roi[3]))
        print(roi[0] + roi[2] / 2)
        current_time = time.time()
        if roi[0] + roi[2] / 2 > width / 2 + 50:
            print("forward")
            util.run_motor(dev, 0, 10)
        elif roi[0] + roi[2] / 2 < width / 2 - 50:
            util.run_motor(dev, 1, 10)
            print("backward")
        else:
            util.run_motor(dev, 0, 0)
            print("stable")
        cv2.rectangle(arr, p1, p2, (255, 0, 0), 2, 1)
        # Display result
        cv2.imshow("image tracking", arr)
        cv2.waitKey(1)
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