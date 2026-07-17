extends SceneTree

func _init():
    var btn = Button.new()
    print("Has icon_placement: ", "icon_alignment" in btn)
    print("Has vertical_icon_alignment: ", "vertical_icon_alignment" in btn)
    print("Has icon_alignment: ", "icon_alignment" in btn)
    print("Has icon: ", "icon" in btn)
    quit()
