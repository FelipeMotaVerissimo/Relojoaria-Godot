extends Area2D

@export var cura: int = 1
@export var duracao: float = 8.0  # some sozinha se ninguem pegar

var restante := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	restante = duracao


func _physics_process(delta: float) -> void:
	restante -= delta
	if restante <= 0.0:
		queue_free()
		return

	# nos 2 ultimos segundos, pisca para avisar que vai sumir
	if restante < 2.0:
		sprite.modulate.a = 0.4 if int(restante * 8.0) % 2 == 0 else 1.0

	for corpo in get_overlapping_bodies():
		# so pega se estiver machucado: nao desperdica a cura
		if corpo.is_in_group("player") and corpo.vida < corpo.vida_maxima:
			corpo.curar(cura)
			queue_free()
			return
