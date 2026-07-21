with open("scratch.gd", "r") as f:
    lines = f.readlines()

# The missing lines are from 692 to 995 (0-indexed 691 to 994)
missing_lines = lines[691:995]

with open("scripts/LessonSaoTruc.gd", "r") as f:
    target_lines = f.readlines()

# In scripts/LessonSaoTruc.gd, line 697 is:
# 697: 	
# 698: 	elif target_note_key == "sao_truc_level4_7":

# Let's find the exact index in target_lines to insert.
insert_idx = -1
for i, line in enumerate(target_lines):
    if 'elif target_note_key == "sao_truc_level4_7":' in line:
        insert_idx = i
        break

if insert_idx != -1:
    # Insert missing_lines at insert_idx
    new_lines = target_lines[:insert_idx] + missing_lines + target_lines[insert_idx:]
    with open("scripts/LessonSaoTruc.gd", "w") as f:
        f.writelines(new_lines)
    print("Fixed!")
else:
    print("Could not find insertion point!")
