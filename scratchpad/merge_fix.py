import re

with open('scripts/MainMenu.gd', 'r', encoding='utf-8') as f:
    content = f.read()

def resolve(match):
    head = match.group(1).strip('\r\n')
    namfix = match.group(2).strip('\r\n')
    
    # We combine them. If one contains 'else:', we move it to the end.
    lines = (head + '\n' + namfix).split('\n')
    
    out_lines = []
    else_lines = []
    
    in_else = False
    for line in lines:
        if line.strip() == 'else:':
            in_else = True
            else_lines.append(line)
        elif in_else:
            if line.strip().startswith('elif '):
                # switch back
                in_else = False
                out_lines.append(line)
            else:
                else_lines.append(line)
        else:
            if line.strip() != '=======':
                out_lines.append(line)
                
    # Also handle the function conflict
    if 'func _set_details_text' in head:
        return head
        
    return '\n'.join(out_lines + else_lines)

pattern = re.compile(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> [a-f0-9]+', re.DOTALL)
new_content = pattern.sub(resolve, content)

with open('scripts/MainMenu.gd', 'w', encoding='utf-8') as f:
    f.write(new_content)
print('Done resolving.')
