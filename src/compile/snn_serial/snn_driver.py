import serial
import torch

def write_input(ser: serial.Serial, idx, x):
    ser.write(chr(0))
    ser.write(chr(idx & (((1 << 8)-1) << 8)))
    ser.write(chr(idx & ((1 << 8) - 1)))
    ser.write(chr(x))

def read_output(ser: serial.Serial, x, t):
    ser.write(chr(1))
    ser.write(chr(x & (((1 << 8)-1) << 8)))
    ser.write(chr(x & ((1 << 8) - 1)))
    ser.write(chr(t))

def timestep(ser: serial.Serial):
    ser.write(chr(2)) 
    ser.write(chr(0)) 
    ser.write(chr(0)) 
    ser.write(chr(0)) 

def write_input_arr(ser: serial.Serial, x: torch.Tensor):
    x = x.flatten()
    for i in range(x.shape[0]):
        write_input(ser, i, x)

def read_output_arr(ser: serial.Serial, sz: int):
    res = torch.zeros((16,))
    for i in range(10):
        spk = read_output(ser, 0, i)
        for j in range(16):
            res[j] += int((spk & (1 << sz)) > 0)

    return res[0:sz]
    


