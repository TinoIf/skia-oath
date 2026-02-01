extends Node

var is_game_over : bool = false

func register_player(player_node):
	player_node.hp_change.connect(on_player_hp_changed)
	player_node.energy_change.connect(on_player_energy_changed)
	
func on_player_hp_changed(new_hp):
	if new_hp <= 0:
		trigger_game_over()

func on_player_energy_changed(new_energy):
	pass

func trigger_game_over():
	if is_game_over == false:
		is_game_over = true
		print("game over")
		
		## Next nya ntar mulai ulang game atau mulai dari menu
	
