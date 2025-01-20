import sys
import torch
from torch import nn
import torch.nn.functional as F
import snntorch as snn
from train import Net
import matplotlib.pyplot as plt
from torchvision import datasets, transforms
from torch.utils.data import DataLoader

sz = 28
MAX_NEURONS = 1024
MAX_TILES = 512 
NEURONS_PER_TILE = 16
QUANT_VAL = 64 # for weight quantization
THRESH = 64 # must be a mutliple of quant_val

# compile MLP from snntorch
# only supports 1 membrane potential across all neurons
# only supports 0.5 leak
# no bias

img = None

def round_up(x):
    return (x // NEURONS_PER_TILE + 1) * NEURONS_PER_TILE

def compile(model): # compile MLP 
    neuron_idx = 0

    tile_idx = []
    tiles = []
    tiles_bias = []

    for name, param in model.named_parameters():
        if(not name.endswith("weight")):
            continue
        weight = param.data

        in_neurons = weight.shape[1]
        out_neurons = weight.shape[0]

        in_idx = neuron_idx
        out_idx = neuron_idx + round_up(in_neurons) 

        pad = (0, round_up(in_neurons)-in_neurons, 0, round_up(out_neurons)-out_neurons)
        weight_pad = F.pad(weight, pad, mode="constant", value=0)

        #print(weight.shape, weight_pad.shape, round_up(weight.shape[0]), round_up(weight.shape[1]))
        #print(weight_pad[0:NEURONS_PER_TILE, 0:NEURONS_PER_TILE])
        #print(weight.shape)

        for i in range(0, round_up(in_neurons) // NEURONS_PER_TILE):
            y = i*NEURONS_PER_TILE
            for j in range(0, round_up(out_neurons) // NEURONS_PER_TILE):
                x = j*NEURONS_PER_TILE
                tile_weights = weight_pad[x:x+NEURONS_PER_TILE, y:y+NEURONS_PER_TILE]
                #tile_weights = (tile_weights * THRESH).round().to(dtype=torch.int8)
                tile_idx.append([in_idx // NEURONS_PER_TILE + i, out_idx // NEURONS_PER_TILE + j])
                tiles.append(tile_weights)
                #print(tiles[-1], tile_idx[-1])

        neuron_idx = out_idx

    neuron_idx = 0

    for name, param in model.named_parameters():
        if(not name.endswith("bias")):
            continue
        bias = param.data

        in_neurons = bias.shape[0]

        in_idx = neuron_idx
        out_idx = neuron_idx + round_up(in_neurons) 

        pad = (0, round_up(in_neurons) - in_neurons)
        bias_pad = F.pad(bias, pad, mode="constant", value=0) * THRESH / QUANT_VAL

        tiles_bias += bias_pad.tolist()

        neuron_idx = out_idx

    return tile_idx, tiles, tiles_bias

def compile_to_c(model, img=None, spk=None, mem=None):
    tile_idx, tiles = compile(model)
    print("/* AUTO GENERATED CODE BY MODEL COMPILATION")
    print(" * IT IS HIGHLY DISCOURAGED TO EDIT THIS!!!")
    print(" */")

    print("/* EXPECTED OUTPUT")
    #print(f"{torch.stack(spk[0], dim=0)}")
    for i in range(len(spk[0])):
        #print(mem[1][i][0][:20].tolist())
        print(spk[2][i][0].tolist())
    print("*/")

    print("#include \"spi_driver.hpp\"")
    print("")
    print("void write_model() {")
    for i in range(len(tiles)):
        print(f"    write_tile({i}, {tile_idx[i][0]}, {tile_idx[i][1]});")
        for x in range(NEURONS_PER_TILE):
            for y in range(NEURONS_PER_TILE):
                val = int(tiles[i][y][x] * (THRESH / QUANT_VAL))
                if(val != 0):
                    print(f"    write_weight({i}, {x}, {y}, {val});")

    if(img is not None):
        for i in range(sz*sz):
            val = int(round(img[i].item() * QUANT_VAL) * (THRESH / QUANT_VAL))
            if(val != 0):
                print(f"    write_network_input({i}, {val});")

    print("}")

def compile_to_arr(model, img=None, spk=None, mem=None):
    tile_idx, tiles, tiles_bias = compile(model)
    print("/* AUTO GENERATED CODE BY MODEL COMPILATION")
    print(" * IT IS HIGHLY DISCOURAGED TO EDIT THIS!!!")
    print(" */")

    print("/* EXPECTED OUTPUT")
    #print(f"{torch.stack(spk[0], dim=0)}")
    for i in range(len(spk[0])):
        #print(mem[1][i][0][:20].tolist())
        print(spk[2][i][0].tolist())
    print("*/")

    print("uint16_t tile_idx_x[] = {")
    for i in range(len(tiles)):
        print(f"{tile_idx[i][0]},")
    print("};\n")
    print("uint16_t tile_idx_y[] = {")
    for i in range(len(tiles)):
        print(f"{tile_idx[i][1]},")
    print("};\n")

    print("int8_t weight[] = {")
    for i in range(len(tiles)):
        for x in range(NEURONS_PER_TILE):
            for y in range(NEURONS_PER_TILE):
                val = int(tiles[i][y][x] * (THRESH / QUANT_VAL))
                print(f"{val},")
    print("};")

    network_input = []
    if(img is not None):
        for i in range(sz*sz):
            network_input.append(int(round(img[i].item() * QUANT_VAL) * (THRESH / QUANT_VAL)))
    network_input += tiles_bias

    print("int8_t network_input[] = {")
    if(img is not None):
        for i in range(len(network_input)):
            val = int(network_input[i])
            print(f"{val},")

    print("};")

def compile_to_uart(model, img=None, spk_out=None, mem=None):
    ser = serial.Serial("COM4", baudrate=9600)		

    for i in range(len(tiles)):
        ser.write(f"0 {i} {tile_idx[i][0]} {tile_idx[i][1]}\n")
        for x in range(NEURONS_PER_TILE):
            for y in range(NEURONS_PER_TILE):
                ser.write(f"1 {i} {x} {y} {int(tiles[i][y][x])}\n")

    if(img is not None):
        for i in range(sz*sz):
            ser.write(f"2 {i} {int(round(img[i].item() * QUANT_VAL) * (THRESH / QUANT_VAL))}\n")

    ser.write("end\n")

def write_network_input(i, val):
    img[0][0][i // sz][i % sz] = val / THRESH

if __name__ == "__main__":
    try:
        out_path = sys.argv[2]
        sys.stdout = open(out_path, "w")
    except Exception:
        pass

    try:
        mode = sys.argv[1]
    except Exception:
        mode = "c"	

    model = Net()
    state_dict = torch.load("./mnist_28x28_spk.h5", weights_only=True)
    model.load_state_dict(state_dict)

    multiply = transforms.Lambda(lambda img: torch.clamp(img, min=0, max=1))
    transform = transforms.Compose([
        transforms.Resize((sz, sz)),
        transforms.Grayscale(),
        transforms.ToTensor(),
        multiply
        ])

    data_path='/tmp/data/mnist'
    mnist_test = datasets.MNIST(data_path, train=False, download=True, transform=transform)
    test_loader = iter(DataLoader(mnist_test, batch_size=1, shuffle=True, drop_last=True))
    img, label = next(test_loader)

    """img = torch.zeros_like(img)

    write_network_input(12, 16);
    write_network_input(19, 16);
    write_network_input(20, 32);
    write_network_input(27, 32);
    write_network_input(28, 32);
    write_network_input(29, 16);
    write_network_input(34, 16);
    write_network_input(35, 48);
    write_network_input(36, 48);
    write_network_input(37, 16);
    write_network_input(43, 16);
    write_network_input(44, 32);
    write_network_input(52, 32);"""
    
    plt.imshow(img.view(sz, sz));
    plt.show()


    model.quantize(torch.tensor(QUANT_VAL-0.01))
    spk0, spk1, spk2, mem0, mem1 = model((img.view(1, -1) * QUANT_VAL).round(), debug=True)
    #print(mem0)
    #for i in range(len(spk0)):
    #    print(spk0[i][0, :16], mem0[i][0, :16]);

    if(mode == "c"):
        #tile_idx, tiles = compile(model)
        #compile_to_c(model, img=img.view(sz*sz), spk=[spk0, spk1, spk2], mem=[mem0, mem1, None])
        compile_to_arr(model, img=img.view(sz*sz), spk=[spk0, spk1, spk2], mem=[mem0, mem1, None])
    elif(mode == "uart"):
        compile_to_uart(model, img=img.view(sz*sz))
