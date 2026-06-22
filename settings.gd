extends Control

enum ACTIONS {Forward, Backward, Left, Right, SpecialAction, Jump}

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

var is_customisable: bool = false
var action_string: String = ""

func _ready() -> void:
	for tab_button: Button in menu_tabs.get_children():
		tab_button.toggled.connect(_settings_tab.bind(tab_button))
		if tab_button.is_pressed():
			_settings_tab(true, tab_button)
	
	for rebind_key_button in rebind_key_button_list:
		rebind_key_button.pressed.connect(_on_toggle_action_button_pressed.bind(rebind_key_button))
	_update_keys()

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
				SignalBus.back_pressed.emit()
				menu_tabs.get_child(0).set_pressed(true)
# change keybinds
func _input(event: InputEvent) -> void:
	if event is InputEventKey and is_customisable:
		if event.is_pressed():
			_change_action_key(event)
			is_customisable = false

func _change_action_key(new_key: InputEventKey):
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
