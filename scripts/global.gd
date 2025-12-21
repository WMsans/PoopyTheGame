extends Node



func _input(event):
	if event.is_action_pressed("refresh"):
		get_tree().reload_current_scene()
	
	if event.is_action_pressed("esc"):
		get_tree().quit()
