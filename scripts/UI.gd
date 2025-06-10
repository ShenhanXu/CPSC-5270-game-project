extends CanvasLayer

onready var coin_num = $CoinNum

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func update_ui(new_score):
	coin_num.text = str(new_score)
