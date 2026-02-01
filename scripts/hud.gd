extends CanvasLayer

@onready var hp_bar = $HUD_Container/VBoxContainer/HBoxContainer2/HpBar
@onready var energy_bar = $HUD_Container/VBoxContainer/HBoxContainer/EnergyBar
@onready var hp_label = $HUD_Container/VBoxContainer/HBoxContainer2/Label
@onready var energy_label = $HUD_Container/VBoxContainer/HBoxContainer/Label


func _ready() -> void:
	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		player.hp_change.connect(_update_hp_bar)
		player.energy_change.connect(_update_energy_bar)
		
		_update_hp_bar(player.current_hp)
		_update_energy_bar(player.current_energy)

func _update_hp_bar(new_value):
	hp_bar.value = new_value
	hp_label.text = "HP: " + str(int(new_value)) + " / 100"

func _update_energy_bar(new_value):
	energy_bar.value = new_value
	#Next coba pelajari Tween buat efek getar dan transisi mulus
	#var tween = create_tween()
	#tween.tween_property(energy_bar, "value", new_value, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	energy_label.text = "ENERGY  : " + str(int(new_value))
