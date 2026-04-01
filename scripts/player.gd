extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 500.0
const DASH_DURATION = 0.2

@onready var animated_sprite = $AnimatedSprite2D
@onready var hud = get_parent().get_node("HUD")

var is_dashing = false
var dash_timer = 0.0
var dash_direction = 1.0
var is_attacking = false
var max_health = 100
var health = 100
var is_dead = false
var is_hurt = false
var has_dealt_damage = false
var knockback_velocity = Vector2.ZERO

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	if is_attacking:
		is_attacking = false
		has_dealt_damage = false
	if is_hurt:
		is_hurt = false
	if is_dead:
		queue_free()

func _physics_process(delta):
	
	# Aplicar knockback
	if knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 25.0)
	
	if is_dead:
		return
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
	
	# Prueba de Daño
	if Input.is_key_pressed(KEY_T):
		take_damage(10)

	# Movimiento siempre disponible
	if not is_dashing:
		var direction = Input.get_axis("mover_izquierda", "mover_derecha")
		if direction != 0:
			velocity.x = direction * SPEED
			animated_sprite.flip_h = direction < 0
			dash_direction = direction
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# Salto
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Dash
	if Input.is_action_just_pressed("dash") and not is_dashing:
		is_dashing = true
		dash_timer = DASH_DURATION

	# Ataque
	if Input.is_action_just_pressed("atacar") and not is_attacking:
		is_attacking = true
	
	# Aplicar daño al enemigo en frame 2 del ataque
	if is_attacking and not has_dealt_damage and animated_sprite.frame >= 2:
		has_dealt_damage = true
		var enemies = get_tree().get_nodes_in_group("enemy")
		for enemy in enemies:
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= 60.0:
				var direction = (enemy.global_position - global_position).normalized()
				enemy.take_damage(20, direction)

	_update_animation()
	move_and_slide()

func _update_animation():
	if is_dead or is_hurt:
		return
	if is_dashing:
		animated_sprite.play("dash")
		return
	# Movimiento siempre disponible
	if not is_dashing:
		var direction = Input.get_axis("mover_izquierda", "mover_derecha")
		if direction != 0:
			velocity.x = direction * SPEED
			animated_sprite.flip_h = direction < 0
			dash_direction = direction
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	if is_attacking:
		if animated_sprite.animation != "attack":
			animated_sprite.play("attack")
		return
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
	elif Input.is_action_pressed("agacharse"):
		var direction = Input.get_axis("mover_izquierda", "mover_derecha")
		if direction != 0:
			animated_sprite.play("crouchwalk")
		else:
			animated_sprite.play("crouch")
	elif Input.get_axis("mover_izquierda", "mover_derecha") != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")
	
func take_damage(amount, knockback_direction = Vector2.ZERO):
	if is_dead or is_hurt:
		return
	health -= amount
	knockback_velocity = knockback_direction * 300.0
	if health <= 0:
		health = 0
		die()
	else:
		is_hurt = true
		animated_sprite.play("hit")
	
	hud.update_health(health, max_health)

func die():
	is_dead = true
	velocity = Vector2.ZERO
	animated_sprite.play("death")
