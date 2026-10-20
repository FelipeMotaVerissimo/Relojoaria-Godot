extends Node2D

@onready var spawner = $Spawner
@onready var hud = $HUD

var terminou := false


func _ready() -> void:
	var jogador = get_tree().get_first_node_in_group("player")

	# abates: o spawner avisa, o HUD so escreve o texto
	spawner.abates_mudou.connect(hud.atualizar_abates)
	hud.atualizar_abates(spawner.abates, spawner.meta_de_abates)
	spawner.meta_atingida.connect(_on_meta_atingida)

	# vida: o jogador avisa, o HUD so desenha os coracoes
	jogador.vida_mudou.connect(hud.atualizar_vida)
	jogador.morreu.connect(_on_jogador_morreu)
	hud.atualizar_vida(jogador.vida, jogador.vida_maxima)


func _on_meta_atingida() -> void:
	if terminou:
		return
	terminou = true
	await get_tree().create_timer(0.8).timeout  # deixa a ultima explosao terminar
	terminar(true)


func _on_jogador_morreu() -> void:
	if terminou:
		return
	terminou = true
	await get_tree().create_timer(1.0).timeout  # deixa o fade da morte terminar
	terminar(false)


func terminar(vitoria: bool) -> void:
	hud.mostrar_fim(vitoria, spawner.abates, spawner.meta_de_abates)
	get_tree().paused = true
