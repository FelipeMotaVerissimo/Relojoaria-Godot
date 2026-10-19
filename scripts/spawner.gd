extends Node

signal abates_mudou(abates: int, meta: int)
signal meta_atingida

@export var cena_inimigo: PackedScene
@export var meta_de_abates: int = 50
@export var max_vivos: int = 8
@export var intervalo: float = 1.5
@export var distancia_minima: float = 110.0
# area (em pixels, dentro das paredes) onde os inimigos podem nascer: Position x,y e Size largura,altura
@export var limites := Rect2(24, 40, 592, 128)

var abates := 0
var vivos := 0
var tempo := 0.0


func _physics_process(delta: float) -> void:
	if abates >= meta_de_abates:
		return

	tempo += delta
	if tempo >= intervalo:
		tempo = 0.0
		tentar_spawn()


func tentar_spawn() -> void:
	# nunca cria mais inimigos do que os que ainda faltam para a meta
	if vivos >= max_vivos or abates + vivos >= meta_de_abates:
		return

	var p := get_tree().get_first_node_in_group("player")
	if p == null or cena_inimigo == null:
		return

	# sorteia uma posicao e tenta de novo (ate 10 vezes) se cair perto demais do jogador
	var pos := Vector2.ZERO
	for i in 10:
		pos = Vector2(
			randf_range(limites.position.x, limites.end.x),
			randf_range(limites.position.y, limites.end.y)
		)
		if pos.distance_to(p.global_position) >= distancia_minima:
			break

	var inimigo := cena_inimigo.instantiate()
	get_parent().add_child(inimigo)
	inimigo.global_position = pos
	inimigo.morreu.connect(_on_inimigo_morreu)
	vivos += 1


func _on_inimigo_morreu() -> void:
	vivos -= 1
	abates += 1
	abates_mudou.emit(abates, meta_de_abates)
	if abates >= meta_de_abates:
		meta_atingida.emit()
