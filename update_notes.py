import re

def update_notes():
    with open('scripts/PracticeRoom.gd', 'r', encoding='utf-8') as f:
        content = f.read()

    mapping = {
        'Sol': 'Sol1', 'La': 'La1', 'Đô': 'Đô2', 'Rê': 'Rê2', 'Mi': 'Mi2',
        'Sol2': 'Sol2', 'La2': 'La2', 'Đô2': 'Đô3', 'Rê2': 'Rê3', 'Mi2': 'Mi3',
        'Sol3': 'Sol3', 'La3': 'La3', 'Đô3': 'Đô4', 'Rê3': 'Rê4', 'Mi3': 'Mi4',
        'Sol4': 'Sol4'
    }

    def replace_note(m):
        note = m.group(1)
        if note in mapping:
            return '"' + mapping[note] + '"'
        return m.group(0)

    parts = content.split('"Giấc Mơ Trưa"')
    if len(parts) > 1:
        old_part = parts[1]
        new_part = re.sub(r'"(Sol\d*|La\d*|Đô\d*|Rê\d*|Mi\d*)"', replace_note, old_part)
        content = parts[0] + '"Giấc Mơ Trưa"' + new_part
        
    with open('scripts/PracticeRoom.gd', 'w', encoding='utf-8') as f:
        f.write(content)

update_notes()
