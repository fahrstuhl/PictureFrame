tool
extends Container

signal setting_changed

enum SettingType {BOOL, MENU, FILE}

export(String) var NAME = "Setting"
export(SettingType) var TYPE = SettingType.BOOL
export(Array, String) var OPTIONS
export(bool) var BOOL = false setget set_BOOL
export(String) var PATH = "" setget set_PATH
export(int) var OPTION = 0 setget set_OPTION

func _ready():
	$"%name".text = NAME
	match TYPE:
		SettingType.FILE:
			setup_file()
		SettingType.BOOL:
			setup_bool()
		SettingType.MENU:
			setup_menu()

func setup_bool():
	$"%check".show()
	$"%value".hide()
	set_BOOL(BOOL)

func set_BOOL(value):
	BOOL = value
	$"%check".pressed = BOOL

func setup_menu():
	$"%value".show()
	$"%check".hide()
	for item in OPTIONS:
		$"%menu".add_item(item)
	set_OPTION(OPTION)

func set_OPTION(value):
	OPTION = value
	$"%value".text = OPTIONS[OPTION]

func setup_file():
	$"%value".show()
	$"%check".hide()
	set_PATH(PATH)

func set_PATH(value):
	PATH = value
	$"%value".text = PATH

func _on_button_pressed():
	match TYPE:
		SettingType.FILE:
			$"%dialog".show()
		SettingType.BOOL:
			BOOL = not BOOL
			$"%check".pressed = BOOL
			emit_signal("setting_changed", BOOL)
		SettingType.MENU:
			$"%menu".rect_size.x = rect_size.x
			$"%menu".rect_position.x = rect_global_position.x
			$"%menu".rect_position.y = rect_global_position.y + rect_size.y/2
			$"%menu".show()

func _on_dialog_dir_selected(dir):
	PATH = dir
	$"%value".text = PATH
	emit_signal("setting_changed", PATH)

func _on_menu_index_pressed(index):
	if OPTION != index:
		OPTION = index
		emit_signal("setting_changed", OPTION)
	$"%value".text = OPTIONS[OPTION]
