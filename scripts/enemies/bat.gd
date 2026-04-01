extends CharacterBody2D

const SPEED = 80.0
const ATTACK_DAMAGE = 10
const DETECTION_RANGE = 200.0
const ATTACK_RANGE = 40.0
const MAX_HEALTH = 30
const ATTACK_COOLDOWN_TIME = 0.5
var knockback_velocity = Vector2.ZERO

var attack_cooldown = 0.0
var health = MAX_HEALTH
var is_dead = false
var is_hurt = false
var is_attacking = false
var is_awake = false
var has_dealt_damage = false
var player = null

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	# Aplicar daño solo en frame 5, una vez por ataque
	if is_attacking and not has_dealt_damage and animated_sprite.frame >= 5:
		has_dealt_damage = true
		var direction = (player.global_position - global_position).normalized()
		player.take_damage(ATTACK_DAMAGE, direction)
	
	if knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 20.0)
		move_and_slide()

	if is_dead or is_hurt or is_attacking:
		_update_animation()
		return

	if player == null:
		_update_animation()
		return

	if attack_cooldown > 0:
		attack_cooldown -= delta

	var distance = global_position.distance_to(player.global_position)

	if not is_awake:
		if distance <= DETECTION_RANGE:
			if animated_sprite.animation != "wakeup":
				animated_sprite.play("wakeup")
		else:
			animated_sprite.play("sleep")
		return

	if distance <= ATTACK_RANGE and attack_cooldown <= 0:
		is_attacking = true
		attack_cooldown = ATTACK_COOLDOWN_TIME
	elif distance <= DETECTION_RANGE:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * SPEED
		animated_sprite.flip_h = velocity.x > 0
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	_update_animation()

func _update_animation():
	if is_dead:
		return
	if is_hurt:
		animated_sprite.play("hurt")
		return
	if is_attacking:
		if animated_sprite.animation != "attack":
			animated_sprite.play("attack")
		return
	if not is_awake:
		animated_sprite.play("sleep")
		return
	var distance = 999.0
	if player:
		distance = global_position.distance_to(player.global_position)
	if distance <= ATTACK_RANGE:
		animated_sprite.play("attack")
	elif distance <= DETECTION_RANGE:
		animated_sprite.play("chase")
	else:
		animated_sprite.play("idle")

func _on_animation_finished():
	if is_hurt:
		is_hurt = false
	if is_attacking:
		is_attacking = false
		has_dealt_damage = false
	if is_dead:
		queue_free()
	if animated_sprite.animation == "wakeup":
		is_awake = true

func take_damage(amount, knockback_direction = Vector2.ZERO):
	if is_dead or is_hurt:
		return
	health -= amount
	knockback_velocity = knockback_direction * 200.0
	if health <= 0:
		health = 0
		is_dead = true
		animated_sprite.play("die")
	else:
		is_hurt = true
