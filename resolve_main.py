import re

def resolve_main_menu():
    with open("scripts/MainMenu.gd", "r", encoding="utf-8") as f:
        content = f.read()
    
    # Conflict 1: Roadmap text setup
    conflict1 = re.search(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> origin/datFix', content, re.DOTALL)
    if conflict1:
        head_text = conflict1.group(1)
        dat_text = conflict1.group(2)
        # We want to keep dat_text for dan_tranh, and head_text for trong_chau
        # head_text has the `elif instrument == "trong_chau":` block
        # dat_text has the `basic_title.text = "LEVEL 1...` for dan_tranh
        
        trong_chau_block = head_text[head_text.find('\telif instrument == "trong_chau":'):]
        resolved1 = dat_text + "\n" + trong_chau_block
        content = content[:conflict1.start()] + resolved1 + content[conflict1.end():]
        
    # Conflict 2: Card basic click
    conflict2 = re.search(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> origin/datFix', content, re.DOTALL)
    if conflict2:
        head_text = conflict2.group(1)
        dat_text = conflict2.group(2)
        resolved2 = head_text + "\n" + dat_text.replace('\t\t\telif inst == "sao_truc":', '\t\t\telif inst == "sao_truc":')
        # Wait, head_text is `elif inst == "trong_chau": ...`
        # dat_text is `elif inst == "sao_truc": ...`
        resolved2 = head_text + "\n" + dat_text
        content = content[:conflict2.start()] + resolved2 + content[conflict2.end():]

    # Conflict 3: Card ess click
    conflict3 = re.search(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> origin/datFix', content, re.DOTALL)
    if conflict3:
        head_text = conflict3.group(1)
        dat_text = conflict3.group(2)
        resolved3 = head_text + "\n" + dat_text
        content = content[:conflict3.start()] + resolved3 + content[conflict3.end():]
        
    # Conflict 4: Play soloist click
    conflict4 = re.search(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> origin/datFix', content, re.DOTALL)
    if conflict4:
        head_text = conflict4.group(1)
        dat_text = conflict4.group(2)
        resolved4 = head_text + "\n" + dat_text
        content = content[:conflict4.start()] + resolved4 + content[conflict4.end():]

    with open("scripts/MainMenu.gd", "w", encoding="utf-8") as f:
        f.write(content)
        
resolve_main_menu()
print("Resolved MainMenu.gd")
