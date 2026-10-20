extends CanvasLayer

const ICONE_CORACAO := preload("res://assets/ui/coracao.png")

@onready var label_abates: Label = $HBoxContainer/Label
@onready var vidas: HBoxContainer = $Vidas
@onready var tela_fim: ColorRect = $TelaFim
@onready var texto_fim: Label = $TelaFim/Texto

var pode_reiniciar := false


func _ready() -> void:
	# o HUD precisa continuar funcionando com o jogo pausado (para aceitar o "reiniciar")
	process_mode = Node.PROCESS_MODE_ALWAYS
	tela_fim.visible = false


func atualizar_abates(abates: int, meta: int) -> void:
	label_abates.text = "%d / %d" % [abates, meta]


func atualizar_vida(vida: int, maxima: int) -> void:
	# cria os coracoes na primeira chamada
	while vidas.get_child_count() < maxima:
		var c := TextureRect.new()
		c.texture = ICONE_CORACAO
		c.stretch_mode = TextureRect.STRETCH_KEEP
		c.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		vidas.add_child(c)

	# coracao perdido fica escuro
	for i in vidas.get_child_count():
		vidas.get_child(i).modulate = Color.WHITE if i < vida else Color(0.2, 0.2, 0.2, 0.8)


func mostrar_fim(vitoria: bool, abates: int, meta: int) -> void:
	if vitoria:
		texto_fim.text = "VOCÊ VENCEU!\n%d / %d abates\n\nEnter para jogar de novo" % [abates, meta]
	else:
		texto_fim.text = "FIM DE JOGO\n%d / %d abates\n\nEnter para tentar de novo" % [abates, meta]
	tela_fim.visible = true

	# pequena espera, para quem estava apertando ataque nao reiniciar sem querer
	await get_tree().create_timer(0.6).timeout
	pode_reiniciar = true


func _input(event: InputEvent) -> void:
	if pode_reiniciar and event.is_action_pressed("ui_accept"):
		get_tree().paused = false
		get_tree().reload_current_scene()
