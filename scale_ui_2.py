import re
import math

def scale_value(val_str):
    val = float(val_str)
    return str(math.ceil(val * 1.5))

def scale_vector2(x_str, y_str):
    x = float(x_str)
    y = float(y_str)
    return f"Vector2({math.ceil(x * 1.5)}, {math.ceil(y * 1.5)})"

def process_gd(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # pivot_offset = Vector2(X, Y)
    content = re.sub(r'pivot_offset\s*=\s*Vector2\(\s*([\d\.]+)\s*,\s*([\d\.]+)\s*\)', lambda m: f"pivot_offset = {scale_vector2(m.group(1), m.group(2))}", content)
    
    # corner_radius
    content = re.sub(r'corner_radius_(top_left|top_right|bottom_right|bottom_left)\s*=\s*(\d+)', lambda m: f"corner_radius_{m.group(1)} = {scale_value(m.group(2))}", content)
    
    # expand_margin
    content = re.sub(r'expand_margin_(left|right|top|bottom)\s*=\s*(\d+)', lambda m: f"expand_margin_{m.group(1)} = {scale_value(m.group(2))}", content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

process_gd('d:/vietstage25d/scripts/PracticeSaoTruc.gd')
print("Secondary scaling completed.")
