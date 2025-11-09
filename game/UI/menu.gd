extends Control

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_scenes/dialogue_scene.tscn")
