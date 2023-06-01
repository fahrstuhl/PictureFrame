extends Control

export var PATH: String setget set_image_path
enum ImageFillModes {ZOOM, BARS, BLUR}
export(ImageFillModes) var IMAGE_FILL: int setget set_image_fill
var CONFIG : ConfigFile
var CONFIG_PATH = "user://config.ini"
var IMAGES := []
var current: int = 0
var c_texture: Texture
var image: Image

func _ready():
	load_config()

func _input(event):
	if event.is_action("toggle_settings") and event.is_action_pressed("toggle_settings"):
		$"%settings".visible = not $"%settings".visible

func load_config():
	CONFIG = ConfigFile.new()
	var err = CONFIG.load(CONFIG_PATH)
	if err != OK:
		print("Config not found, using default values")
		$"%settings".show()
	else:
		$"%settings".hide()
	set_image_path(CONFIG.get_value("DEFAULT", "image_path", "user://"))
	set_image_fill(CONFIG.get_value("DEFAULT", "image_fill", 0))

func set_image_path(value):
	print("Setting path to ", value)
	PATH = value
	$"%image_path/grid/value".text = PATH
	set_setting("image_path", PATH)
	find_images()

func set_image_fill(index):
	IMAGE_FILL = index
	match IMAGE_FILL:
		ImageFillModes.ZOOM: $"%image/image".stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		ImageFillModes.BARS: $"%image/image".stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ImageFillModes.BLUR: pass
	set_setting("image_fill", IMAGE_FILL)

func set_setting(key: String, value):
	CONFIG.set_value("DEFAULT", key, value)
	CONFIG.save(CONFIG_PATH)

func find_images():
	print("Finding images")
	IMAGES = find_files_with_extensions(PATH, ["jpg", "jpeg"])
	if len(IMAGES) == 0:
		print("Couldn't find any images, adding icon.png.")
		IMAGES.append("res://icon.png")
	image = Image.new()
	c_texture = ImageTexture.new()
	image.load(IMAGES[0])
	next_picture()

func next_picture():
	c_texture.create_from_image(image)
	var c_name : String = IMAGES[current]
	print("Current image {0} with index {1}".format([c_name, current]))
	if c_name.get_file().begins_with("panorama"):
		$"%panorama/panorama/WorldEnvironment".environment.background_sky.panorama = c_texture
		$"%image".hide()
		$"%video".hide()
		$"%panorama".show()
	else:
		$"%image/image".texture = c_texture
		$"%video".hide()
		$"%panorama".hide()
		$"%image".show()
	current = (current + 1)%len(IMAGES)
	image.load(IMAGES[current])

static func find_files_with_extensions(path, extensions):
	var dir = Directory.new()
	var images = []
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var filename = dir.get_next()
		while filename != "":
#			print(filename)
			if dir.current_is_dir():
				var recurse_dir = path.plus_file(filename)
				images.append_array(find_files_with_extensions(recurse_dir, extensions))
#				print("Ignoring dir '{0}'".format([recurse_dir]))
			else:
				if filename.get_extension() in extensions:
					var image_path = path.plus_file(filename)
					images.append(image_path)
			filename = dir.get_next()
		return images
	else:
		print("Can't open directory '{0}'".format([path]))
		return []

func _on_Timer_timeout():
	next_picture()

func _on_image_path_button_pressed():
	$"%image_path/grid/FileDialog".show()

func _on_image_path_dir_selected(dir):
	set_image_path(dir)

func _on_image_fill_item_selected(index):
	set_image_fill(index)
