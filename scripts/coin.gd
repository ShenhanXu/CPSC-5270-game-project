extends Area2D

export var score_value = 1  
var collect_shader_material = null

func _ready():
	# 加载shader材质
	collect_shader_material = preload("res://materials/coin_collect_material.tres")

func _on_coin_body_entered(body):
	if body.has_method("add_score"):  
		body.add_score(score_value)
		# 应用简单的shader效果
		apply_simple_collect_effect()

func apply_simple_collect_effect():
	# 应用shader材质
	var shader_instance = collect_shader_material.duplicate()
	$AnimatedSprite.material = shader_instance
	
	# 创建Tween来控制动画
	var tween = Tween.new()
	add_child(tween)
	
	# 只用shader溶解效果 + 轻微缩放
	tween.interpolate_method(self, "_update_shader_progress", 0.0, 1.0, 0.4, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	
	# 轻微缩放效果
	tween.interpolate_property($AnimatedSprite, "scale", Vector2(1.0, 1.0), Vector2(1.2, 1.2), 0.4, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	
	# 动画完成后删除节点
	tween.connect("tween_all_completed", self, "_on_collect_animation_finished")
	tween.start()
	
	# 播放音效
	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.play()

func _update_shader_progress(progress):
	# 更新shader的进度参数
	if $AnimatedSprite.material:
		$AnimatedSprite.material.set_shader_param("progress", progress)

func _on_collect_animation_finished():
	# 动画完成后删除金币
	queue_free()
