extends CharacterBody2D

signal vida_mudou(vida: int, maxima: int)
signal morreu

enum State { IDLE, RUN, ATTACK, HURT, DEAD }
var state: State = State.IDLE

const SPEED = 80.0

# posicao da area do golpe para cada direcao (a origem do jogador esta nos pes)
const GOLPE_POS = {
	"right": Vector2(22, -16),
	"left": Vector2(-22, -16),
	"down": Vector2(0, 8),
	"up": Vector2(0, -36),
}

@export var vida_maxima: int = 10
@export var tempo_hurt: float = 0.3          # tempo "atordoado": sem controle
@export var tempo_invulneravel: float = 1.0  # tempo total sem levar dano (maior que o atordoamento)
@export var dano_do_golpe: int = 1
@export var quadro_do_golpe: int = 2

var vida: int
var tempo_no_hurt := 0.0
var invulneravel := 0.0
var facing := "down"  # down, up, left, right
var golpe_aplicado := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_golpe: Area2D = $AreaGolpe


func _ready() -> void:
	vida = vida_maxima
	vida_mudou.emit(vida, vida_maxima)
	go_to_idle()


func _physics_process(delta: float) -> void:
	atualizar_invulnerabilidade(delta)

	match state:
		State.IDLE:
			state_idle(delta)
		State.RUN:
			state_run(delta)
		State.ATTACK:
			state_attack(delta)
		State.HURT:
			state_hurt(delta)
		State.DEAD:
			pass

	move_and_slide()


# enquanto invulneravel, o personagem pisca; ao acabar, volta ao normal
func atualizar_invulnerabilidade(delta: float) -> void:
	if invulneravel > 0.0:
		invulneravel -= delta
		anim.modulate.a = 0.4 if int(invulneravel * 12.0) % 2 == 0 else 1.0
	elif anim.modulate.a != 1.0:
		anim.modulate.a = 1.0


func read_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing = "right" if dir.x > 0 else "left"
	else:
		facing = "down" if dir.y > 0 else "up"


# quem chama e o inimigo; "origem" e a posicao dele (para empurrar o jogador)
func levar_dano(quantidade: int, origem := Vector2.ZERO) -> void:
	# o atordoamento (HURT) acaba antes da invulnerabilidade: o jogador volta a ter
	# controle mas ainda nao leva dano, senao ele fica preso apanhando em sequencia
	if state == State.DEAD or invulneravel > 0.0:
		return

	vida -= quantidade
	print("vida: ", vida)  # TEMPORARIO -- apague quando tiver o HUD
	vida_mudou.emit(vida, vida_maxima)
	if vida <= 0:
		go_to_dead()
		return

	go_to_hurt(origem)
	return


# ---------------- IDLE ----------------

func go_to_idle() -> void:
	state = State.IDLE
	velocity = Vector2.ZERO
	anim.modulate = Color.WHITE
	anim.play("idle_" + facing)
	return


func state_idle(_delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		go_to_attack()
		return

	if read_direction() != Vector2.ZERO:
		go_to_run()
		return


# ---------------- RUN ----------------

func go_to_run() -> void:
	state = State.RUN
	update_facing(read_direction())
	anim.play("run_" + facing)
	return


func state_run(_delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		go_to_attack()
		return

	var dir := read_direction()
	if dir == Vector2.ZERO:
		go_to_idle()
		return

	update_facing(dir)
	velocity = dir * SPEED
	anim.play("run_" + facing)


# ---------------- ATTACK ----------------

func go_to_attack() -> void:
	state = State.ATTACK
	velocity = Vector2.ZERO
	golpe_aplicado = false
	area_golpe.position = GOLPE_POS[facing]
	area_golpe.monitoring = true
	anim.play("attack1_" + facing)
	return


func state_attack(_delta: float) -> void:
	# o dano sai NUM quadro da animacao (o da espada estendida), nao durante o estado todo
	if not golpe_aplicado and anim.frame >= quadro_do_golpe:
		golpe_aplicado = true
		for corpo in area_golpe.get_overlapping_bodies():
			if corpo != self and corpo.has_method("levar_dano"):
				corpo.levar_dano(dano_do_golpe, global_position)

	# o estado termina quando a animacao acaba (por isso ela nao pode estar em loop)
	if not anim.is_playing():
		area_golpe.monitoring = false
		go_to_idle()
		return


# ---------------- HURT ----------------
# sai sozinho pelo tempo (atordoamento); a invulnerabilidade dura mais que ele

func go_to_hurt(origem: Vector2) -> void:
	state = State.HURT
	tempo_no_hurt = 0.0
	invulneravel = max(tempo_invulneravel, tempo_hurt)
	area_golpe.monitoring = false  # se apanhou no meio do golpe, desliga a area
	anim.modulate = Color(1, 0.4, 0.4)
	anim.play("idle_" + facing)

	var dir := Vector2.ZERO
	if origem != Vector2.ZERO:
		dir = (global_position - origem).normalized()
	velocity = dir * 130.0
	return


func state_hurt(delta: float) -> void:
	tempo_no_hurt += delta
	velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	if tempo_no_hurt >= tempo_hurt:
		go_to_idle()
		return


# ---------------- DEAD ----------------
# estado sem saida: nao existe animacao de morte no pacote, entao ele some em fade

func go_to_dead() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	area_golpe.monitoring = false
	anim.modulate = Color(1, 0.4, 0.4)
	anim.play("idle_" + facing)
	set_physics_process(false)
	morreu.emit()

	var t := create_tween()
	t.tween_property(anim, "modulate:a", 0.0, 0.8)
	return
