# 2025-04-08T14:30:20.622689800
import vitis

client = vitis.create_client()
client.set_workspace(path="ws")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.get_component(name="app_component_mnist")
comp.build()

vitis.dispose()

