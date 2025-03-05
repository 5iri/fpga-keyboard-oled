import serial
ser = serial.Serial('/dev/ttyUSB1', 115200)  # Adjust for your OS
ser.write(b'1')  # Send '1' character
