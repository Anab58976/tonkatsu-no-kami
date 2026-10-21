class_name InteriorLayer
extends Node2D
## Draws interior walls for every VOID tile of a GroundLayer: a front-facing
## wall face (plaster, wood beams, shoji panels) where a floor tile lies below,
## and a dark roof/top elsewhere. Floors use the ground textures (tinted).

var ground: GroundLayer
var wall_color := Color("e6d3b0")
var beam_color := Color("5c3a28")
var top_color := Color("2a1a14")
var shoji := true


func _draw() -> void:
	var T := GroundLayer.TILE
	for y in ground.h:
		for x in ground.w:
			if ground.at(x, y) != GroundLayer.T.VOID:
				continue
			var p := Vector2(x, y) * T
			var below := ground.at(x, y + 1)
			if below != GroundLayer.T.VOID and below != GroundLayer.T.WATER and y + 1 < ground.h:
				# wall face
				draw_rect(Rect2(p, Vector2(T, T)), wall_color)
				draw_rect(Rect2(p, Vector2(T, 4)), beam_color)
				draw_rect(Rect2(p + Vector2(0, T - 5), Vector2(T, 5)), beam_color)
				draw_rect(Rect2(p + Vector2(0, 12), Vector2(T, 2)), beam_color.lightened(0.15))
				if x % 3 == 0:
					draw_rect(Rect2(p, Vector2(4, T)), beam_color)
				elif shoji and x % 3 == 1:
					draw_rect(Rect2(p + Vector2(6, 16), Vector2(20, 10)), Color("fbf3e2"))
					draw_rect(Rect2(p + Vector2(15, 16), Vector2(1, 10)), beam_color)
					draw_rect(Rect2(p + Vector2(6, 20), Vector2(20, 1)), beam_color)
			else:
				draw_rect(Rect2(p, Vector2(T, T)), top_color)
				# subtle edge where the top meets a floor at the sides
				for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]:
					var n := ground.at(x + d.x, y + d.y)
					if n != GroundLayer.T.VOID and n != -1 and n <= GroundLayer.T.WATER:
						match d:
							Vector2i(-1, 0):
								draw_rect(Rect2(p, Vector2(3, T)), beam_color)
							Vector2i(1, 0):
								draw_rect(Rect2(p + Vector2(T - 3, 0), Vector2(3, T)), beam_color)
							Vector2i(0, -1):
								draw_rect(Rect2(p, Vector2(T, 3)), beam_color)
