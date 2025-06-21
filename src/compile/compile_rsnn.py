import os
import sys
from compiler.tiles import *
from compiler.compile import *
import shutil

sz = 28
MAX_NEURONS = 1024
MAX_TILES = 512 
NEURONS_PER_TILE = 16
QUANT_VAL = 64 # for weight quantization
THRESH = 64 # must be a mutliple of quant_val

img = None
out_folder = "compile_out"

try:
    out_folder = sys.argv[2]
except Exception:
    pass

try:
    os.mkdir(out_folder)
except FileExistsError:
    pass

out_path = out_folder + "/weights.py"
sys.stdout = open(out_path, "w")

try:
    mode = sys.argv[1]
except Exception:
    mode = "c"	

model = [
    [1, 2, THRESH],
    [2, 3, THRESH],
    [3, 4, THRESH],
    [4, 3, THRESH],
    [4, 2, -THRESH],
    [3, 2, -THRESH],
    [1, 5, THRESH*2-1],
    [3, 5, THRESH*2-1],
    [0, 5, -THRESH*2+1]
]
tile = RSNNTiles(model, MAX_TILES)
if(mode == "c"):
    pass
elif(mode == "py"):
    compile_to_py(tile, network_input=[THRESH, THRESH/4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    shutil.copy("./py_to_mem.py", out_folder + "/py_to_mem.py")
    #os.system("cp py_to_mem.py compile_out && cd " + out_folder + " && python3 py_to_mem.py")    

