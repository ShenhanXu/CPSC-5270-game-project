
extends Node2D

onready var UI_Root = $"UIRoot"
onready var player = $Player  # 假设Player是World的直接子节点
onready var tween = $Tween  # 添加Tween节点引用
onready var camera = $Player/Camera2D  # 添加摄像机引用

# Called when the node enters the scene tree for the first time.
func _ready():
	# 连接Player的update_score信号到UI的update_ui方法
	player.connect("update_score", UI_Root, "update_ui")
	
	# 开场动画
	play_intro_animation()
	
	pass # Replace with function body.

# 简单的开场动画函数
func play_intro_animation():
	# 初始设置（玩家和UI初始透明）
	player.modulate.a = 0
	# UI_Root.modulate.a = 0
	
	# 设置摄像机初始缩放
	camera.zoom = Vector2(2.0, 2.0)  # 开始时摄像机缩小（视野更广）
	
	# 禁用玩家输入
	player.set_input_enabled(false)
	
	# 创建淡入动画
	tween.interpolate_property(player, "modulate:a", 0, 1, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
	# tween.interpolate_property(UI_Root, "modulate:a", 0, 1, 1.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	# 添加摄像机缩放动画（从远到近的推进效果）
	tween.interpolate_property(camera, "zoom", Vector2(2.0, 2.0), Vector2(1.0, 1.0), 2.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	
	# 连接动画完成信号
	tween.connect("tween_all_completed", self, "_on_intro_animation_completed")
	tween.start()

# 动画完成后的回调函数
func _on_intro_animation_completed():
	# 启用玩家输入
	player.set_input_enabled(true)
	# 断开信号连接，避免重复调用
	tween.disconnect("tween_all_completed", self, "_on_intro_animation_completed")


func _on_Area2D_body_entered(body):
	if body.name == "Player":
		get_tree().change_scene("res://scenes/BossLevel.tscn")
