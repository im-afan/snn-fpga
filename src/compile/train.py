# copied from snntorch tutorial 5

# imports
import snntorch as snn
from snntorch import spikeplot as splt
from snntorch import spikegen

import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torchvision import datasets, transforms

import matplotlib.pyplot as plt
import numpy as np
import itertools

# Network Architecture
num_inputs = 8*8
num_hidden = 20
num_outputs = 10
thresh = 1

# Temporal Dynamics
num_steps = 10
beta = 0.5

# Define Network
class Net(nn.Module):
    def __init__(self):
        super().__init__()

        # Initialize layers
        self.spkgen = snn.Leaky(beta=beta, threshold=thresh)
        self.fc1 = nn.Linear(num_inputs, num_hidden)
        self.lif1 = snn.Leaky(beta=beta, threshold=thresh)
        self.fc2 = nn.Linear(num_hidden, num_outputs)
        self.lif2 = snn.Leaky(beta=beta, threshold=thresh)

    def forward(self, x):

        # Initialize hidden states at t=0
        mem0 = self.spkgen.init_leaky()
        mem1 = self.lif1.init_leaky()
        mem2 = self.lif2.init_leaky()

        # Record the final layer
        spk2_rec = []
        mem2_rec = []

        for step in range(num_steps):
            spk0, mem0 = self.spkgen(x, mem0)
            cur1 = self.fc1(spk0)
            spk1, mem1 = self.lif1(cur1, mem1)
            cur2 = self.fc2(spk1)
            spk2, mem2 = self.lif2(cur2, mem2)
            spk2_rec.append(spk2)
            mem2_rec.append(mem2)

        return torch.stack(spk2_rec, dim=0), torch.stack(mem2_rec, dim=0)

if __name__ == "__main__":
    # dataloader arguments
    batch_size = 128
    data_path='/tmp/data/mnist'

    dtype = torch.float
    device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")

    multiply = transforms.Lambda(lambda img: img*2)
    # Define a transform
    transform = transforms.Compose([
                transforms.Resize((8, 8)),
                transforms.Grayscale(),
                transforms.ToTensor(),
                transforms.Normalize((0,), (1,)),
                multiply])

    mnist_train = datasets.MNIST(data_path, train=True, download=True, transform=transform)
    mnist_test = datasets.MNIST(data_path, train=False, download=True, transform=transform)

    # # temporary dataloader if MNIST service is unavailable
    # !wget www.di.ens.fr/~lelarge/MNIST.tar.gz
    # !tar -zxvf MNIST.tar.gz

    # mnist_train = datasets.MNIST(root = './', train=True, download=True, transform=transform)
    # mnist_test = datasets.MNIST(root = './', train=False, download=True, transform=transform)

    # Create DataLoaders
    train_loader = DataLoader(mnist_train, batch_size=batch_size, shuffle=True, drop_last=True)
    test_loader = DataLoader(mnist_test, batch_size=batch_size, shuffle=True, drop_last=True)



    # Load the network onto CUDA if available
    net = Net().to(device)

    # pass data into the network, sum the spikes over time
    # and compare the neuron with the highest number of spikes
    # with the target

    def print_batch_accuracy(data, targets, train=False):
        output, _ = net(data.view(batch_size, -1))
        _, idx = output.sum(dim=0).max(1)
        acc = np.mean((targets == idx).detach().cpu().numpy())

        if train:
            print(f"Train set accuracy for a single minibatch: {acc*100:.2f}%")
        else:
            print(f"Test set accuracy for a single minibatch: {acc*100:.2f}%")

    def train_printer(
        data, targets, epoch,
        counter, iter_counter,
            loss_hist, test_loss_hist, test_data, test_targets):
        print(f"Epoch {epoch}, Iteration {iter_counter}")
        print(f"Train Set Loss: {loss_hist[counter]:.2f}")
        print(f"Test Set Loss: {test_loss_hist[counter]:.2f}")
        print_batch_accuracy(data, targets, train=True)
        print_batch_accuracy(test_data, test_targets, train=False)
        print("\n")

    loss = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(net.parameters(), lr=5e-4, betas=(0.9, 0.999))

    num_epochs = 5
    loss_hist = []
    test_loss_hist = []
    counter = 0

    # Outer training loop
    for epoch in range(num_epochs):
        iter_counter = 0
        train_batch = iter(train_loader)

        # Minibatch training loop
        for data, targets in train_batch:
            data = data.to(device)
            targets = targets.to(device)

            # forward pass
            net.train()
            spk_rec, mem_rec = net(data.view(batch_size, -1))

            # initialize the loss & sum over time
            loss_val = torch.zeros((1), dtype=dtype, device=device)
            for step in range(num_steps):
                loss_val += loss(mem_rec[step], targets)

            # Gradient calculation + weight update
            optimizer.zero_grad()
            loss_val.backward()
            optimizer.step()

            # Store loss history for future plotting
            loss_hist.append(loss_val.item())

            # Test set
            with torch.no_grad():
                net.eval()
                test_data, test_targets = next(iter(test_loader))
                test_data = test_data.to(device)
                test_targets = test_targets.to(device)

                # Test set forward pass
                test_spk, test_mem = net(test_data.view(batch_size, -1))

                # Test set loss
                test_loss = torch.zeros((1), dtype=dtype, device=device)
                for step in range(num_steps):
                    test_loss += loss(test_mem[step], test_targets)
                test_loss_hist.append(test_loss.item())

                # Print train/test loss/accuracy
                if counter % 50 == 0:
                    train_printer(
                        data, targets, epoch,
                        counter, iter_counter,
                        loss_hist, test_loss_hist,
                        test_data, test_targets)
                counter += 1
                iter_counter +=1

    torch.save(net.state_dict(), "./mnist_16x16_spk.h5")

    total = 0
    correct = 0

    # drop_last switched to False to keep all samples
    test_loader = DataLoader(mnist_test, batch_size=batch_size, shuffle=True, drop_last=False)

    with torch.no_grad():
      net.eval()
      for data, targets in test_loader:
        data = data.to(device)
        targets = targets.to(device)

        # forward pass
        test_spk, _ = net(data.view(data.size(0), -1))

        # calculate total accuracy
        _, predicted = test_spk.sum(dim=0).max(1)
        total += targets.size(0)
        correct += (predicted == targets).sum().item()

    print(f"Total correctly classified test set images: {correct}/{total}")
    print(f"Test Set Accuracy: {100 * correct / total:.2f}%")
