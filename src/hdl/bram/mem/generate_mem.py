import sys

sys.stdout = open("bram.mem", "w")

MAX_TILES = 256
MAX_NEURONS = 1024
TILE_IDX_WIDTH = 16
CROSSBAR_NEURONS = 16
NETWORK_WIDTH = 8

tile_idx = [[0, 0] for i in range(MAX_TILES)]
tile = [[[0 for i in range(CROSSBAR_NEURONS)] for i in range(CROSSBAR_NEURONS)] for i in range(MAX_TILES)]
mem = [0 for i in range(MAX_NEURONS)]
snn_in = [0 for i in range(MAX_NEURONS)]
"""
snn_in[0] = 127;
snn_in[1] = 0;
snn_in[3] = 127;

snn_in[46] = 127;

tile[0][0][4] = 127;
tile[0][0][5] = -127;
tile[0][1][4] = -127;
tile[0][1][5] = 127;
tile[0][2][6] = 127;
tile[0][2][7] = -127;
tile[0][3][6] = -127;
tile[0][3][7] = 127;

tile[0][4][8] = 127;
tile[0][5][8] = 127;
tile[0][6][9] = 127;
tile[0][7][9] = 127;

tile[0][8][10] = 127;
tile[0][8][11] = -127;
tile[0][9][10] = -127;
tile[0][9][11] = 127;

tile[0][10][12] = 127;
tile[0][10][11] = 127;

tile[1][0][15] = 32;
for i in range(MAX_TILES):
	tile_idx[i] = [i // 8, i % 8]
"""

tile[0][13][0] = 127
tile[0][13][1] = 127

snn_in[13] = 127
tile_idx[0] = [1, 2]
tile_idx[1] = [0, 3]

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
    with open(path, "w+") as sys.stdout:
        for i in range(0, depth * width):
            s = ''.join(memory[i*width : (i+1)*width])
            if(rev):
                s = endian(s, bytewidth)
            print(s)


def write_tile_idx():
    memory = ["0" for i in range(32*1024)] 
    for i in range(0, MAX_TILES):
        memory[TILE_IDX_WIDTH*2*i : TILE_IDX_WIDTH*2*(i+1)] = bin_(tile_idx[i][1], 16) + bin_(tile_idx[i][0], 16)
    printmem(memory, "./tile_idx_bram.mem", 32, 1024, bytewidth=16)

def write_weight():
    memory = ["0" for i in range(1024*1024)] 
    for i in range(0, MAX_TILES):
        for j in range(CROSSBAR_NEURONS):
            for k in range(CROSSBAR_NEURONS):
                base = (i*CROSSBAR_NEURONS*CROSSBAR_NEURONS + j*CROSSBAR_NEURONS + k) * NETWORK_WIDTH
                #print(base, bin_(tile[i][j][k], 8))
                memory[base:base+NETWORK_WIDTH] = bin_(tile[i][j][k], NETWORK_WIDTH)
    printmem(memory, "./weight_bram.mem", 1024, 1024, rev=True);

def write_input():
    memory = ["0" for i in range(8*1024)]
    for i in range(0, MAX_NEURONS):
        base = i*NETWORK_WIDTH
        memory[base:base+NETWORK_WIDTH] = bin_(snn_in[i], NETWORK_WIDTH)
    printmem(memory, "./input_bram.mem", 128, 1024, rev=True)
    

def write_mem():
    memory = ["0" for i in range(8*1024)]
    for i in range(0, MAX_NEURONS):
        base = i*NETWORK_WIDTH
        #print(bin_(mem[i], 8))
        memory[base:base+NETWORK_WIDTH] = bin_(mem[i], NETWORK_WIDTH)
    printmem(memory, "./mem_bram.mem", 128, 1024, rev=True)

def write_spk_in():
    memory = ["0" for i in range(1024)]
    for i in range(0, MAX_NEURONS):
        base = i
        memory[base] = '0'
    printmem(memory, "./spk_in_bram.mem", 16, 1024)

write_tile_idx()
write_weight()
write_input()
write_mem()
write_spk_in()