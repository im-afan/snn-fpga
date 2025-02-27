# 2025-02-26T23:51:57.244684800
import vitis

client = vitis.create_client()
client.set_workspace(path="ws")

platform = client.create_platform_component(name = "platform",hw_design = "$COMPONENT_LOCATION/../../top_microblaze.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",generate_dtb = True)

comp = client.create_app_component(name="app_component",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0")

comp = client.get_component(name="app_component")
status = comp.import_files(from_loc="$COMPONENT_LOCATION/../../../src/c", files=["main_mnist.c", "snn_driver.h", "model.h", "model_params.h"], dest_dir_in_cmp = "src")

comp = client.create_app_component(name="app_component_xor",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0")

comp = client.get_component(name="app_component_xor")
status = comp.import_files(from_loc="$COMPONENT_LOCATION/../../../src/c", files=["main_mnist.c", "snn_driver.h", "model_params.h"], dest_dir_in_cmp = "src")

comp = client.create_app_component(name="uart_listener",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0")

comp = client.get_component(name="uart_listener")
status = comp.import_files(from_loc="$COMPONENT_LOCATION/../../../src/c", files=["main_uart.c", "snn_driver.h", "uart_driver.h"], dest_dir_in_cmp = "src")

vitis.dispose()

