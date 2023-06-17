extends Control

export var PATH: String setget set_image_path
enum ImageFillModes {ZOOM, BARS, BLUR}
enum ImageType {FLAT, PANORAMA, VR180}
export(ImageFillModes) var IMAGE_FILL: int setget set_image_fill
var CONFIG : ConfigFile
var CONFIG_PATH = "user://config.ini"
var IMAGES := []
var current: int = 0
var c_texture: Texture
var image: Image
var is_dragging := false
var is_default_path : bool
var WAIT_TIME_INDEX: int = 3 # 10s
var selectable_wait_times = [
	1, 2, 5, 10, 20, 30, 45, 60,
	1.5*60, 2*60, 2.5*60, 3*60, 4*60, 5*60,
	10*60, 15*60, 20*60, 30*60, 45*60, 1*3600,
	1.5*3600, 2*3600, 2.5*3600, 3*3600, 4*3600, 5*3600,
	6*3600, 12*3600, 24*3600
]

func _ready():
	fill_wait_time_options()
	get_tree().get_root().connect("size_changed", self, "_on_window_size_changed")
	disable_content_inputs()
	load_config()

func fill_wait_time_options():
	var fuzzy_times = []
	for time in selectable_wait_times:
		fuzzy_times.append(fuzzy_time_format(time))
	$"%wait_time".OPTIONS = fuzzy_times

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
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
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
		$"%settings".show()
	else:
		$"%settings".hide()
	var default_path
	if OS.get_name() == "Android":
		default_path = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	else:
		default_path = OS.get_user_data_dir()
	set_image_path(CONFIG.get_value("DEFAULT", "image_path", default_path))
	set_image_fill(CONFIG.get_value("DEFAULT", "image_fill", 0))
	set_wait_time(CONFIG.get_value("DEFAULT", "wait_time_index", 3))

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

func set_wait_time(index):
	WAIT_TIME_INDEX = index
	var wait_time = selectable_wait_times[WAIT_TIME_INDEX]
	debug_print("Setting wait time to {0}".format([fuzzy_time_format(wait_time)]))
	$"%timer".wait_time = wait_time
	$"%timer".start()
	$"%wait_time".OPTION = WAIT_TIME_INDEX
	set_setting("wait_time_index", WAIT_TIME_INDEX)

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
	var image_type = get_image_type(c_name)
	match image_type:
		ImageType.PANORAMA:
			$"%panorama/panorama/WorldEnvironment".environment.background_sky.panorama = c_texture
			$"%image".hide()
			$"%panorama/panorama/Camera".rotation_degrees.y = 0
			$"%panorama".show()
		ImageType.FLAT:
			$"%image/image".texture = c_texture
			$"%panorama".hide()
			$"%image".show()
		ImageType.VR180:
			$"%panorama/panorama/WorldEnvironment".environment.background_sky.panorama = c_texture
			$"%image".hide()
			$"%panorama".show()
			$"%panorama/panorama/Camera".rotation_degrees.y = 90
	current = (current + 1)%len(IMAGES)
	image.load(IMAGES[current])

func get_image_type(n: String):
	n = n.trim_prefix(PATH)
	var parts = n.split("/")
	var panorama_checks = ["panorama", "vr360"]
	var vr180_checks = ["vr180"]
	if any_begins_with_list(parts, panorama_checks):
		return ImageType.PANORAMA
	if any_begins_with_list(parts, vr180_checks):
		return ImageType.VR180
	return ImageType.FLAT

static func any_begins_with_list(string_list, check_list):
	for string in string_list:
		for to_check in check_list:
			if string.to_lower().begins_with(to_check):
				return true
	return false

static func fuzzy_time_format(time: int):
	var seconds = (time%60)
	var minutes = (time%3600)/60
	var hours = time/3600
	if time < 60:
		return "{0}s".format([seconds])
	if time < 600 and seconds != 0:
		return "{0}m {1}s".format([minutes, seconds])
	if time < 3600:
		return "{0}m".format([minutes])
	if time < 10800 and minutes !=0:
		return "{0}h {1}m".format([hours, minutes])
	return "{0}h".format([hours])

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

func _on_wait_time_setting_changed(value):
	set_wait_time(value)

func _on_setting_setting_changed(value):
	$"%debug_container".visible = value
