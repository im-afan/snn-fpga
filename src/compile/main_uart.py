import serial
import gymnasium as gym
from stable_baselines3 import PPO

# There already exists an environment generator that will make and wrap atari environments correctly.
new_thresh = 64
env = gym.make("CartPole-v1")

model = PPO.load("CartPole-v1" + "/runs/ppo_snn_392000_steps.zip", verbose=1, env=env, policy=CustomActorCriticPolicy)
model.set_env(env)

pop_encode = model.policy.pi_features_extractor.extractor
net = model.policy.mlp_extractor.actor
pop_decode = model.policy.action_net

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
