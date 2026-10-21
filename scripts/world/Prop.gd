class_name Prop
extends Node2D
## A static world object from props.json, anchored at its base (y-sorted).
## Adds a StaticBody2D footprint when the prop is solid.

const PROPS_DIR := "res://assets/sprites/props/"
## Buildings are solid over most of their picture, not only at the doorstep:
## in this 3/4 view the wall and roof stand on the ground behind the base line,
## so a base-only footprint let Lulu walk "into" the facade and over the roof.
## The top of the roof (1 - BUILDING_DEPTH) stays open so she can still pass
## just behind a roof edge (the see-through fade shows her there).
const BUILDINGS := ["house_day", "shop_day", "house_small", "house_tall", "house_tree", "hall_red", "shrine_stairs"]
const BUILDING_DEPTH := 0.8
static var _db: Dictionary = {}

var prop_name := ""
var sprite: Sprite2D


static func db() -> Dictionary:
	if _db.is_empty():
		var f := FileAccess.open(PROPS_DIR + "props.json", FileAccess.READ)
		_db = JSON.parse_string(f.get_as_text())
	return _db


static func info(name: String) -> Dictionary:
	return db().get(name, {})


static func make(name: String, pos: Vector2, flip := false, solid_override := -1) -> Prop:
	var p := Prop.new()
	p.prop_name = name
	p.position = pos.round()
	var d := info(name)
	if d.is_empty():
		push_error("Prop: unknown '%s'" % name)
		return p
	p.sprite = Sprite2D.new()
	p.sprite.texture = load(PROPS_DIR + String(d["file"]))
	p.sprite.centered = false
	p.sprite.offset = Vector2(-int(d["w"]) / 2, -int(d["h"]))
	p.sprite.flip_h = flip
	p.add_child(p.sprite)
	var solid: bool = d["solid"] if solid_override < 0 else solid_override == 1
	if solid and d["fp"][0] > 0:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		var depth := body_depth(name)
		r.size = Vector2(d["fp"][0], depth)
		cs.shape = r
		cs.position = Vector2(0, -depth / 2.0)
		body.add_child(cs)
		p.add_child(body)
	return p


static func is_building(name: String) -> bool:
	for b in BUILDINGS:
		if name.ends_with(b):
			return true
	return false


## Height (pixels, up from the base) of the solid part of a prop.
static func body_depth(name: String) -> float:
	var d := info(name)
	if d.is_empty():
		return 0.0
	var fp_h := float(d["fp"][1])
	if is_building(name):
		return maxf(fp_h, roundf(float(d["h"]) * BUILDING_DEPTH))
	return fp_h


func size() -> Vector2:
	var d := info(prop_name)
	return Vector2(d.get("w", 0), d.get("h", 0))


## Swaps to another prop's image (same anchor rules), e.g. a bell swinging.
func set_texture_name(name: String) -> void:
	var d := info(name)
	if d.is_empty() or sprite == null:
		return
	sprite.texture = load(PROPS_DIR + String(d["file"]))
	sprite.offset = Vector2(-int(d["w"]) / 2, -int(d["h"]))
