from typing import Any, Dict, List, Mapping, Optional, Tuple, Union, Callable
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
from stable_baselines3.common.vec_env.base_vec_env import VecEnv, VecEnvWrapper
from stable_baselines3.common.vec_env.stacked_observations import StackedObservations

class PreprocessAtariObs(ObservationWrapper):
    def __init__(self, env, **kwargs):
        """A gym wrapper that crops, scales image into the desired shapes and grayscales it."""
        ObservationWrapper.__init__(self, env, **kwargs)

        self.img_size = (1, 64, 64) 
        #self.observation_space = spaces.Box(0.0, 1.0, (4096,))
        self.observation_space = spaces.Box(0.0, 1.0, (64, 64))


    def _to_gray_scale(self, rgb, channel_weights=[0.8, 0.1, 0.1]):
        return np.dot(rgb[...,:3], channel_weights)


    def observation(self, img):
        #print(img.shape)
        #img = np.sum(img, axis=0)
        #print(img.shape)
        cropped_img = img[30:200, :,:]
        resized_img = cv2.resize(cropped_img, self.img_size[1:], interpolation=cv2.INTER_LINEAR_EXACT)
        gs_img = self._to_gray_scale(resized_img)
        normalized_img = gs_img.astype('float32') / 255.
        #flattened_img = normalized_img.flatten()
        flattened_img = normalized_img
        #print(flattened_img.shape)
        
        return flattened_img
    
    """def step(self, action):
        observation, reward, terminated, truncated, info = self.env.step(action)
        self.frames.append(observation)
        return self.observation(None), reward, terminated, truncated, info
    
    def reset(self, **kwargs):
        obs, info = self.env.reset(**kwargs)

        [self.frames.append(obs) for _ in range(self.num_stack)]

        return self.observation(None), info"""

class CustomAtariWrapper(gym.ObservationWrapper):
    def __init__(self, env, frame_stack=4):
        super(CustomAtariWrapper, self).__init__(env)
        self.frame_stack = frame_stack
        self.frames = np.zeros((frame_stack, 84, 84), dtype=np.uint8)
        self.observation_space = spaces.Box(low=0, high=255, shape=(84 * 84,), dtype=np.uint8)
    
    def observation(self, obs):
        gray = cv2.cvtColor(obs, cv2.COLOR_RGB2GRAY)
        resized = cv2.resize(gray, (84, 84), interpolation=cv2.INTER_AREA)
        self.frames[:-1] = self.frames[1:]
        self.frames[-1] = resized
        summed_frames = np.sum(self.frames, axis=0)
        return summed_frames.flatten()
