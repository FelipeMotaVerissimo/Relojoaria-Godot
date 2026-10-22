extends Node

signal abates_mudou(abates: int, meta: int)
signal meta_atingida

@export var cena_inimigo: PackedScene
@export var cena_titan: PackedScene
@export var cena_mola: PackedScene
@export var cena_lata: PackedScene
@export var meta_de_abates: int = 50

# a dificuldade sobe com o progresso (abates / meta): do valor inicial ao final
@export var max_vivos_inicial: int = 3
@export var max_vivos_final: int = 10
@export var intervalo_inicial: float = 2.0
@export var intervalo_final: float = 0.8

# inimigos especiais: so aparecem depois de alguns abates, e so de vez em quando
@export var abates_para_titan: int = 10
@export_range(0.0, 1.0) var chance_titan: float = 0.2
@export var abates_para_mola: int = 5
@export_range(0.0, 1.0) var chance_mola: float = 0.25

# chance de um inimigo morto soltar uma lata de oleo (so se o jogador estiver machucado)
@export_range(0.0, 1.0) var chance_lata: float = 0.15

@export var distancia_minima: float = 110.0
# area (em pixels, dentro das paredes) onde os inimigos podem nascer
@export var limites := Rect2(24, 40, 592, 128)

var abates := 0
var vivos := 0
var tempo := 0.0


func _physics_process(delta: float) -> void:
	if abates >= meta_de_abates:
		return

	tempo += delta
	if tempo >= intervalo_atual():
		tempo = 0.0
		tentar_spawn()


func progresso() -> float:
	return clampf(float(abates) / float(meta_de_abates), 0.0, 1.0)


func max_vivos_atual() -> int:
	return roundi(lerpf(max_vivos_inicial, max_vivos_final, progresso()))


func intervalo_atual() -> float:
	return lerpf(intervalo_inicial, intervalo_final, progresso())


func escolher_cena() -> PackedScene:
	var sorteio := randf()
	var limite := 0.0
	if cena_titan != null and abates >= abates_para_titan:
		limite += chance_titan
		if sorteio < limite:
			return cena_titan
	if cena_mola != null and abates >= abates_para_mola:
		limite += chance_mola
		if sorteio < limite:
			return cena_mola
	return cena_inimigo


func tentar_spawn() -> void:
	# nunca cria mais inimigos do que os que ainda faltam para a meta
	if vivos >= max_vivos_atual() or abates + vivos >= meta_de_abates:
		return

	var p := get_tree().get_first_node_in_group("player")
	var cena := escolher_cena()
	if p == null or cena == null:
		return

	# sorteia uma posicao; so vale se estiver longe do jogador E livre de paredes e moveis
	var pos := Vector2.ZERO
	var achou := false
	for i in 20:
		pos = Vector2(
			randf_range(limites.position.x, limites.end.x),
			randf_range(limites.position.y, limites.end.y)
		)
		if pos.distance_to(p.global_position) >= distancia_minima and posicao_livre(pos):
			achou = true
			break
	if not achou:
		return  # tenta de novo no proximo intervalo

	var inimigo := cena.instantiate()
	get_parent().add_child(inimigo)
	inimigo.global_position = pos
	inimigo.morreu.connect(_on_inimigo_morreu)
	vivos += 1


# pergunta a fisica se ha algo da camada "mundo" (paredes, moveis) naquele ponto
func posicao_livre(pos: Vector2) -> bool:
	var forma := CircleShape2D.new()
	forma.radius = 12.0
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, pos + Vector2(0, -6))  # centro do corpo, nao dos pes
	consulta.collision_mask = 1  # camada 1 = mundo
	var espaco = get_parent().get_world_2d().direct_space_state
	return espaco.intersect_shape(consulta, 1).is_empty()


func _on_inimigo_morreu(posicao: Vector2) -> void:
	vivos -= 1
	abates += 1
	abates_mudou.emit(abates, meta_de_abates)
	if abates >= meta_de_abates:
		meta_atingida.emit()
	soltar_lata(posicao)


func soltar_lata(posicao: Vector2) -> void:
	if cena_lata == null:
		return
	var p := get_tree().get_first_node_in_group("player")
	if p == null or p.vida >= p.vida_maxima:
		return
	if randf() >= chance_lata:
		return

	var lata := cena_lata.instantiate()
	lata.position = posicao
	get_parent().add_child.call_deferred(lata)
