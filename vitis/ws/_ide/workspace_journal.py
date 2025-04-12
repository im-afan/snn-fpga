# 2025-04-11T17:47:39.460937900
import vitis

client = vitis.create_client()
client.set_workspace(path="ws")

vitis.dispose()

platform = client.get_component(name="platform")
status = platform.build()

comp = client.get_component(name="app_component_mnist")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

