import gym
import torch
import torch.nn as nn
import torch.nn.functional as F
from stable_baselines3 import DQN, PPO
from stable_baselines3.common.torch_layers import BaseFeaturesExtractor
from stable_baselines3.common.env_util import make_vec_env
from stable_baselines3.common.vec_env import SubprocVecEnv
from policy import *

# Create the CartPole environment
env = make_vec_env("CartPole-v1", n_envs=8, vec_env_cls=SubprocVecEnv)


# Create and train the DQN model
model = PPO(CustomActorCriticPolicy, env, verbose=1, learning_rate=1e-3)

model.learn(total_timesteps=500000)

# Save the model
model.save("ppo_cartpole_custom")

env.close()