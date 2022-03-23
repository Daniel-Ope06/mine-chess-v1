extends Node2D

var is_paused = false setget set_is_paused

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		self.is_paused = not(is_paused)

func set_is_paused(value):
	is_paused = value
	get_tree().paused = is_paused
	visible = is_paused

func _on_ResumeBtn_pressed() -> void:
	self.is_paused = false

func _on_QuitBtn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene("res://UI/MainMenu.tscn")
