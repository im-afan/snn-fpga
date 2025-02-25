from typing import Callable
import torch
import gymnasium as gym
import torch.nn as nn
import torch.nn.functional as F
from stable_baselines3 import A2C
from stable_baselines3.common.torch_layers import BaseFeaturesExtractor
from stable_baselines3.common.policies import ActorCriticPolicy
import gymnasium.spaces as spaces
from gymnasium import ObservationWrapper
import snntorch as snn
import cv2
import numpy as np

device = torch.device("cpu")

class IdentityExtractor(BaseFeaturesExtractor):
    def __init__(self, observation_space: gym.spaces.Dict, features_dim:int=4096):
        super().__init__(observation_space, features_dim=features_dim)
        features_dim = observation_space.shape[0]
        assert observation_space.shape[0] == features_dim
        
        self._features_dim = features_dim 

    def forward(self, observations) -> torch.Tensor:
        return observations

class PopulationExtractor(BaseFeaturesExtractor):
    def __init__(self, observation_space: spaces.Box, features_dim: int = 64):
        super().__init__(observation_space, features_dim)
        n_in = torch.numel(torch.zeros(observation_space.shape))
        print(n_in, features_dim)

        self.extractor = nn.Sequential(
            nn.Flatten(),
            nn.Linear(n_in, features_dim),
            nn.ReLU()
        )

    def forward(self, observations: torch.Tensor) -> torch.Tensor:
        return self.extractor(observations)

snn_steps = 10
snn_beta = 1
class SNN(nn.Module):
    def __init__(self, feature_dim: int, output_dim: int = 2, hidden_dim: int = 64):
        super().__init__()

        self.feature_dim = feature_dim
        self.output_dim = output_dim
        self.hidden_dim = hidden_dim
        self.population_dim = 64
        self.flatten = nn.Flatten()

        
        self.lif0 = snn.Leaky(beta=1, reset_mechanism="zero")
        self.fc1 = nn.Linear(feature_dim, hidden_dim, bias=False)
        self.lif1 = snn.Leaky(beta=1, reset_mechanism="zero")
        self.fc2 = nn.Linear(hidden_dim, output_dim, bias=False)
        self.lif2 = snn.Leaky(beta=1, reset_mechanism="zero")

    def forward(self, features):
        features = self.flatten(features)

        mem0 = self.lif0.init_leaky() 
        mem1 = self.lif1.init_leaky()
        mem2 = self.lif2.init_leaky()
        spk0 = torch.zeros((features.shape[0], self.population_dim)).to(device)
        spk1 = torch.zeros((features.shape[0], self.hidden_dim)).to(device)
        spk2 = torch.zeros((features.shape[0], self.output_dim)).to(device)

        out = torch.zeros((features.shape[0], self.output_dim)).to(device)

        for i in range(snn_steps):
            spk0_next, mem0 = self.lif0(features, mem0)
            cur1 = self.fc1(spk0)
            spk1_next, mem1 = self.lif1(cur1, mem1)
            cur2 = self.fc2(spk1)
            spk2_next, mem2 = self.lif2(cur2, mem2)

            out += spk2

            spk0 = spk0_next
            spk1 = spk1_next
            spk2 = spk2_next

        return out 
    
class Net(nn.Module): # feature extractor -> SNN
    def __init__(
        self,
        feature_dim: int,
        output_dim: int = 64
    ):

        super().__init__()

        hidden_dim = 64 

        self.net = nn.Sequential(
            nn.Linear(feature_dim, hidden_dim), 
            nn.ReLU(), 
            nn.Linear(feature_dim, hidden_dim), 
            nn.ReLU(), 
            nn.Linear(hidden_dim, output_dim))

    def forward(self, features):
        return self.net(features) 

class ActorCriticNetwork(nn.Module):
    def __init__(self, feature_dim: int = 32, dim_pi: int = 8, dim_vf: int = 8):
        super().__init__()
        self.latent_dim_pi = dim_pi
        self.latent_dim_vf = dim_vf

        self.actor = SNN(feature_dim, output_dim=dim_pi)
        self.critic = Net(feature_dim, output_dim=dim_vf)

    def forward(self, feature):
        return self.forward_actor(feature), self.forward_critic(feature)
    
    def forward_actor(self, features):
        return self.actor(features)
    
    def forward_critic(self, features):
        return self.critic(features)
    
class CustomActorCriticPolicy(ActorCriticPolicy):
    def __init__(
        self,
        observation_space: spaces.Space,
        action_space: spaces.Space,
        lr_schedule: Callable[[float], float],
        use_pop_code=True,
        *args,
        **kwargs,
    ):
        # Disable orthogonal initialization
        kwargs["ortho_init"] = False
        #self.use_pop_code = kwargs["use_pop_code"] 
        self.use_pop_code = use_pop_code 
        extractor = IdentityExtractor
        if(use_pop_code):
            extractor = PopulationExtractor

        super().__init__(
            observation_space,
            action_space,
            lr_schedule,
            features_extractor_class=extractor,
            #features_dim=observation_space.shape[0],
            # Pass remaining arguments to base class
            *args,
            **kwargs,
        )


    def _build_mlp_extractor(self) -> None:
        self.mlp_extractor = ActorCriticNetwork(self.features_dim).to(device)
