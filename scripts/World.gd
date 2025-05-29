extends Node2D

onready var UI_Root = $"UIRoot"
onready var player = $Player  
onready var tween = $Tween  
onready var camera = $Player/Camera2D  

func _ready():

	player.connect("update_score", UI_Root, "update_ui")
	

	play_intro_animation()
	
	pass 


func play_intro_animation():

	player.modulate.a = 0

	

	camera.zoom = Vector2(2.0, 2.0)  
	

	player.set_input_enabled(false)
	

	tween.interpolate_property(player, "modulate:a", 0, 1, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN)

	tween.interpolate_property(camera, "zoom", Vector2(2.0, 2.0), Vector2(1.0, 1.0), 2.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	

	tween.connect("tween_all_completed", self, "_on_intro_animation_completed")
	tween.start()


func _on_intro_animation_completed():

	player.set_input_enabled(true)

	tween.disconnect("tween_all_completed", self, "_on_intro_animation_completed")


func _on_Area2D_body_entered(body):
	if body.name == "Player":
		get_tree().change_scene("res://scenes/win.tscn")
