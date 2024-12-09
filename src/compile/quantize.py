import sys
import torch
from torch import nn
import torch.nn.functional as F
import snntorch as snn
from train import Net
import matplotlib.pyplot as plt
from torchvision import datasets, transforms
from torch.utils.data import DataLoader

THRESH = torch.tensor(127, dtype=torch.float32)

if __name__ == "__main__":
    try:
        out_path = sys.argv[1]
        sys.stdout = open(out_path, "w")
    except Exception:
        pass
    
    with torch.no_grad(): 
        model = Net()
        state_dict = torch.load("./mnist_16x16_spk.h5", weights_only=True)
        model.load_state_dict(state_dict)
        model.eval()


        multiply = transforms.Lambda(lambda img: torch.clamp(img*4, min=0, max=1))
        transform = transforms.Compose([
            transforms.Resize((8, 8)),
            transforms.Grayscale(),
            transforms.ToTensor(),
            multiply
        ])

        data_path='/tmp/data/mnist'
        mnist_test = datasets.MNIST(data_path, train=False, download=True, transform=transform)
        test_loader = iter(DataLoader(mnist_test, batch_size=1, shuffle=True, drop_last=True))
        img, label = next(test_loader)
        plt.imshow(img.view(8, 8).numpy())
        spk, mem = model(img.view(1, -1))
        
        print(spk)

        model.quantize(THRESH)


        img = (img * THRESH).round()
        print(img)


        spk_quant, mem_quant = model(img.view(1, -1))
        print(spk_quant)

 
