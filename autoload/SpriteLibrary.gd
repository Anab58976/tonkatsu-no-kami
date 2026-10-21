extends Node
## Builds SpriteFrames from sprite folders described by anims.json:
##   {"cell_w": 64, "cell_h": 64, "origin": [32, 60],
##    "animations": {"idle": {"file": "idle.png", "frames": 4, "fps": 6, "loop": true}}}
##
## Lookup order (artist art always wins over generated art):
##   1. res://assets/sprites/characters/<id>/anims.json   (official sprites)
##   2. res://assets/sprites/generated/<id>/anims.json    (pipeline output)

const OFFICIAL := "res://assets/sprites/characters/%s/"
const GENERATED := "res://assets/sprites/generated/%s/"

var _cache: Dictionary = {}


func folder_for(id: String) -> String:
	if FileAccess.file_exists((OFFICIAL % id) + "anims.json"):
		return OFFICIAL % id
	return GENERATED % id


func is_official(id: String) -> bool:
	return FileAccess.file_exists((OFFICIAL % id) + "anims.json")


func meta(id: String) -> Dictionary:
	var p := folder_for(id) + "anims.json"
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		push_error("SpriteLibrary: missing %s" % p)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func frames(id: String) -> SpriteFrames:
	if _cache.has(id):
		return _cache[id]
	var m := meta(id)
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	if m.is_empty():
		return sf
	var cw := int(m["cell_w"])
	var ch := int(m["cell_h"])
	var dir := folder_for(id)
	for anim_name in m["animations"]:
		var a: Dictionary = m["animations"][anim_name]
		var tex: Texture2D = load(dir + String(a["file"]))
		if tex == null:
			push_error("SpriteLibrary: cannot load %s%s" % [dir, a["file"]])
			continue
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, float(a.get("fps", 8)))
		sf.set_animation_loop(anim_name, bool(a.get("loop", true)))
		for i in int(a["frames"]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * cw, 0, cw, ch)
			sf.add_frame(anim_name, at)
	_cache[id] = sf
	return sf


## Offset to apply to a centred AnimatedSprite2D so its node position is the feet.
func origin_offset(id: String) -> Vector2:
	var m := meta(id)
	if m.is_empty():
		return Vector2.ZERO
	return Vector2(m["cell_w"] / 2.0 - m["origin"][0], m["cell_h"] / 2.0 - m["origin"][1])


func make_sprite(id: String, anim := "") -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = frames(id)
	s.centered = true
	s.offset = origin_offset(id)
	if anim != "" and s.sprite_frames.has_animation(anim):
		s.play(anim)
	return s
