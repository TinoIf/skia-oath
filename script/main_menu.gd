extends Control

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/world.tscn")


func _on_keluar_pressed() -> void:
	get_tree().quit()
