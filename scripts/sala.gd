extends Node2D

@onready var spawner = $Spawner
@onready var hud = $HUD


func _ready() -> void:
	# o spawner avisa a cada abate; o HUD so sabe escrever o texto
	spawner.abates_mudou.connect(hud.atualizar_abates)
	hud.atualizar_abates(spawner.abates, spawner.meta_de_abates)

	# TEMPORARIO -- na proxima etapa isto vira a tela de vitoria
	spawner.meta_atingida.connect(func(): print("meta atingida!"))
