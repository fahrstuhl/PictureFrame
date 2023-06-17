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
var is_dragging := false
var is_default_path : bool

func _ready():
	get_tree().get_root().connect("size_changed", self, "_on_window_size_changed")
	disable_content_inputs()
	load_config()

func disable_content_inputs():
	$content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in $content.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event):
	if event.is_action("toggle_settings") and event.is_action_pressed("toggle_settings"):
		$"%settings".visible = not $"%settings".visible
	if event is InputEventPanGesture:
		debug_print("detected pan gesture")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		debug_print("unhandled click")
	handle_menu_toggle(event)

func handle_menu_toggle(event):
	if event is InputEventMouseButton and event.is_pressed():
		send_menu_toggle()

func send_menu_toggle():
	var action = InputEventAction.new()
	action.action = "toggle_settings"
	action.pressed = true
	Input.parse_input_event(action)

func load_config():
	CONFIG = ConfigFile.new()
	var err = CONFIG.load(CONFIG_PATH)
	if err != OK:
		debug_print("Config not found, using default values")
		is_default_path = true
		$"%settings".show()
	else:
		is_default_path = false
		$"%settings".hide()
	set_image_path(CONFIG.get_value("DEFAULT", "image_path", OS.get_user_data_dir()))
	set_image_fill(CONFIG.get_value("DEFAULT", "image_fill", 0))

func set_image_path(value):
	debug_print("Setting path to {0}".format([value]))
	PATH = value
	$"%image_path".PATH = PATH
	set_setting("image_path", PATH)
	find_images()

func set_image_fill(index):
	IMAGE_FILL = index
	match IMAGE_FILL:
		ImageFillModes.ZOOM: $"%image/image".stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		ImageFillModes.BARS: $"%image/image".stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ImageFillModes.BLUR: pass
	$"%image_fill".OPTION = IMAGE_FILL
	set_setting("image_fill", IMAGE_FILL)

func set_setting(key: String, value):
	CONFIG.set_value("DEFAULT", key, value)
	CONFIG.save(CONFIG_PATH)

func find_images():
	debug_print("Finding images")
	IMAGES = find_files_with_extensions(PATH, ["jpg", "jpeg"])
	if len(IMAGES) == 0:
		debug_print("Couldn't find any images, adding icon.png.")
		IMAGES.append("res://icon.png")
	image = Image.new()
	c_texture = ImageTexture.new()
	image.load(IMAGES[0])
	next_picture()

func next_picture():
	c_texture.create_from_image(image)
	var c_name : String = IMAGES[current]
	debug_print("Current image {0} with index {1}".format([c_name, current]))
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
	var dialog : FileDialog = $"%image_path/grid/FileDialog"
	if is_default_path and OS.get_name() == "Android":
		dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	debug_print("Current dir: {0}".format([dialog.current_dir]))
	debug_print("Data dir: {0}".format([OS.get_data_dir()]))
	debug_print("User data dir: {0}".format([OS.get_user_data_dir()]))
	for dir in [OS.SYSTEM_DIR_DESKTOP, OS.SYSTEM_DIR_DCIM, OS.SYSTEM_DIR_DOCUMENTS, OS.SYSTEM_DIR_PICTURES]:
		debug_print("System dir {0}: {1}".format([dir, OS.get_system_dir(dir, false)]))
		debug_print("System dir {0}: {1}".format([dir, OS.get_system_dir(dir, true)]))
	dialog.show()

func _on_image_path_dir_selected(dir):
	is_default_path = false
	set_image_path(dir)

func _on_image_fill_item_selected(index):
	set_image_fill(index)

func _on_window_size_changed():
	rect_size = OS.window_size
	debug_print("resized to {0}".format([OS.window_size]))

func _on_PictureFrame_gui_input(event):
	handle_menu_toggle(event)

func debug_print(text):
	print(text)
	var old = $"%debug".text
	var new = "{0}\n{1}".format([text, old])
	$"%debug".text = new

func _on_image_fill_setting_changed(value):
	set_image_fill(value)
