import sys

sys.stdout = open("bram.mem", "w")

MAX_TILES = 64
MAX_NEURONS = 1024

tile_idx = [[0, 0] for i in range(MAX_TILES)]
#arr = ["0" for i in range(1024)]
mem = "" 


for i in range(MAX_TILES):
	tile_idx[i] = [i // 8, i % 8]

BRAM_DATA_WIDTH = 1024
TILE_IDX_WIDTH = 16
CROSSBAR_NEURONS = 16
NETWORK_WIDTH = 8

TILE_IDX_OFFSET = 0;
WEIGHT_OFFSET = TILE_IDX_OFFSET + ((2*TILE_IDX_WIDTH*MAX_TILES) // BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH / 8;
NETWORK_INPUT_OFFSET = WEIGHT_OFFSET + CROSSBAR_NEURONS*CROSSBAR_NEURONS*NETWORK_WIDTH/8 * MAX_TILES;
SPK_OUT_OFFSET = NETWORK_INPUT_OFFSET + (MAX_NEURONS * NETWORK_WIDTH // BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH / 8;
FLAGS_OFFSET = SPK_OUT_OFFSET + BRAM_DATA_WIDTH / 8;
MEM_OFFSET = FLAGS_OFFSET + BRAM_DATA_WIDTH / 8;

def bin_(num, bit_width=16):
    """Convert a signed decimal number to binary with a fixed bit width."""
    if num < 0:
        # Convert to two's complement binary
        num = (1 << bit_width) + num  # Add 2^bit_width to the negative number
    # Format as binary with the specified width
    return format(num, f'0{bit_width}b')

mem0 = ""
mem1 = ""
for i in range(0, MAX_TILES // 2):
    mem0 = bin_(tile_idx[i][0], TILE_IDX_WIDTH) + mem0
    mem0 = bin_(tile_idx[i][1], TILE_IDX_WIDTH) + mem0
for i in range(MAX_TILES // 2, MAX_TILES):
    mem1 = bin_(tile_idx[i][0], TILE_IDX_WIDTH) + mem1
    mem1 = bin_(tile_idx[i][1], TILE_IDX_WIDTH) + mem1


print(mem0)
print(mem1)