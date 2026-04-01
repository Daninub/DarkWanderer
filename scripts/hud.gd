extends CanvasLayer

@onready var health_bar = $HealthBar

func update_health(current, maximum):
	health_bar.max_value = maximum
	health_bar.value = current
