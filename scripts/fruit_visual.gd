extends Node2D
## Draws a fruit once; the parent RigidBody2D rotation turns it.
var tier := 0

func _draw() -> void:
	FruitArt.draw_fruit(self, tier, FruitArt.RADII[tier])
