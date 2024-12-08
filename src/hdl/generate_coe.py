import sys

sys.stdout = open("snn_bram_64.coe", "w")

depth = 8192
width = 128
byte_width = 128 // 8 
MAX_NEURONS = 1024
MAX_TILES = 32
NEURONS_PER_TILE = 16
arr = ["0" for i in range(depth)]
tiles = [[[0 for i in range(NEURONS_PER_TILE)] for i in range(NEURONS_PER_TILE)] for i in range(MAX_TILES)]
tile_idx = [[0, 0] for i in range(MAX_TILES)]
network_input = [0 for i in range(MAX_NEURONS)]

for i in range(MAX_TILES):
	tile_idx[i] = [i // 4, i % 4]

#TILE_WIDTH = width + NEURONS_PER_TILE*byte_width;
TILE_WIDTH = byte_width + NEURONS_PER_TILE*byte_width;

WEIGHT_OFFSET = 0; # word 1: core index, word 2...NEURONS_PER_TILE: weights
NETWORK_INPUT_OFFSET = TILE_WIDTH * MAX_TILES // byte_width;
SPK_OUT_OFFSET = (NETWORK_INPUT_OFFSET + MAX_NEURONS) // byte_width;
FLAGS_OFFSET = (SPK_OUT_OFFSET + MAX_NEURONS) // byte_width;

network_input[0] = 32;
network_input[1] = 32;
network_input[3] = 32;

tiles[0][0][4] = 32;
tiles[0][0][5] = -32;
tiles[0][1][4] = -32;
tiles[0][1][5] = 32;
tiles[0][2][6] = 32;
tiles[0][2][7] = -32;
tiles[0][3][6] = -32;
tiles[0][3][7] = 32;

tiles[0][4][8] = 32;
tiles[0][5][8] = 32;
tiles[0][6][9] = 32;
tiles[0][7][9] = 32;

tiles[0][8][10] = 32;
tiles[0][8][11] = -32;
tiles[0][9][10] = -32;
tiles[0][9][11] = 32;

tiles[1][10][0] = 32;
tiles[1][11][0] = 32;

def bin_(num, bit_width=8):
    """Convert a signed decimal number to binary with a fixed bit width."""
    if num < 0:
        # Convert to two's complement binary
        num = (1 << bit_width) + num  # Add 2^bit_width to the negative number
    # Format as binary with the specified width
    return format(num, f'0{bit_width}b')

for i in range(0, MAX_TILES):
	arr[WEIGHT_OFFSET + i * TILE_WIDTH // byte_width] = bin_(tile_idx[i][0]) + bin_(tile_idx[i][1]) 
	for j in range(NEURONS_PER_TILE):
		val = ""
		for k in range(byte_width-1, -1, -1):	
			val = val + bin_(tiles[i][j][k])
			#val = val + bin_(weight[x][y+j]);
		#val = bin_(weight[x][y+3]) + bin_(weight[x][y+2]) + bin_(weight[x][y+1]) + bin_(weight[x][y+0]) 	
		arr[WEIGHT_OFFSET + i*TILE_WIDTH // byte_width + j + 1] = val;


for i in range(0, MAX_NEURONS//byte_width):
	y = byte_width*i	
	#val = bin_(network_input[y+3]) + bin_(network_input[y+2]) + bin_(network_input[y+1]) + bin_(network_input[y+0]) 	
	val = ""
	for j in range(byte_width-1, -1, -1):	
		val = val + bin_(network_input[y+j]);

	arr[NETWORK_INPUT_OFFSET + i] = val;

#arr[enable_offset] = "1"
arr[FLAGS_OFFSET] = "1"
print("memory_initialization_radix=2;")
print("memory_initialization_vector=")
for s in arr:
	print(s + ",")
