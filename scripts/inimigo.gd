extends CharacterBody2D

signal morreu  # o contador de abates (proxima etapa) escuta este sinal

enum State { CHASE, HURT, DEAD }
var state: State = State.CHASE

# os numeros que diferenciam um inimigo do outro ficam no Inspetor, nao no codigo
@export var vida_maxima: int = 2
@export var velocidade: float = 45.0
@export var dano: int = 1
@export var tempo_hurt: float = 0.2

var vida: int
var tempo_no_hurt := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_contato: Area2D = $AreaContato


func _ready() -> void:
	vida = vida_maxima
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


func state_chase(_delta: float) -> void:
	var p := alvo()
	if p == null:
		velocity = Vector2.ZERO
		return

	velocity = global_position.direction_to(p.global_position) * velocidade

	# dano de contato: a invulnerabilidade do jogador impede que ele leve dano a cada quadro
	for corpo in area_contato.get_overlapping_bodies():
		if corpo.is_in_group("player") and corpo.has_method("levar_dano"):
			corpo.levar_dano(dano, global_position)


# ---------------- HURT ----------------

func go_to_hurt(origem: Vector2) -> void:
	state = State.HURT
	tempo_no_hurt = 0.0
	anim.modulate = Color(1, 0.5, 0.5)

	var dir := Vector2.ZERO
	if origem != Vector2.ZERO:
		dir = (global_position - origem).normalized()
	velocity = dir * 120.0
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
	morreu.emit()
	anim.play("explodir")
	await anim.animation_finished
	queue_free()
