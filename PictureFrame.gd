extends Container

export var PATH: String = "res://"
var IMAGES := []
var current: int = 0
var next: int = 0
var c_texture: Texture
var n_texture: Texture

func _ready():
	print("Finding images")
	IMAGES = find_files_with_extensions(PATH, ["jpg", "jpeg"])
	if len(IMAGES) == 0:
		print("Couldn't find any images, adding icon.png.")
		IMAGES.append("res://icon.png")
	next_picture()

func next_picture():
	current = next
	next = (next + 1)%len(IMAGES)
	c_texture = n_texture
	n_texture = load(IMAGES[next])
	var c_name : String = IMAGES[current]
	if c_name.get_file().begins_with("panorama"):
		$panorama/panorama/WorldEnvironment.environment.background_sky.panorama = c_texture
		$image.hide()
		$video.hide()
		$panorama.show()
	else:
		$image.texture = c_texture
		$video.hide()
		$panorama.hide()
		$image.show()

static func find_files_with_extensions(path, extensions):
	var dir = Directory.new()
	var images = []
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var filename = dir.get_next()
		while filename != "":
			print(filename)
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
