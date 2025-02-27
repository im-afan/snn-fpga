# 2025-02-26T23:56:19.872710300
import vitis

client = vitis.create_client()
client.set_workspace(path="ws")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.get_component(name="app_component_xor")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

