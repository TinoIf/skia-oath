extends CanvasLayer

# Hubungkan node Label ke variabel
@onready var hp_label = $MarginContainer/VBoxContainer/HP_Label
@onready var energy_label = $MarginContainer/VBoxContainer/Energy_Label

# Variabel untuk menampung node player
var player

func _ready():
	# Cara 1: Menunggu player siap (Cara paling aman)
	# Kita tunggu sampai node "Player" ada di scene tree
	player = await get_tree().root.get_node("/root/WorldLv1/Player").ready 
	
	# Cara 2: Jika Player di-load instan (Cara lebih simpel)
	# player = get_node("/root/Level/Player") # Ganti "Level/Player" dengan path
	
	# Setelah player ditemukan, hubungkan sinyalnya ke fungsi di script UI ini
	player.hp_updated.connect(_on_player_hp_updated)
	player.energy_updated.connect(_on_player_energy_updated)
	
	# Set nilai awal UI saat game dimulai
	_on_player_hp_updated(player.current_hp)
	_on_player_energy_updated(player.current_energy, player.MAX_ENERGY)


# Fungsi ini akan dipanggil SETIAP KALI sinyal "hp_updated" diterima
func _on_player_hp_updated(new_hp):
	hp_label.text = "HP: " + str(new_hp)

# Fungsi ini akan dipanggil SETIAP KALI sinyal "energy_updated" diterima
func _on_player_energy_updated(new_energy, max_energy):
	energy_label.text = "Energi: " + str(new_energy) + " / " + str(max_energy)
