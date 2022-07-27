extends Node2D

var is_paused = false setget set_is_paused

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		self.is_paused = not(is_paused)

func set_is_paused(value: bool):
	is_paused = value
	get_tree().paused = is_paused
	visible = is_paused

# Buttons
func _on_ResumeBtn_pressed() -> void:
	$AudioStreamPlayer.play()
	self.is_paused = false

func _on_HomeBtn_pressed() -> void:
	$AudioStreamPlayer.play()
	yield(get_tree().create_timer(0.2), "timeout")
	get_tree().paused = false
	get_tree().change_scene("res://UI/MainMenu.tscn")
