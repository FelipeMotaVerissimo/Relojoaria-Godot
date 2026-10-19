extends CharacterBody2D
# ALVO DE TESTE -- apague a cena e este script quando os inimigos de verdade existirem.

func levar_dano(quantidade: int) -> void:
	print("acertei! dano: ", quantidade)
	modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.15).timeout
	modulate = Color.WHITE
