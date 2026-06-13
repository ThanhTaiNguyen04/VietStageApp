from PIL import Image

img_path = r"E:\VietStageApp\assets\textures\virtual_artist_mai.png"
img = Image.open(img_path)
print(f"Size: {img.size}")
print(f"Mode: {img.mode}")

# Print colors from top-left area
for y in range(20):
    row_colors = [img.getpixel((x, y)) for x in range(20)]
    print(f"Row {y:2d}: {row_colors[:10]} ...")
