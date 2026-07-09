extends Control

enum ACTIONS {Forward, Backward, Left, Right, SpecialAction, Jump, OpenMenu, UnlockMouse}

@export_category("Sub-Menus")
@export var graphic_settings: VBoxContainer
@export var audio_settings: VBoxContainer
@export var controls_settings: VBoxContainer

@export_category("Menu Tabs")
@export var menu_tabs: VBoxContainer
@export var menu_title: Label

@export_category("Rebinding Inputs")
@export var available_actions: VBoxContainer
@export var rebind_key_button_list: Array[Button]

@export_category("FPS-Related Options")
@export var vsync_toggle: CheckButton
@export var fps_limit_array: Array[String] = ["30 FPS", "60 FPS", "120 FPS", "240 FPS", "No Limit"]
@export var fps_limit_picker: OptionButton

@export_category("Window Options")
@export var window_mode_array: Array[String] = ["Windowed", "Maximized", "Fullscreen", "Exclusive Fullscreen"]
@export var window_mode_picker: OptionButton

var is_customisable: bool = false
var action_string: String = ""
var previous_menu

func _ready() -> void:
	for mode in window_mode_array:
		window_mode_picker.add_item(mode)
	for limit in fps_limit_array:
		fps_limit_picker.add_item(limit)
		
	window_mode_picker.item_selected.connect(_option_buttons.bind(window_mode_picker))
	fps_limit_picker.item_selected.connect(_option_buttons.bind(fps_limit_picker))
	vsync_toggle.toggled.connect(_check_button.bind(vsync_toggle))
	
	_sync_ui_to_current_settings()
	
	for tab_button: Button in menu_tabs.get_children():
		tab_button.toggled.connect(_settings_tab.bind(tab_button))
		if tab_button.is_pressed():
			_settings_tab(true, tab_button)
	
	for rebind_key_button in rebind_key_button_list:
		rebind_key_button.pressed.connect(_on_toggle_action_button_pressed.bind(rebind_key_button))
	_update_keys()

func _sync_ui_to_current_settings() -> void:
	var current_mode := DisplayServer.window_get_mode()
	var mode_string := "Windowed"
	
	match current_mode:
		DisplayServer.WINDOW_MODE_WINDOWED: mode_string = "Windowed"
		DisplayServer.WINDOW_MODE_MAXIMIZED: mode_string = "Maximized"
		DisplayServer.WINDOW_MODE_FULLSCREEN: mode_string = "Fullscreen"
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN: mode_string = "Exclusive Fullscreen"
		
	var mode_index := window_mode_array.find(mode_string)
	if mode_index != -1:
		window_mode_picker.select(mode_index)
		
	var vsync_mode := DisplayServer.window_get_vsync_mode()
	vsync_toggle.set_pressed_no_signal(vsync_mode != DisplayServer.VSYNC_DISABLED)

	var current_fps := Engine.max_fps
	var fps_string := "No Limit" if current_fps == 0 else str(current_fps) + " FPS"
	
	var fps_index := fps_limit_array.find(fps_string)
	if fps_index != -1:
		fps_limit_picker.select(fps_index)
	else:
		fps_limit_picker.select(fps_limit_array.find("No Limit"))

func _settings_tab(toggled_on: bool, button: Button):
	if toggled_on:
		graphic_settings.hide()
		audio_settings.hide()
		controls_settings.hide()
		
		match button.name:
			"graphic_tab":
				graphic_settings.show()
			"audio_tab":
				audio_settings.show()
			"controls_tab":
				controls_settings.show()
			_:
				if SceneTransition.previous_scene_path != "":
					SceneTransition.transition(true, SceneTransition.previous_scene_path)
				else:
					SignalBus.back_pressed.emit()
				menu_tabs.get_child(0).set_pressed(true)


#check button
func _check_button(toggled: bool, button: CheckButton):
	match button:
		vsync_toggle:
			if toggled:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

#option buttons
func _option_buttons(index: int, button: Button):
	match button:
		window_mode_picker:
			var chosen_mode: String = window_mode_array[index]
			match chosen_mode:
				"Windowed":
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				"Maximized":
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
				"Fullscreen":
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
				"Exclusive Fullscreen":
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		fps_limit_picker:
			var value_string: String = fps_limit_array[index]
			if value_string == "No Limit":
				Engine.max_fps = 0
			else:
				Engine.max_fps = value_string.to_int()

# change keybinds
func _input(event: InputEvent) -> void:
	if event is InputEvent and is_customisable:
		if event.is_pressed():
			_change_action_key(event)
			is_customisable = false

func _change_action_key(new_key: InputEvent):
	var action_events = InputMap.action_get_events(action_string)
	if not action_events.is_empty():
		InputMap.action_erase_event(action_string, action_events[0])
	
	for project_action_name in ACTIONS.keys():
		if InputMap.action_has_event(project_action_name, new_key):
			InputMap.action_erase_event(project_action_name, new_key)
			
	InputMap.action_add_event(action_string, new_key)
	_update_keys()

func _update_keys():
	for node_name in ACTIONS.keys(): 
		var input_button: Button = available_actions.get_node(node_name).get_child(0)
		input_button.set_pressed(false)
		
		var project_action_name = str(node_name)
		
		if InputMap.has_action(project_action_name):
			var events = InputMap.action_get_events(project_action_name)
			if not events.is_empty():
				var first_event = events[0]
				
				if first_event is InputEventKey:
					var clean_label = DisplayServer.keyboard_get_label_from_physical(first_event.physical_keycode)
					input_button.text = OS.get_keycode_string(clean_label)
				elif first_event is InputEventMouseButton:
					if first_event.button_index == MOUSE_BUTTON_LEFT:
						input_button.text = "LMB"
					elif first_event.button_index == MOUSE_BUTTON_RIGHT:
						input_button.text = "RMB"
				else:
					input_button.text = first_event.as_text()
			else:
				input_button.text = "No Key"

func _toggle_action_key(action_key_string: String):
	is_customisable = true
	action_string = action_key_string
	
	for node_name in ACTIONS.keys():
		if node_name != action_key_string:
			var input_button: Button = available_actions.get_node(node_name).get_child(0)
			input_button.set_pressed(false)

func _on_toggle_action_button_pressed(button: Button):
	var action_to_rebind = button.get_parent().name
	
	if ACTIONS.keys().has(action_to_rebind):
		_toggle_action_key(action_to_rebind)
