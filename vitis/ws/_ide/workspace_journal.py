# 2025-01-18T14:45:25.140632100
import vitis

client = vitis.create_client()
client.set_workspace(path="ws")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.get_component(name="app_component_xor")
comp.build()

status = platform.build()

comp = client.get_component(name="uart_listener")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

