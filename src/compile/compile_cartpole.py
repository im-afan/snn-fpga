import sys
from stable_baselines3.ppo import PPO
from stable_baselines3.common.env_util import make_atari_env, make_vec_env
#from stable_baselines3.common.policies import register_policy
from compiler.quantize import quantize
from compiler.tiles import MLPTiles
from compiler.compile import *
import torch
from train_rl.policy import CustomActorCriticPolicy 

#register_policy("CustomActorCriticPolicy", CustomActorCriticPolicy)

name = sys.argv[1]
env = make_vec_env(name)


img = None
try:
    out_path = sys.argv[3]
    sys.stdout = open(out_path, "w")
except Exception:
    pass

try:
    mode = sys.argv[2]
except Exception:
    mode = "c"	

model = PPO.load("train_rl/" + name + "/runs/ppo_snn_392000_steps.zip", verbose=1, env=env, custom_objects={"policy_class": CustomActorCriticPolicy})
model.set_env(env)

pop_encode = model.policy.pi_features_extractor.extractor
net = model.policy.mlp_extractor.actor
pop_decode = model.policy.action_net

net = quantize(net, torch.tensor(64))

tile = MLPTiles(net)

if(mode == "c"):
    compile_to_arr(tile)
elif(mode == "py"):
    compile_to_py(tile)

