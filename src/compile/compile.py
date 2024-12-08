import sys
import torch
from torch import nn
import torch.nn.functional as F
import snntorch as snn
from train import Net
import matplotlib.pyplot as plt
from torchvision import datasets, transforms
from torch.utils.data import DataLoader

MAX_NEURONS = 1024
MAX_TILES = 64
NEURONS_PER_TILE = 16
THRESH = 32 # for weight quantization

# compile MLP from snntorch
# only supports 1 membrane potential across all neurons
# only supports 0.5 leak
# no bias

def round_up(x):
    return (x // NEURONS_PER_TILE + 1) * NEURONS_PER_TILE

def compile(model): # compile MLP 
    neuron_idx = 0

    tile_idx = []
    tiles = []
    
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

        for i in range(0, round_up(in_neurons) // NEURONS_PER_TILE):
            y = i*NEURONS_PER_TILE
            for j in range(0, round_up(out_neurons) // NEURONS_PER_TILE):
                x = j*NEURONS_PER_TILE
                tile_weights = weight_pad[x:x+NEURONS_PER_TILE, y:y+NEURONS_PER_TILE]
                tile_weights = (tile_weights * THRESH).round().to(dtype=torch.int8)
                tile_idx.append([in_idx // NEURONS_PER_TILE + i, out_idx // NEURONS_PER_TILE + j])
                tiles.append(tile_weights)
                #print(tiles[-1], tile_idx[-1])

        neuron_idx = out_idx

    return tile_idx, tiles

def compile_to_c(model, img=None, spk=None):
    tile_idx, tiles = compile(model)
    print("/* AUTO GENERATED CODE BY MODEL COMPILATION")
    print(" * IT IS HIGHLY DISCOURAGED TO EDIT THIS!!!")
    print(" */")

    print("/* EXPECTED OUTPUT")
    print(f"{spk}")
    print("*/")

    print("#include \"snn_driver.h\"")
    print("")
    print("void write_model() {")
    for i in range(len(tiles)):
        print(f"    write_tile({i}, {tile_idx[i][0]}, {tile_idx[i][1]});")
        for x in range(NEURONS_PER_TILE):
            for y in range(NEURONS_PER_TILE):
                print(f"    write_weight({i}, {x}, {y}, {tiles[i][x][y]});")

    if(img is not None):
        for i in range(64):
            print(f"    write_network_input({i}, {int(round(img[i].item() * THRESH))});")

    print("}")

if __name__ == "__main__":
    try:
        out_path = sys.argv[1]
        sys.stdout = open(out_path, "w")
    except Exception:
        pass
    
    model = Net()
    state_dict = torch.load("./mnist_16x16_spk.h5", weights_only=True)
    model.load_state_dict(state_dict)

    multiply = transforms.Lambda(lambda img: img*2)
    transform = transforms.Compose([
        transforms.Resize((8, 8)),
        transforms.Grayscale(),
        transforms.ToTensor(),
        transforms.Normalize((0,), (1,)),
        multiply
    ])

    data_path='/tmp/data/mnist'
    mnist_test = datasets.MNIST(data_path, train=False, download=True, transform=transform)
    test_loader = iter(DataLoader(mnist_test, batch_size=1, shuffle=True, drop_last=True))
    img, label = next(test_loader)
    plt.imshow(img.view(8, 8).numpy())
    spk, mem = model(img.view(1, -1))
    #print(spk)
    #print(label)

    #tile_idx, tiles = compile(model)
    compile_to_c(model, img=img.view(64), spk=spk)
    plt.show()

