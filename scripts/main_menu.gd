extends Node2D

func _on_btn_play_pressed() -> void:
	# This command switches the current scene to your game file.
	# MAKE SURE THE PATH IS CORRECT!
	get_tree().change_scene_to_file("res://scenes/Main.tscn")