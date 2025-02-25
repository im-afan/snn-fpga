import gymnasium as gym
import torch
import torch.nn as nn
import torch.nn.functional as F
from stable_baselines3 import DQN, PPO
from stable_baselines3.common.torch_layers import BaseFeaturesExtractor
from stable_baselines3.common.env_util import make_vec_env, make_atari_env
from stable_baselines3.common.vec_env import SubprocVecEnv, VecFrameStack, VecNormalize
from stable_baselines3.common.atari_wrappers import AtariWrapper 
from stable_baselines3.common.callbacks import CheckpointCallback
from policy import *
from wrapper import *
#from gymnasium.wrappers import FrameStack

def atari_wrap(env):
    #return PreprocessAtariObs(FrameStack(env, num_stack=4))
    return FrameStack(PreprocessAtariObs(env), num_stack=4)

def builtin_atari_wrap(env):
    return AtariWrapper(env)

if __name__ == "__main__":
    checkpoint_callback = CheckpointCallback(
        save_freq=1000,
        save_path="./breakout/runs",
        name_prefix="ppo_snn",
        save_replay_buffer=True,
        save_vecnormalize=True,
    )
    # Create the CartPole environment
    #env = gym.make("ALE/Breakout-v4")
    #env = PreprocessAtariObs(env)

    #env = make_vec_env("BreakoutNoFrameskip-v4", n_envs=4)
    #env = CustomVecFrameStack(env, n_stack=4)
    #env = PreprocessAtariObs(env)
    env = make_vec_env("BreakoutNoFrameskip-v4", n_envs=8, wrapper_class=builtin_atari_wrap)


    # Create and train the DQN model
    model = PPO(CustomActorCriticPolicy, env, verbose=1, device="cpu", policy_kwargs={"use_pop_code": False})
    #model = PPO("CnnPolicy", env, verbose=1, device="cpu")

    model.learn(total_timesteps=10000000, callback=checkpoint_callback)

    # Save the model
    model.save("ppo_cartpole_custom")

    env.close()