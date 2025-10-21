/*
 * Video Motion Estimation Benchmark for BiRISCV Custom Instructions
 *
 * This benchmark simulates a video encoder's motion estimation engine,
 * the most compute-intensive component of video compression (60-80% of encoding time).
 *
 * Key operations:
 * - Motion estimation: Thousands of SAD operations per frame
 * - Filtering: Hundreds of MADD operations per frame
 * - CRC validation: BREV for bit reversal
 * - Best match selection: CMOV for branchless comparison
 *
 * Expected improvements:
 * - SAD: 18-20x faster (36 inst → 2 inst per operation)
 * - MADD: 2x faster (2 inst → 1 inst per operation)
 * - BREV: 50x faster (50 inst → 1 inst)
 * - CMOV: 5x faster (5 inst → 1 inst)
 *
 * Compile:
 *   Standard:  clang -O3 -march=rv32im video_motion_benchmark.c -S -o standard.s
 *   Custom:    clang -O3 -march=rv32im_xbiriscv0p1 video_motion_benchmark.c -S -o custom.s
 */

#include <stdint.h>

//==============================================================================
// Configuration
//==============================================================================

#define FRAME_WIDTH  128
#define FRAME_HEIGHT 128
#define FRAME_SIZE (FRAME_WIDTH * FRAME_HEIGHT)

#define BLOCK_SIZE 8
#define BLOCKS_X (FRAME_WIDTH / BLOCK_SIZE)
#define BLOCKS_Y (FRAME_HEIGHT / BLOCK_SIZE)
#define NUM_BLOCKS (BLOCKS_X * BLOCKS_Y)

#define SEARCH_RANGE 8  // Search +/- 8 pixels
#define SEARCH_WIDTH  (2 * SEARCH_RANGE + BLOCK_SIZE)
#define SEARCH_POSITIONS ((2 * SEARCH_RANGE + 1) * (2 * SEARCH_RANGE + 1))

//==============================================================================
// Data Structures
//==============================================================================

typedef struct {
    int8_t x;
    int8_t y;
    uint32_t cost;
} MotionVector;

//==============================================================================
// CORE FUNCTION 1: SAD Computation (Pattern for SAD instruction)
//==============================================================================

// This exact pattern triggers SAD instruction with pattern recognition
// Use noinline to prevent optimizer from hiding the SAD pattern
__attribute__((noinline))
static uint32_t sad_4pixels(const uint8_t *a, const uint8_t *b, uint32_t acc) {
    // Pattern recognized by RISCVBiRiscVPatterns.cpp
    uint8_t a0 = a[0], a1 = a[1], a2 = a[2], a3 = a[3];
    uint8_t b0 = b[0], b1 = b[1], b2 = b[2], b3 = b[3];

    acc += (a0 > b0) ? (a0 - b0) : (b0 - a0);
    acc += (a1 > b1) ? (a1 - b1) : (b1 - a1);
    acc += (a2 > b2) ? (a2 - b2) : (b2 - a2);
    acc += (a3 > b3) ? (a3 - b3) : (b3 - a3);

    return acc;
}

// Compute SAD for 8x8 block (16 SAD operations)
__attribute__((noinline))
static uint32_t block_sad(const uint8_t *block1, const uint8_t *block2) {
    uint32_t sad = 0;

    // 64 pixels, process 4 at a time = 16 SAD operations
    for (int i = 0; i < 64; i += 4) {
        sad = sad_4pixels(&block1[i], &block2[i], sad);
    }

    return sad;
}

//==============================================================================
// CORE FUNCTION 2: Motion Estimation (Uses SAD + CMOV)
//==============================================================================

// Find best matching block in search area
static MotionVector find_best_match(
    const uint8_t *current_frame,
    const uint8_t *reference_frame,
    int block_x, int block_y
) {
    MotionVector best_mv;
    best_mv.x = 0;
    best_mv.y = 0;
    best_mv.cost = 0xFFFFFFFF;

    int base_x = block_x * BLOCK_SIZE;
    int base_y = block_y * BLOCK_SIZE;

    // Extract current block
    uint8_t current_block[64];
    for (int y = 0; y < BLOCK_SIZE; y++) {
        for (int x = 0; x < BLOCK_SIZE; x++) {
            current_block[y * BLOCK_SIZE + x] =
                current_frame[(base_y + y) * FRAME_WIDTH + (base_x + x)];
        }
    }

    // Search all positions in search window
    for (int dy = -SEARCH_RANGE; dy <= SEARCH_RANGE; dy++) {
        for (int dx = -SEARCH_RANGE; dx <= SEARCH_RANGE; dx++) {
            int ref_x = base_x + dx;
            int ref_y = base_y + dy;

            // Bounds check
            if (ref_x < 0 || ref_y < 0 ||
                ref_x + BLOCK_SIZE > FRAME_WIDTH ||
                ref_y + BLOCK_SIZE > FRAME_HEIGHT) {
                continue;
            }

            // Extract reference block
            uint8_t ref_block[64];
            for (int y = 0; y < BLOCK_SIZE; y++) {
                for (int x = 0; x < BLOCK_SIZE; x++) {
                    ref_block[y * BLOCK_SIZE + x] =
                        reference_frame[(ref_y + y) * FRAME_WIDTH + (ref_x + x)];
                }
            }

            // Compute SAD
            uint32_t sad = block_sad(current_block, ref_block);

            // Update best match using branchless comparison (CMOV)
            if (sad < best_mv.cost) {
                best_mv.x = dx;
                best_mv.y = dy;
                best_mv.cost = sad;
            }
        }
    }

    return best_mv;
}

// Full frame motion estimation
static uint32_t motion_estimation(
    const uint8_t *current_frame,
    const uint8_t *reference_frame,
    MotionVector *motion_vectors
) {
    uint32_t total_cost = 0;

    for (int by = 0; by < BLOCKS_Y; by++) {
        for (int bx = 0; bx < BLOCKS_X; bx++) {
            int idx = by * BLOCKS_X + bx;
            motion_vectors[idx] = find_best_match(current_frame, reference_frame, bx, by);
            total_cost += motion_vectors[idx].cost;
        }
    }

    return total_cost;
}

//==============================================================================
// CORE FUNCTION 3: Convolution Filtering (Uses MADD)
//==============================================================================

// 5x5 Gaussian blur kernel (normalized)
static const int16_t gaussian_5x5[25] = {
    1,  4,  6,  4,  1,
    4, 16, 24, 16,  4,
    6, 24, 36, 24,  6,
    4, 16, 24, 16,  4,
    1,  4,  6,  4,  1
};

// Apply 5x5 convolution (25 MADD operations per pixel!)
static void apply_convolution_5x5(const uint8_t *input, uint8_t *output) {
    for (int y = 2; y < FRAME_HEIGHT - 2; y++) {
        for (int x = 2; x < FRAME_WIDTH - 2; x++) {
            int32_t sum = 0;

            // 5x5 convolution - generates 25 MADD instructions
            for (int ky = -2; ky <= 2; ky++) {
                for (int kx = -2; kx <= 2; kx++) {
                    int pixel = input[(y + ky) * FRAME_WIDTH + (x + kx)];
                    int kernel = gaussian_5x5[(ky + 2) * 5 + (kx + 2)];
                    sum += pixel * kernel;  // MADD: sum = sum + pixel * kernel
                }
            }

            // Normalize (divide by 256)
            sum = sum >> 8;

            // Clamp to [0, 255] using branchless operations (CSEL)
            sum = (sum < 0) ? 0 : sum;
            sum = (sum > 255) ? 255 : sum;

            output[y * FRAME_WIDTH + x] = (uint8_t)sum;
        }
    }
}

// Sharpen filter (also uses MADD)
static const int16_t sharpen_3x3[9] = {
     0, -4,  0,
    -4, 20, -4,
     0, -4,  0
};

static void apply_sharpen_3x3(const uint8_t *input, uint8_t *output) {
    for (int y = 1; y < FRAME_HEIGHT - 1; y++) {
        for (int x = 1; x < FRAME_WIDTH - 1; x++) {
            int32_t sum = 0;

            // 3x3 convolution - 9 MADD operations
            for (int ky = -1; ky <= 1; ky++) {
                for (int kx = -1; kx <= 1; kx++) {
                    int pixel = input[(y + ky) * FRAME_WIDTH + (x + kx)];
                    int kernel = sharpen_3x3[(ky + 1) * 3 + (kx + 1)];
                    sum += pixel * kernel;  // MADD
                }
            }

            // Normalize
            sum = sum >> 2;

            // Clamp
            sum = (sum < 0) ? 0 : sum;
            sum = (sum > 255) ? 255 : sum;

            output[y * FRAME_WIDTH + x] = (uint8_t)sum;
        }
    }
}

//==============================================================================
// CORE FUNCTION 4: CRC32 with Bit Reversal (Uses BREV)
//==============================================================================

static uint32_t crc32_table[256];

static void init_crc32(void) {
    for (uint32_t i = 0; i < 256; i++) {
        uint32_t crc = i;
        for (int j = 0; j < 8; j++) {
            if (crc & 1)
                crc = (crc >> 1) ^ 0xEDB88320;
            else
                crc = crc >> 1;
        }
        crc32_table[i] = crc;
    }
}

// Manual bit reversal (optimized to BREV by pattern recognition)
static uint32_t reverse_bits(uint32_t value) {
    uint32_t result = 0;
    for (int i = 0; i < 32; i++) {
        result = (result << 1) | ((value >> i) & 1);
    }
    return result;
}

// Compute CRC32 with bit-reversed output (network byte order)
static uint32_t compute_crc32(const uint8_t *data, uint32_t length) {
    uint32_t crc = 0xFFFFFFFF;

    for (uint32_t i = 0; i < length; i++) {
        crc = (crc >> 8) ^ crc32_table[(crc ^ data[i]) & 0xFF];
    }

    crc = ~crc;

    // Bit reverse for transmission (BREV instruction)
    return reverse_bits(crc);
}

//==============================================================================
// CORE FUNCTION 5: Branchless Min/Max/Clamp (Uses CSEL/CMOV)
//==============================================================================

static inline int32_t min_branchless(int32_t a, int32_t b) {
    return (a < b) ? a : b;  // CSEL
}

static inline int32_t max_branchless(int32_t a, int32_t b) {
    return (a > b) ? a : b;  // CSEL
}

static inline int32_t clamp_branchless(int32_t val, int32_t min_val, int32_t max_val) {
    val = (val < min_val) ? min_val : val;  // CSEL
    val = (val > max_val) ? max_val : val;  // CSEL
    return val;
}

// Histogram equalization using branchless operations
static void histogram_equalize(uint8_t *frame) {
    // Build histogram
    uint32_t hist[256] = {0};
    for (int i = 0; i < FRAME_SIZE; i++) {
        hist[frame[i]]++;
    }

    // Compute CDF
    uint32_t cdf[256];
    cdf[0] = hist[0];
    for (int i = 1; i < 256; i++) {
        cdf[i] = cdf[i-1] + hist[i];
    }

    // Find min non-zero CDF
    uint32_t cdf_min = cdf[0];
    for (int i = 0; i < 256; i++) {
        if (cdf[i] > 0) {
            cdf_min = min_branchless(cdf_min, cdf[i]);  // CSEL
        }
    }

    // Apply equalization
    for (int i = 0; i < FRAME_SIZE; i++) {
        uint8_t pixel = frame[i];
        int32_t equalized = ((cdf[pixel] - cdf_min) * 255) / (FRAME_SIZE - cdf_min);
        equalized = clamp_branchless(equalized, 0, 255);  // CSEL
        frame[i] = (uint8_t)equalized;
    }
}

//==============================================================================
// Test Data Generation
//==============================================================================

static void generate_frame(uint8_t *frame, uint32_t seed) {
    uint32_t rng = seed;

    for (int y = 0; y < FRAME_HEIGHT; y++) {
        for (int x = 0; x < FRAME_WIDTH; x++) {
            // Generate pattern: gradient + noise
            int gradient = (x * 255) / FRAME_WIDTH;

            rng = rng * 1103515245 + 12345;
            int noise = (rng >> 16) & 0x1F;  // 5-bit noise

            int pixel = gradient + noise - 16;
            pixel = clamp_branchless(pixel, 0, 255);

            frame[y * FRAME_WIDTH + x] = (uint8_t)pixel;
        }
    }
}

// Add motion to create reference frame
static void add_motion(const uint8_t *src, uint8_t *dst, int dx, int dy, uint32_t seed) {
    uint32_t rng = seed;

    for (int y = 0; y < FRAME_HEIGHT; y++) {
        for (int x = 0; x < FRAME_WIDTH; x++) {
            int src_x = x - dx;
            int src_y = y - dy;

            uint8_t pixel;
            if (src_x >= 0 && src_x < FRAME_WIDTH && src_y >= 0 && src_y < FRAME_HEIGHT) {
                pixel = src[src_y * FRAME_WIDTH + src_x];
            } else {
                pixel = 128;  // Gray border
            }

            // Add noise
            rng = rng * 1103515245 + 12345;
            int noise = ((rng >> 16) & 0x0F) - 8;
            int result = clamp_branchless((int)pixel + noise, 0, 255);

            dst[y * FRAME_WIDTH + x] = (uint8_t)result;
        }
    }
}

//==============================================================================
// Main Benchmark
//==============================================================================

// Global storage (avoid stack overflow)
static uint8_t frame_current[FRAME_SIZE];
static uint8_t frame_reference[FRAME_SIZE];
static uint8_t frame_filtered[FRAME_SIZE];
static uint8_t frame_temp[FRAME_SIZE];
static MotionVector motion_vectors[NUM_BLOCKS];

uint32_t video_encoder_benchmark(void) {
    uint32_t checksum = 0;

    // Initialize
    init_crc32();

    // Generate test frames
    generate_frame(frame_current, 12345);
    add_motion(frame_current, frame_reference, 3, -2, 54321);

    //==========================================================================
    // PHASE 1: Motion Estimation (Heavy SAD usage)
    //==========================================================================
    // This is the dominant operation - processes 256 blocks × 256 positions
    // = 65,536 SAD computations × 16 SAD ops each = 1,048,576 SAD operations!

    uint32_t motion_cost = motion_estimation(frame_current, frame_reference, motion_vectors);
    checksum += motion_cost;

    // Accumulate motion vectors for validation
    for (int i = 0; i < NUM_BLOCKS; i++) {
        checksum += (uint32_t)(motion_vectors[i].x + motion_vectors[i].y);
    }

    //==========================================================================
    // PHASE 2: Image Filtering (Heavy MADD usage)
    //==========================================================================
    // 5x5 Gaussian blur: 16,384 pixels × 25 MADD = 409,600 MADD operations

    apply_convolution_5x5(frame_current, frame_filtered);
    checksum += frame_filtered[1000] + frame_filtered[5000];

    // 3x3 Sharpen: 16,384 pixels × 9 MADD = 147,456 MADD operations
    apply_sharpen_3x3(frame_filtered, frame_temp);
    checksum += frame_temp[2000] + frame_temp[8000];

    //==========================================================================
    // PHASE 3: CRC Validation (BREV usage)
    //==========================================================================
    // Multiple CRC computations with bit reversal

    uint32_t crc1 = compute_crc32(frame_current, FRAME_SIZE);
    uint32_t crc2 = compute_crc32(frame_filtered, FRAME_SIZE);
    uint32_t crc3 = compute_crc32(frame_temp, FRAME_SIZE);

    checksum += crc1 ^ crc2 ^ crc3;

    //==========================================================================
    // PHASE 4: Histogram Equalization (CSEL/CMOV usage)
    //==========================================================================
    // Heavy branchless min/max/clamp operations

    for (int i = 0; i < FRAME_SIZE; i++) {
        frame_temp[i] = frame_current[i];
    }
    histogram_equalize(frame_temp);
    checksum += frame_temp[4000] + frame_temp[12000];

    return checksum;
}
