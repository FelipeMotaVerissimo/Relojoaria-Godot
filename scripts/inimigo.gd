extends CharacterBody2D

signal morreu(posicao: Vector2)  # o spawner escuta: conta o abate e pode soltar uma lata

enum State { CHASE, HURT, DEAD }
var state: State = State.CHASE

# os numeros que diferenciam um inimigo do outro ficam no Inspetor, nao no codigo
@export var vida_maxima: int = 2
@export var velocidade: float = 45.0
@export var dano: int = 1
@export var tempo_hurt: float = 0.2
@export var empurrao: float = 120.0  # inimigos pesados usam um valor menor

var vida: int
var tempo_no_hurt := 0.0

# para contornar obstaculos fixos (mesas, cadeiras) em vez de empurrar de frente
var desvio := Vector2.ZERO
var tempo_desvio := 0.0
var lado_preferido := 1.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_contato: Area2D = $AreaContato


func _ready() -> void:
	vida = vida_maxima
	lado_preferido = 1.0 if randf() < 0.5 else -1.0  # cada inimigo contorna por um lado
	go_to_chase()


func alvo() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	match state:
		State.CHASE:
			state_chase(delta)
		State.HURT:
			state_hurt(delta)
		State.DEAD:
			pass

	move_and_slide()


func levar_dano(quantidade: int, origem := Vector2.ZERO) -> void:
	if state == State.HURT or state == State.DEAD:
		return

	vida -= quantidade
	if vida <= 0:
		go_to_dead()
		return

	go_to_hurt(origem)
	return


# ---------------- CHASE ----------------

func go_to_chase() -> void:
	state = State.CHASE
	anim.modulate = Color.WHITE
	anim.play("girar")
	return


func state_chase(delta: float) -> void:
	var p := alvo()
	if p == null:
		velocity = Vector2.ZERO
		return

	var dir := global_position.direction_to(p.global_position)
	velocity = contornar_obstaculos(dir, delta) * velocidade

	# dano de contato: a invulnerabilidade do jogador impede que ele leve dano a cada quadro
	for corpo in area_contato.get_overlapping_bodies():
		if corpo.is_in_group("player") and corpo.has_method("levar_dano"):
			corpo.levar_dano(dano, global_position)


# Se o inimigo bate de frente num obstaculo fixo, move_and_slide cancela o movimento e ele
# fica empurrando sem sair do lugar. Aqui ele passa a andar pela lateral por um instante.
func contornar_obstaculos(dir: Vector2, delta: float) -> Vector2:
	if tempo_desvio > 0.0:
		tempo_desvio -= delta
		return (desvio + dir * 0.35).normalized()

	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is CharacterBody2D:
			continue  # outro inimigo ou o jogador: nao e obstaculo fixo

		var n := c.get_normal()
		if dir.dot(n) < -0.6:  # indo de frente contra o obstaculo
			var tangente := Vector2(-n.y, n.x)
			var lado := tangente.dot(dir)
			if absf(lado) < 0.2:
				tangente *= lado_preferido  # de frente total: escolhe um lado
			elif lado < 0.0:
				tangente = -tangente
			desvio = tangente
			tempo_desvio = 0.5
			return (desvio + dir * 0.35).normalized()

	return dir


# ---------------- HURT ----------------

func go_to_hurt(origem: Vector2) -> void:
	state = State.HURT
	tempo_no_hurt = 0.0
	anim.modulate = Color(1, 0.5, 0.5)

	var dir := Vector2.ZERO
	if origem != Vector2.ZERO:
		dir = (global_position - origem).normalized()
	velocity = dir * empurrao
	return


func state_hurt(delta: float) -> void:
	tempo_no_hurt += delta
	velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	if tempo_no_hurt >= tempo_hurt:
		go_to_chase()
		return


# ---------------- DEAD ----------------

func go_to_dead() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	anim.modulate = Color.WHITE
	# desligar colisor/area durante a fisica trava a Godot: use set_deferred
	area_contato.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	set_physics_process(false)
	morreu.emit(global_position)
	anim.play("explodir")
	await anim.animation_finished
	queue_free()
