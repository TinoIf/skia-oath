extends Control

func _on_play_pressed() -> void:
	GlobalState.last_checkpoint_position = Vector2.ZERO
	GlobalState.current_fire = 0
	get_tree().change_scene_to_file("res://scene/world.tscn")


func _on_keluar_pressed() -> void:
	get_tree().quit()
