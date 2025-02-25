import sys
import gymnasium as gym
from stable_baselines3 import DQN, PPO
from stable_baselines3.common.env_util import make_vec_env, make_atari_env
from stable_baselines3.common.vec_env import SubprocVecEnv
from stable_baselines3.common.callbacks import CheckpointCallback
from policy import *
from wrapper import *

if __name__ == "__main__":
    env_name = sys.argv[1]
    use_pop_code = sys.argv[2] == "True"


    checkpoint_callback = CheckpointCallback(
        save_freq=1000,
        save_path=f"./{env_name}/runs",
        name_prefix="ppo_snn",
        save_replay_buffer=True,
        save_vecnormalize=True,
    )


    #env = make_vec_env("BipedalWalker-v3", n_envs=8, vec_env_cls=SubprocVecEnv)
    env = make_vec_env(env_name, n_envs=8, vec_env_cls=SubprocVecEnv)


    # Create and train the DQN model
    model = PPO(CustomActorCriticPolicy, env, verbose=1, device="cpu", policy_kwargs={"use_pop_code": True})
    #model = PPO("CnnPolicy", env, verbose=1, device="cpu")
    #model = PPO("MlpPolicy", env, verbose=1, device="cpu")

    model.learn(total_timesteps=10000000, callback=checkpoint_callback)

    # Save the model
    #model.save("ppo_cartpole_custom")

    env.close()