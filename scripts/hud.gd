extends CanvasLayer

@onready var label: Label = $HBoxContainer/Label


func atualizar_abates(abates: int, meta: int) -> void:
	label.text = "%d / %d" % [abates, meta]
