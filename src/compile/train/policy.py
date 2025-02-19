from typing import Callable
import torch
import gymnasium as gym
import torch.nn as nn
from stable_baselines3 import A2C
from stable_baselines3.common.torch_layers import BaseFeaturesExtractor
from stable_baselines3.common.policies import ActorCriticPolicy
import gymnasium.spaces as spaces
import snntorch as snn

class CustomCombinedExtractor(BaseFeaturesExtractor):
    def __init__(self, observation_space: gym.spaces.Dict, features_dim:int =16):
        super().__init__(observation_space, features_dim=features_dim)
        print(observation_space)
        self.extractor = nn.Sequential(nn.Linear(observation_space, features_dim), nn.ReLU())
        self._features_dim = features_dim 

    def forward(self, observations) -> torch.Tensor:
        return self.extractor(observations) 

snn_steps = 25
snn_beta = 1
class SNN(nn.Module):
    def __init__(self, feature_dim: int, output_dim: int = 64, hidden_dim: int = 16):
        super().__init__()
        self.feature_dim = feature_dim
        self.output_dim = output_dim
        self.hidden_dim = hidden_dim

        self.lif0 = snn.Leaky(beta=1)
        self.fc1 = nn.Linear(feature_dim, hidden_dim, bias=False)
        self.lif1 = snn.Leaky(beta=1)
        self.fc2 = nn.Linear(hidden_dim, output_dim, bias=False)
        self.lif2 = snn.Leaky(beta=1)

    def forward(self, features):
        mem0 = self.lif0.init_leaky() 
        mem1 = self.lif1.init_leaky()
        mem2 = self.lif2.init_leaky()
        spk0 = torch.zeros((features.shape[0], self.feature_dim))
        spk1 = torch.zeros((features.shape[0], self.hidden_dim))
        spk2 = torch.zeros((features.shape[0], self.output_dim))

        out = torch.zeros((features.shape[0], self.output_dim))

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

        self.net = nn.Sequential(nn.Linear(feature_dim, output_dim))

    def forward(self, features):
        return self.net(features) 

class ActorCriticNetwork(nn.Module):
    def __init__(self, feature_dim: int = 32, dim_pi: int = 64, dim_vf: int = 64):
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
        *args,
        **kwargs,
    ):
        # Disable orthogonal initialization
        kwargs["ortho_init"] = False
        super().__init__(
            observation_space,
            action_space,
            lr_schedule,
            # Pass remaining arguments to base class
            *args,
            **kwargs,
        )

    def _build_mlp_extractor(self) -> None:
        self.mlp_extractor = ActorCriticNetwork(self.features_dim)