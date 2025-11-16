extends CanvasLayer

# 1. Hubungkan node Label ke variabel
@onready var hp_label = $MarginContainer/VBoxContainer/HP_Label
@onready var energy_label = $MarginContainer/VBoxContainer/Energy_Label
@onready var api_label = $MarginContainer/VBoxContainer/Api_Label 

func _ready():
	# 2. Kita tidak perlu lagi mencari Player!
	# Kita langsung "berlangganan" ke Papan Pengumuman Global.
	
	GlobalSignal.hp_updated.connect(_on_player_hp_updated)
	GlobalSignal.energy_updated.connect(_on_player_energy_updated)
	GlobalSignal.fire_updated.connect(_on_player_fire_updated) # Langganan sinyal baru
	
	# 3. Kita tidak perlu 'await' atau 'get_node' lagi.
	# Nilai awal akan dikirim oleh Player saat _ready()-nya dipanggil.

# Fungsi ini akan dipanggil SETIAP KALI sinyal "hp_updated" diterima
func _on_player_hp_updated(new_hp):
	hp_label.text = "HP: " + str(new_hp)

# Fungsi ini akan dipanggil SETIAP KALI sinyal "energy_updated" diterima
func _on_player_energy_updated(new_energy, max_energy):
	energy_label.text = "Energi: " + str(new_energy) + " / " + str(max_energy)

# (FUNGSI BARU)
# Fungsi ini akan dipanggil SETIAP KALI sinyal "fire_updated" diterima
func _on_player_fire_updated(new_fire, max_fire):
	api_label.text = "Api: " + str(new_fire) + " / " + str(max_fire)
