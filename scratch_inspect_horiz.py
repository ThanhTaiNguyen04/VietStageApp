from PIL import Image

img_path = r"E:\VietStageApp\assets\textures\virtual_artist_mai.png"
img = Image.open(img_path)
for x in range(0, img.width, 32):
    print(f"x={x}: {img.getpixel((x, 10))}")
