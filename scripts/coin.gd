extends Area2D

export var score_value = 1  

func _on_coin_body_entered(body):
	if body.has_method("add_score"):  
		body.add_score(score_value)  
	$AnimationPlayer.play("picked")
