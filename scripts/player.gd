extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 500.0
const DASH_DURATION = 0.2

@onready var animated_sprite = $AnimatedSprite2D

var is_dashing = false
var dash_timer = 0.0
var dash_direction = 1.0

func _physics_process(delta):
	# Gravedad
	if not is_on_floor() and not is_dashing:
		velocity += get_gravity() * delta

	# Dash
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction * DASH_SPEED
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = 0

	if not is_dashing:
		# Salto
		if Input.is_action_just_pressed("saltar") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Movimiento horizontal
		var direction = Input.get_axis("mover_izquierda", "mover_derecha")
		if direction != 0:
			velocity.x = direction * SPEED
			animated_sprite.flip_h = direction < 0
			dash_direction = direction
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# Iniciar dash
		if Input.is_action_just_pressed("dash"):
			is_dashing = true
			dash_timer = DASH_DURATION

	# Animaciones
	_update_animation()

	move_and_slide()

func _update_animation():
	if is_dashing:
		animated_sprite.play("dash")
	elif not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
	elif Input.is_action_pressed("atacar"):
		animated_sprite.play("attack")
	elif Input.is_action_pressed("agacharse"):
		animated_sprite.play("crouch")
	elif Input.get_axis("mover_izquierda", "mover_derecha") != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")
