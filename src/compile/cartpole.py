import gymnasium as gym
import numpy as np
import random 
import serial

env = gym.make("CartPole-v1", render_mode="human")
s = serial.Serial("/dev/ttyS0", 115200)

terminated = False
obs, info = env.reset()

print(env.action_space)

while(not terminated):
    
    s.write(bytes([]))
    obs, _, terminated, truncated, info = env.step(random.choice([0, 1]))
