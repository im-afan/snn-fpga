import sys

sys.stdout = open("bram.mem", "w")

MAX_TILES = 128
MAX_NEURONS = 1024
TILE_IDX_WIDTH = 16
BRAM_DATA_WIDTH = 1024
CROSSBAR_NEURONS = 16
NETWORK_WIDTH = 8

TILE_IDX_BITS = ((2*TILE_IDX_WIDTH*MAX_TILES) // BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;
WEIGHT_BITS = ((MAX_TILES*CROSSBAR_NEURONS*CROSSBAR_NEURONS*NETWORK_WIDTH) // BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;
NETWORK_INPUT_BITS = ((MAX_NEURONS*NETWORK_WIDTH) // BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;
SPK_OUT_BITS = 2 * ((MAX_NEURONS) // BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;
FLAGS_BITS = BRAM_DATA_WIDTH;
TILE_IDX_OFFSET = 0;

WEIGHT_OFFSET = TILE_IDX_OFFSET + TILE_IDX_BITS;
NETWORK_INPUT_OFFSET = WEIGHT_OFFSET + WEIGHT_BITS;
SPK_OUT_OFFSET = NETWORK_INPUT_OFFSET + NETWORK_INPUT_BITS;
FLAGS_OFFSET = SPK_OUT_OFFSET + SPK_OUT_BITS;
MEM_OFFSET = FLAGS_OFFSET + FLAGS_BITS;

tile_idx = [[0, 0] for i in range(MAX_TILES)]
tile = [[[0 for i in range(CROSSBAR_NEURONS)] for i in range(CROSSBAR_NEURONS)] for i in range(MAX_TILES)]
#mem = [i%256 for i in range(MAX_NEURONS)]
mem = [0 for i in range(MAX_NEURONS)]
snn_in = [0 for i in range(MAX_NEURONS)]
memory = ["0" for i in range(BRAM_DATA_WIDTH*1024)] 

snn_in[0] = 32;
snn_in[1] = 32;
snn_in[3] = 32;

tile[0][0][4] = 32;
tile[0][0][5] = -32;
tile[0][1][4] = -32;
tile[0][1][5] = 32;
tile[0][2][6] = 32;
tile[0][2][7] = -32;
tile[0][3][6] = -32;
tile[0][3][7] = 32;

tile[0][4][8] = 32;
tile[0][5][8] = 32;
tile[0][6][9] = 32;
tile[0][7][9] = 32;

tile[0][8][10] = 32;
tile[0][8][11] = -32;
tile[0][9][10] = -32;
tile[0][9][11] = 32;

tile[0][10][12] = 32;
tile[0][10][11] = 32;

#tile[1][10][0] = 32;
#tile[1][11][0] = 32;

tile[1][0][15] = 32;


for i in range(MAX_TILES):
	tile_idx[i] = [i // 8, i % 8]

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

for i in range(0, MAX_TILES):
    memory[TILE_IDX_OFFSET + TILE_IDX_WIDTH*2*i : TILE_IDX_OFFSET + TILE_IDX_WIDTH*2*(i+1)] = bin_(tile_idx[i][0], 16) + bin_(tile_idx[i][1], 16)
    #print(memory[TILE_IDX_OFFSET + TILE_IDX_WIDTH*2*i : TILE_IDX_OFFSET + TILE_IDX_WIDTH*2*(i+1)])

for i in range(0, MAX_TILES):
    for j in range(CROSSBAR_NEURONS):
        for k in range(CROSSBAR_NEURONS):
            base = WEIGHT_OFFSET + (i*CROSSBAR_NEURONS*CROSSBAR_NEURONS + j*CROSSBAR_NEURONS + k) * NETWORK_WIDTH
            #print(base, bin_(tile[i][j][k], 8))
            memory[base:base+NETWORK_WIDTH] = bin_(tile[i][j][k], NETWORK_WIDTH)

for i in range(0, MAX_NEURONS):
    base = NETWORK_INPUT_OFFSET + i*NETWORK_WIDTH
    memory[base:base+NETWORK_WIDTH] = bin_(snn_in[i], NETWORK_WIDTH);

for i in range(0, MAX_NEURONS):
    base = MEM_OFFSET + i*NETWORK_WIDTH
    #print(bin_(mem[i], 8))
    memory[base:base+NETWORK_WIDTH] = bin_(mem[i], NETWORK_WIDTH)

for i in range(0, MAX_NEURONS):
    base = SPK_OUT_OFFSET + i
    memory[base] = '0'

for i in range(0, 1024):
    s = ''.join(memory[i*1024 : (i+1)*1024])
    if(i < 2):
        s = endian(s, 16)
    else:
        s = endian(s, 8)
    #s = ''.join(reversed(s)) 
    print(s)