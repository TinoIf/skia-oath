extends CanvasLayer

@onready var hp_bar = $HUD_Container/VBoxContainer/HBoxContainer2/HpBar
@onready var energy_bar = $HUD_Container/VBoxContainer/HBoxContainer/EnergyBar
@onready var hp_label = $HUD_Container/VBoxContainer/HBoxContainer2/Label
@onready var energy_label = $HUD_Container/VBoxContainer/HBoxContainer/Label
# Asumsi kamu sudah menambah HBoxContainer3 untuk Orb sesuai instruksi sebelumnya
@onready var orb_label = $HUD_Container/VBoxContainer/HBoxContainer3/OrbLabel 

func _ready() -> void:
	# Hubungkan ke GameManager (Bukan ke Player langsung)
	GameManager.hp_updated.connect(_update_hp_bar)
	GameManager.energy_updated.connect(_update_energy_bar)
	GameManager.orb_updated.connect(_update_orb_label)
	
	# Set nilai awal dari data yang ada di GameManager
	_update_orb_label(GameManager.orb_count)
	if GameManager.player:
		_update_hp_bar(GameManager.player.current_hp)
		_update_energy_bar(GameManager.player.current_energy)

func _update_hp_bar(new_value):
	hp_bar.value = new_value
	hp_label.text = "HP: " + str(int(new_value)) + " / 100"

func _update_energy_bar(new_value):
	energy_bar.value = new_value
	energy_label.text = "ENERGY : " + str(int(new_value))

func _update_orb_label(new_amount):
	orb_label.text = "ORBS: " + str(new_amount)
