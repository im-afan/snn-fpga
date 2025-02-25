import sys
from stable_baselines3 import A2C, PPO
from stable_baselines3.common.env_util import make_atari_env, make_vec_env
from stable_baselines3.common.vec_env import VecFrameStack
import gymnasium as gym
import torch
import numpy as np

# There already exists an environment generator that will make and wrap atari environments correctly.
#env = gym.make("CartPole-v1")
name = sys.argv[1]
env = make_vec_env(name)

model = PPO.load(name + "/runs/ppo_snn_392000_steps.zip", verbose=1, env=env)
model.set_env(env)

pop_encode = model.policy.pi_features_extractor.extractor
snn = model.policy.mlp_extractor.actor
pop_decode = model.policy.action_net

print(pop_encode(torch.zeros((1, 4))))

obs = env.reset()
while True:
    obs = torch.from_numpy(obs)
    x = pop_encode(obs)
    x = snn(x)
    action = pop_decode(x)
    action = np.array([torch.argmax(action)])

    print(action)
    #action, _states = model.predict(obs, deterministic=False)
    obs, rewards, dones, info = env.step(action)
    env.render("human")