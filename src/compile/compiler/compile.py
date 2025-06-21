import generate_mem

sz = 28
MAX_NEURONS = 1024
MAX_TILES = 512 
NEURONS_PER_TILE = 16
QUANT_VAL = 64 # for weight quantization
THRESH = 64 # must be a mutliple of quant_val

def compile_to_arr(model, img=None, spk=None, mem=None):
    tile_idx, tiles, tiles_bias = model.tile_idx, model.tiles, model.tiles_bias 
    print("/* AUTO GENERATED CODE BY MODEL COMPILATION")
    print(" * IT IS HIGHLY DISCOURAGED TO EDIT THIS!!!")
    print(" */")

    print("/* EXPECTED OUTPUT")

    if(spk):
        for i in range(len(spk[0])):
            print(spk[2][i][0].tolist())

    print("*/")

    print("uint16_t tile_idx_x[] = {")
    for i in range(len(tiles)):
        print(f"{tile_idx[i][0]},")
    print("};\n")
    print("uint16_t tile_idx_y[] = {")
    for i in range(len(tiles)):
        print(f"{tile_idx[i][1]},")
    print("};\n")
    print("uint16_t tile_idx_x_ext[] = {")
    for i in range(len(tiles)):
        print(f"{tile_idx[i][2]},")
    print("};\n")
    print("uint16_t tile_idx_y_ext[] = {")
    for i in range(len(tiles)):
        print(f"{tile_idx[i][3]},")
    print("};\n")

    print("int8_t weight[] = {")
    for i in range(len(tiles)):
        for x in range(NEURONS_PER_TILE):
            for y in range(NEURONS_PER_TILE):
                val = int(tiles[i][y][x] * (THRESH / QUANT_VAL))
                print(f"{val},")
    print("};")

    if(img is not None):
        network_input = []
        if(img is not None):
            for i in range(sz*sz):
                network_input.append(int(round(img[i].item() * QUANT_VAL) * (THRESH / QUANT_VAL)))
        network_input += tiles_bias

        print("int8_t network_input[] = {")
        if(img is not None):
            for i in range(len(network_input)):
                val = int(network_input[i])
                print(f"{val},")

        print("};")



def compile_to_py_img(model, img=None, spk=None, mem=None):
    tile_idx, tiles, tiles_bias = model.tile_idx, model.tiles, model.tiles_bias 
    print("\"\"\" AUTO GENERATED CODE BY MODEL COMPILATION")
    print(" * IT IS HIGHLY DISCOURAGED TO EDIT THIS!!!")
    print(" \"\"\"")

    if(spk):
        print("\"\"\" EXPECTED OUTPUT")
        for i in range(len(spk[0])):
            print(spk[2][i][0].tolist())
        print("\"\"\"")

    print("tile_idx = [")
    for i in range(len(tiles)):
        print(f"[{tile_idx[i][0]}, {tile_idx[i][1]}, {tile_idx[i][2]}, {tile_idx[i][3]}],")
    for i in range(sz*sz // 16):
        print(f"[{i}, {i}, {0}, {0}],")
    print("]\n")

    print("tile = [")
    for i in range(len(tiles)):
        print("[")
        for x in range(NEURONS_PER_TILE):
            print("[")
            for y in range(NEURONS_PER_TILE):
                val = int(tiles[i][y][x] * (THRESH / QUANT_VAL))
                print(f"{val},")
            print("],")
        print("],")
    print("]")

    if(img is not None):
        network_input = []
        if(img is not None):
            for i in range(sz*sz):
                network_input.append(int(round(img[i].item() * QUANT_VAL) * (THRESH / QUANT_VAL)))
        network_input += tiles_bias

        print("snn_in = [")
        if(img is not None):
            for i in range(len(network_input)):
                val = int(network_input[i])
                print(f"{val},")

        print("]")

def compile_to_py(model, network_input=None, spk=None, mem=None):
    tile_idx, tiles, tiles_bias = model.tile_idx, model.tiles, model.tiles_bias 
    print("\"\"\" AUTO GENERATED CODE BY MODEL COMPILATION")
    print(" * IT IS HIGHLY DISCOURAGED TO EDIT THIS!!!")
    print(" \"\"\"")

    if(spk):
        print("\"\"\" EXPECTED OUTPUT")
        for i in range(len(spk[0])):
            print(spk[2][i][0].tolist())
        print("\"\"\"")

    print("tile_idx = [")
    for i in range(len(tiles)):
        print(f"[{tile_idx[i][0]}, {tile_idx[i][1]}, {tile_idx[i][2]}, {tile_idx[i][3]}],")
    #for i in range(sz*sz // 16):
    #    print(f"[{i}, {i}, {0}, {0}],")
    print("]\n")

    print("tile = [")
    for i in range(len(tiles)):
        print("[")
        for x in range(NEURONS_PER_TILE):
            print("[")
            for y in range(NEURONS_PER_TILE):
                val = int(tiles[i][y][x] * (THRESH / QUANT_VAL))
                print(f"{val},")
            print("],")
        print("],")
    print("]")

    if(network_input is not None):
        network_input# += tiles_bias
        #print(network_input)#, tiles_bias)

        print("snn_in = [")
        for i in range(len(network_input)):
            val = int(network_input[i])
            print(f"{val},")

        print("]")