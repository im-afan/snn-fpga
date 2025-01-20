# 2025-01-19T17:24:49.239930100
import vitis

client = vitis.create_client()
client.set_workspace(path="ws")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.get_component(name="uart_listener")
comp.build()

