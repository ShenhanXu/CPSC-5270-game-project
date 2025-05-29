extends CanvasLayer

onready var coin_num = $CoinNum


func _ready():
	pass 


func update_ui(new_score):
	coin_num.text = str(new_score)
