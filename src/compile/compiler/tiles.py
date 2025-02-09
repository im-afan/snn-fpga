import torch
import torch.nn as nn
import torch.nn.functional as F

class Tiles:
    MAX_NEURONS = 1024
    MAX_NEURONS = 1024
    MAX_TILES = 512 
    NEURONS_PER_TILE = 16
    QUANT_VAL = 64 # for weight quantization
    THRESH = 64 # must be a mutliple of quant_val

    tile_idx = []
    tiles = []
    tiles_bias = []

    def append(self, new_tiles): # only supports fully disjoint nns for now
        max_tile = 0
        for idx in self.tile_idx:
            max_tile = max(max_tile, idx)

        for i in range(len(new_tiles.tiles)):
            new_tiles.tiles[i][0] += max_tile
            new_tiles.tiles[i][1] += max_tile

        self.tiles += new_tiles.tiles
        self.tile_idx += new_tiles.tile_idx
        self.tiles_bias += new_tiles.tiles_bias
         
class MLPTiles(Tiles):
    def __init__(self, model): # compile MLP 
        neuron_idx = 0
        for name, param in model.named_parameters():
            if(not name.endswith("weight")):
                continue
            weight = param.data

            in_neurons = weight.shape[1]
            out_neurons = weight.shape[0]

            in_idx = neuron_idx
            out_idx = neuron_idx + self.round_up(in_neurons) 

            pad = (0, self.round_up(in_neurons)-in_neurons, 0, self.round_up(out_neurons)-out_neurons)
            weight_pad = F.pad(weight, pad, mode="constant", value=0)

            for i in range(0, self.round_up(in_neurons) // self.NEURONS_PER_TILE):
                y = i*self.NEURONS_PER_TILE
                for j in range(0, self.round_up(out_neurons) // self.NEURONS_PER_TILE):
                    x = j*self.NEURONS_PER_TILE
                    tile_weights = weight_pad[x:x+self.NEURONS_PER_TILE, y:y+self.NEURONS_PER_TILE]
                    self.tile_idx.append([in_idx // self.NEURONS_PER_TILE + i, out_idx // self.NEURONS_PER_TILE + j])
                    self.tiles.append(tile_weights)

            neuron_idx = out_idx

        neuron_idx = 0

        for name, param in model.named_parameters():
            if(not name.endswith("bias")):
                continue
            bias = param.data

            in_neurons = bias.shape[0]

            in_idx = neuron_idx
            out_idx = neuron_idx + self.round_up(in_neurons) 

            pad = (0, self.round_up(in_neurons) - in_neurons)
            bias_pad = F.pad(bias, pad, mode="constant", value=0) * self.THRESH / self.QUANT_VAL

            self.tiles_bias += bias_pad.tolist()

            neuron_idx = out_idx

        sorted_tiles = [[self.tiles[i], self.tile_idx[i]] for i in range(len(self.tile_idx))]
        sorted_tiles = sorted(sorted_tiles, key = lambda x: x[1][1])

        self.tile_idx = [i[1] for i in sorted_tiles]
        self.tiles = [i[0] for i in sorted_tiles]

    
    def round_up(self, x):
        return (x // self.NEURONS_PER_TILE + 1) * self.NEURONS_PER_TILE

