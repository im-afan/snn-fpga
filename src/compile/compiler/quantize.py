import sys
import torch
from torch import nn
import torch.nn.functional as F
import snntorch as snn
from train import Net
import matplotlib.pyplot as plt
from torchvision import datasets, transforms
from torch.utils.data import DataLoader

class QuantizeInput(nn.Module):
    def __init__(self, new_thresh):
        super().__init__()
        self.new_thresh = new_thresh
    
    def forward(self, x):
        return torch.round(x * self.new_thresh)

def quantize(model: nn.Module, new_thresh):
    for name, module in model.named_children():
        if(isinstance(module, nn.Linear)):
            new_linear = module
            if(new_linear.bias):
                new_linear.bias.data = torch.round(module.bias.data * new_thresh)
            new_linear.weight.data = torch.round(module.weight.data * new_thresh)
            setattr(model, name, new_linear)

        elif(isinstance(module, snn.Leaky)):
            new_leaky = module
            new_leaky.threshold = new_thresh
            setattr(model, name, new_leaky)

    model = nn.Sequential(QuantizeInput(new_thresh), model)
    return model

