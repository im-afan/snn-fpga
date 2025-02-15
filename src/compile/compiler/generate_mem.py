import sys

MAX_TILES = 512
MAX_NEURONS = 1024
TILE_IDX_WIDTH = 16
CROSSBAR_NEURONS = 16
NETWORK_WIDTH = 8
PATH = "../hdl/bram/mem"

spk = None
tile_idx = [[0, 0] for i in range(MAX_TILES)]
tile = [[[0 for i in range(CROSSBAR_NEURONS)] for i in range(CROSSBAR_NEURONS)] for i in range(MAX_TILES)]
mem = [0 for i in range(MAX_NEURONS)]
snn_in = [0 for i in range(MAX_NEURONS)]

def bin_(num, bit_width=8):
    """Convert a signed decimal number to binary with a fixed bit width."""
    if num < 0:
        # Convert to two's complement binary
        num = (1 << bit_width) + num  # Add 2^bit_width to the negative number
    # Format as binary with the specified width
    return format(num, f'0{bit_width}b')

def endian(binary_string, width=8):
    if len(binary_string) % width != 0:
        raise ValueError("Binary string length must be a multiple of width")
    
    byte_chunks = [binary_string[i:i+width] for i in range(0, len(binary_string), width)]
    reversed_chunks = byte_chunks[::-1]
    big_endian_string = ''.join(reversed_chunks)
    
    return big_endian_string

def printmem(memory, path, width, depth, rev=False, bytewidth=8):
    #width1 = 32
    #depth = 256
    #rev = True 
    with open(path, "w+") as sys.stdout:
        print("/* EXPECTED OUTPUT")
        #print(f"{torch.stack(spk[0], dim=0)}")
        for i in range(len(spk[0])):
            #print(mem[1][i][0][:20].tolist())
            print(spk[2][i][0].tolist())
        print("*/")


        for i in range(0, depth * width):
            s = ''.join(memory[i*width : (i+1)*width])
            if(rev):
                s = endian(s, bytewidth)
            print(s)


def write_tile_idx():
    memory = ["1" for i in range(32*1024)] 
    for i in range(0, len(tile_idx)):
        memory[TILE_IDX_WIDTH*2*i : TILE_IDX_WIDTH*2*(i+1)] = bin_(tile_idx[i][1], 16) + bin_(tile_idx[i][0], 16)
    printmem(memory, PATH + "/tile_idx_bram.mem", 32, 1024, bytewidth=16)

def write_weight():

    memory = ["0" for i in range(2048*1024)] 
    for i in range(0, len(tile)):
        for j in range(CROSSBAR_NEURONS):
            for k in range(CROSSBAR_NEURONS):
                base = (i*CROSSBAR_NEURONS*CROSSBAR_NEURONS + j*CROSSBAR_NEURONS + k) * NETWORK_WIDTH
                memory[base:base+NETWORK_WIDTH] = bin_(int(tile[i][j][k]), NETWORK_WIDTH)
    printmem(memory, PATH + "/weight_bram.mem", 2048, 1024, rev=True);

def write_input():
    memory = ["0" for i in range(8*1024)]
    for i in range(0, len(snn_in)):
        base = i*NETWORK_WIDTH
        memory[base:base+NETWORK_WIDTH] = bin_(int(snn_in[i]), NETWORK_WIDTH)
    printmem(memory, PATH + "/input_bram.mem", 128, 1024, rev=True)
    

def write_mem():
    memory = ["0" for i in range(8*1024)]
    for i in range(0, MAX_NEURONS):
        base = i*NETWORK_WIDTH
        #print(bin_(mem[i], 8))
        memory[base:base+NETWORK_WIDTH] = bin_(int(mem[i]), NETWORK_WIDTH)
    printmem(memory, PATH + "/mem_bram.mem", 128, 1024, rev=True)

def write_spk_in():
    memory = ["0" for i in range(1024)]
    for i in range(0, MAX_NEURONS):
        base = i
        memory[base] = '0'
    printmem(memory, PATH + "/spk_in_bram.mem", 16, 1024)

def generate_mem(tile_, tile_idx_, network_input_, path=".", spk_=None):
    global tile, tile_idx, snn_in, PATH, spk
    #PATH = path
    tile = tile_
    tile_idx = tile_idx_
    snn_in = network_input_ 
    spk = spk_
    print(spk, spk_)
    write_tile_idx()
    write_weight()
    write_input()
    write_mem()
    write_spk_in()