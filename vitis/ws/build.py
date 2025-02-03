# 2024-12-01T23:13:25.179679
import vitis

#PATH = "/home/andrew/Desktop/snn-soc"
#PATH = "/Users/andrew/Desktop/snn-fpga"
PATH = "C:/Users/andre/Desktop/snn-fpga"
print(PATH + "/vitis/ws")

client = vitis.create_client()
client.update_workspace(path=PATH+"/vitis/ws")
client.set_workspace(path=PATH+"/vitis/ws")

platform = client.create_platform_component(name = "platform", hw_design = PATH + "/vitis/top_microblaze.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0")

comp = client.create_app_component(name="app_component",platform = PATH + "/vitis/ws/platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0")
comp.import_files(from_loc=PATH + "/src/c/", files=["main.c", "snn_driver.h", "model.h", "model_params.h"], dest_dir_in_cmp="src")

comp = client.create_app_component(name="app_component_xor",platform = PATH + "/vitis/ws/platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0")
comp.import_files(from_loc=PATH + "/src/c/", files=["main_xor.c", "snn_driver.h"], dest_dir_in_cmp="src")

comp = client.create_app_component(name="uart_listener",platform = PATH + "/vitis/ws/platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0")
comp.import_files(from_loc=PATH + "/src/c/", files=["main_uart.c", "snn_driver.h", "uart_driver.h"], dest_dir_in_cmp="src")
