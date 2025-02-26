import sys
import os
from stable_baselines3 import A2C, PPO
from stable_baselines3.common.env_util import make_atari_env, make_vec_env
from stable_baselines3.common.vec_env import VecFrameStack
import gymnasium as gym
import torch
import numpy as np
from torch import nn
import snntorch as snn
from policy import CustomActorCriticPolicy

class QuantizeInput(nn.Module):
    def __init__(self, new_thresh):
        super().__init__()
        self.new_thresh = new_thresh
    
    def forward(self, x):
        res = torch.round(x * self.new_thresh)
        return res

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

# There already exists an environment generator that will make and wrap atari environments correctly.
#env = gym.make("CartPole-v1")
name = sys.argv[1]
env = make_vec_env(name)

model = PPO.load(name + "/runs/ppo_snn_392000_steps.zip", verbose=1, env=env, policy=CustomActorCriticPolicy)
model.set_env(env)

pop_encode = model.policy.pi_features_extractor.extractor
net = model.policy.mlp_extractor.actor
pop_decode = model.policy.action_net

net = quantize(net, torch.tensor(64))
print(net)

obs = env.reset()
while True:
    obs = torch.from_numpy(obs)
    x = pop_encode(obs)
    x = net(x)
    action = pop_decode(x)
    action = np.array([torch.argmax(action)])

    #print(action)
    #action, _states = model.predict(obs, deterministic=False)
    obs, rewards, dones, info = env.step(action)
    env.render("human")
