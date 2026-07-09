import re

def update_notes():
    with open('scripts/PracticeRoom.gd', 'r', encoding='utf-8') as f:
        content = f.read()

    # First update the constants at the top
    content = content.replace(
"""const NOTES_VN : Array[String] = [
	"Sol", "La", "Đô", "Rê", "Mi",
	"Sol2", "La2", "Đô2", "Rê2", "Mi2",
	"Sol3", "La3", "Đô3", "Rê3", "Mi3",
	"Sol4"
]""", 
"""const NOTES_VN : Array[String] = [
	"Sol1", "La1", "Đô2", "Rê2", "Mi2",
	"Sol2", "La2", "Đô3", "Rê3", "Mi3",
	"Sol3", "La3", "Đô4", "Rê4", "Mi4",
	"Sol4", "La4" 
]""")

    content = content.replace(
"""const LANES : Array[String] = [
	"Sol", "La", "Đô", "Rê", "Mi",
	"Sol2", "La2", "Đô2", "Rê2", "Mi2",
	"Sol3", "La3", "Đô3", "Rê3", "Mi3",
	"Sol4"
]""",
"""const LANES : Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]""")

    content = content.replace("for i in 16:", "for i in 17:")

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
        
        # We only want to replace inside the sheet array for Giấc Mơ Trưa
        # It ends at the bracket "]"
        sheet_start = old_part.find('"sheet": [')
        sheet_end = old_part.find(']', sheet_start)
        
        if sheet_start != -1 and sheet_end != -1:
            sheet_content = old_part[sheet_start:sheet_end]
            new_sheet_content = re.sub(r'"(Sol\d*|La\d*|Đô\d*|Rê\d*|Mi\d*)"', replace_note, sheet_content)
            old_part = old_part[:sheet_start] + new_sheet_content + old_part[sheet_end:]
            
        content = parts[0] + '"Giấc Mơ Trưa"' + old_part
        
    with open('scripts/PracticeRoom.gd', 'w', encoding='utf-8') as f:
        f.write(content)

update_notes()
print("Success")
