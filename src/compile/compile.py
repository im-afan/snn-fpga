import sys
import torch
from torch import nn
import torch.nn.functional as F
import snntorch as snn
from train import Net
import matplotlib.pyplot as plt
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
from compiler.tiles import *
from compiler.compile import *
from compiler.quantize import quantize

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
state_dict = torch.load("./mnist_28x28_spk_big.h5", weights_only=True)
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

plt.imshow(img.view(sz, sz));
plt.show()

#model.quantize(torch.tensor(QUANT_VAL))
quantize(model, torch.tensor(QUANT_VAL))
spk0, spk1, spk2, mem0, mem1 = model((img.view(1, -1) * QUANT_VAL).round(), debug=True)

tile = MLPTiles(model)

if(mode == "c"):
    compile_to_arr(tile, img=img.view(sz*sz), spk=[spk0, spk1, spk2], mem=[mem0, mem1, None])
elif(mode == "py"):
    compile_to_py(tile, img=img.view(sz*sz), spk=[spk0, spk1, spk2])

