from PIL import Image
import collections

img_path = r"E:\VietStageApp\assets\textures\virtual_artist_mai.png"
img = Image.open(img_path).convert("RGBA")
width, height = img.size

# We will perform BFS flood fill from all border pixels to ensure we catch all background areas.
queue = collections.deque()
visited = set()

# Add all border pixels to queue
for x in range(width):
    queue.append((x, 0))
    queue.append((x, height - 1))
    visited.add((x, 0))
    visited.add((x, height - 1))

for y in range(1, height - 1):
    queue.append((0, y))
    queue.append((width - 1, y))
    visited.add((0, y))
    visited.add((width - 1, y))

# Helper to check if a pixel is part of the checkerboard background.
# The background consists of alternating squares of white (approx 255, 255, 255)
# and light gray/cream (approx 225-235).
def is_background_color(r, g, b):
    # White check
    if r > 240 and g > 240 and b > 240:
        return True
    # Gray/Cream check
    if 210 <= r <= 242 and 210 <= g <= 242 and 210 <= b <= 242:
        # Check that it's relatively desaturated/neutral
        if abs(r - g) < 8 and abs(g - b) < 8 and abs(r - b) < 8:
            return True
    return False

# Load pixel data for fast access
pixels = img.load()

# Perform BFS
bg_pixels = []
while queue:
    x, y = queue.popleft()
    r, g, b, a = pixels[x, y]
    
    if is_background_color(r, g, b):
        bg_pixels.append((x, y))
        
        # Check 4-neighbors
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nx, ny = x + dx, y + dy
            if 0 <= nx < width and 0 <= ny < height:
                if (nx, ny) not in visited:
                    visited.add((nx, ny))
                    queue.append((nx, ny))

# Apply transparency to detected background pixels
for x, y in bg_pixels:
    pixels[x, y] = (0, 0, 0, 0)

# Optional: slight feathering/smoothing of edges
# For any pixel that is non-transparent but adjacent to a transparent pixel,
# if it is very close to the background color, make it semi-transparent or transparent.
for x in range(1, width - 1):
    for y in range(1, height - 1):
        r, g, b, a = pixels[x, y]
        if a > 0:
            # Check if any neighbor is transparent
            has_transparent_neighbor = False
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                if pixels[x + dx, y + dy][3] == 0:
                    has_transparent_neighbor = True
                    break
            
            if has_transparent_neighbor:
                # If it's close to background color, reduce its alpha
                # This helps smooth out the edges
                if is_background_color(r, g, b) or (r > 200 and g > 200 and b > 200 and abs(r - g) < 15 and abs(g - b) < 15):
                    pixels[x, y] = (r, g, b, 0)

img.save(img_path, "PNG")
print(f"Successfully removed background from {len(bg_pixels)} pixels and saved.")
