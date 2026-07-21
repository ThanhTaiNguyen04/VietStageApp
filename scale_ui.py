import re
import math

def scale_value(val_str):
    val = float(val_str)
    return str(math.ceil(val * 1.5))

def scale_vector2(x_str, y_str):
    x = float(x_str)
    y = float(y_str)
    return f"Vector2({math.ceil(x * 1.5)}, {math.ceil(y * 1.5)})"

def process_tscn(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Scale font_size
    content = re.sub(r'theme_override_font_sizes/font_size\s*=\s*(\d+)', lambda m: f"theme_override_font_sizes/font_size = {scale_value(m.group(1))}", content)
    # Scale margins
    content = re.sub(r'theme_override_constants/margin_(left|right|top|bottom)\s*=\s*(\d+)', lambda m: f"theme_override_constants/margin_{m.group(1)} = {scale_value(m.group(2))}", content)
    # Scale separation
    content = re.sub(r'theme_override_constants/separation\s*=\s*(\d+)', lambda m: f"theme_override_constants/separation = {scale_value(m.group(1))}", content)
    # Scale custom_minimum_size
    content = re.sub(r'custom_minimum_size\s*=\s*Vector2\(\s*([\d\.]+)\s*,\s*([\d\.]+)\s*\)', lambda m: f"custom_minimum_size = {scale_vector2(m.group(1), m.group(2))}", content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def process_gd(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # add_theme_font_size_override("font_size", 20)
    content = re.sub(r'add_theme_font_size_override\("font_size",\s*(\d+)\)', lambda m: f'add_theme_font_size_override("font_size", {scale_value(m.group(1))})', content)
    # custom_minimum_size = Vector2(X, Y)
    content = re.sub(r'custom_minimum_size\s*=\s*Vector2\(\s*([\d\.]+)\s*,\s*([\d\.]+)\s*\)', lambda m: f"custom_minimum_size = {scale_vector2(m.group(1), m.group(2))}", content)
    # custom_minimum_size.y = X
    content = re.sub(r'custom_minimum_size\.y\s*=\s*([\d\.]+)', lambda m: f"custom_minimum_size.y = {scale_value(m.group(1))}", content)
    
    # Scale lane_h inside gdscript
    content = re.sub(r'var lane_h\s*:=\s*([\d\.]+)', lambda m: f"var lane_h := {float(m.group(1)) * 1.5}", content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

process_tscn('d:/vietstage25d/scenes/PracticeSaoTruc.tscn')
process_gd('d:/vietstage25d/scripts/PracticeSaoTruc.gd')
print("Scaling completed.")
