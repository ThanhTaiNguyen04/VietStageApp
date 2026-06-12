@tool
extends SceneTree

func _init() -> void:
	var path := "res://assets/textures/icons8/course.png"
	var tex := load(path) as Texture2D
	if not tex:
		print("FAIL: Cannot load texture")
	else:
		print("SUCCESS: Loaded texture")
		print("Size: ", tex.get_size())
		print("Class: ", tex.get_class())
		var img := tex.get_image()
		if img:
			print("Image format: ", img.get_format())
			print("Pixel (0,0): ", img.get_pixel(0, 0))
			print("Pixel (48,48): ", img.get_pixel(48, 48))
		else:
			print("FAIL: Cannot get image")
	quit()
