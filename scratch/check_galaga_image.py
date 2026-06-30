from PIL import Image
import os

p = "content/cartridges/galaga/thumbnail.png"
if os.path.exists(p):
    img = Image.open(p)
    print(f"Format: {img.format}, Size: {img.size}, Mode: {img.mode}")
    # Get extremum (min/max colors)
    print(f"Extrema: {img.getextrema()}")
    # Check average color
    pixels = list(img.getdata())
    avg_color = tuple(sum(col) // len(col) for col in zip(*pixels)) if isinstance(pixels[0], tuple) else sum(pixels)//len(pixels)
    print(f"Average Color: {avg_color}")
else:
    print("Galaga thumbnail does not exist!")
