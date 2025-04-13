# 2025-04-13T01:48:57.765673
import vitis

client = vitis.create_client()
client.set_workspace(path="ws")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.get_component(name="app_component_mnist")
comp.build()

