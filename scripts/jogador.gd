extends CharacterBody2D

enum State { IDLE, RUN, ATTACK }
var state: State = State.IDLE

const SPEED = 80.0

# posicao da area do golpe para cada direcao (a origem do jogador esta nos pes)
const GOLPE_POS = {
	"right": Vector2(22, -16),
	"left": Vector2(-22, -16),
	"down": Vector2(0, 8),
	"up": Vector2(0, -36),
}

@export var dano_do_golpe: int = 1
@export var quadro_do_golpe: int = 2

var facing := "down"  # down, up, left, right
var golpe_aplicado := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_golpe: Area2D = $AreaGolpe


func _ready() -> void:
	go_to_idle()


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			state_idle(delta)
		State.RUN:
			state_run(delta)
		State.ATTACK:
			state_attack(delta)

	move_and_slide()


func read_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing = "right" if dir.x > 0 else "left"
	else:
		facing = "down" if dir.y > 0 else "up"


# ---------------- IDLE ----------------

func go_to_idle() -> void:
	state = State.IDLE
	velocity = Vector2.ZERO
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
				corpo.levar_dano(dano_do_golpe)

	# o estado termina quando a animacao acaba (por isso ela nao pode estar em loop)
	if not anim.is_playing():
		area_golpe.monitoring = false
		go_to_idle()
		return
