class_name RegionBanner
extends CanvasLayer
## Region entry card: a washi scroll unrolls at the top of the screen with the
## region's crest, name and subtitle in the region's accent colour, holds for a
## moment and rolls back up. Small (never covers the play area's centre).
##   RegionBanner.show_on(self, "Vila Fantasma", "Onde os mortos acendem lanternas", Color("5fc4e8"), 1)

var title := ""
var sub := ""
var accent := UiTheme.LACQUER
var crest := 0          # index into fx/glyphs.png (0 ring, 1 hexagram, 2 sakura, 3 crescent, 4 wave, 5 flame)
var hold := 2.6
var _c: _Draw
var _k := 0.0           # unroll amount 0..1
var _t := 0.0


static func show_on(parent: Node, t: String, s: String, col: Color, crest_i := 0, hold_s := 2.6) -> RegionBanner:
	var b := RegionBanner.new()
	b.title = t
	b.sub = s
	b.accent = col
	b.crest = crest_i
	b.hold = hold_s
	parent.add_child(b)
	return b


func _ready() -> void:
	add_to_group("region_banner")     # the HUD tucks the objective away meanwhile
	layer = 55
	_c = _Draw.new()
	_c.banner = self
	_c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_c)
	AudioDirector.play_sfx("region_enter")
	var tw := create_tween()
	tw.tween_property(self, "_k", 1.0, 0.55).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(self, "_k", 0.0, 0.45).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	_c.queue_redraw()


class _Draw:
	extends Control
	var banner: RegionBanner
	var _glyphs: Texture2D = load("res://assets/sprites/generated/fx/glyphs.png")

	func _draw() -> void:
		var b := banner
		if b._k <= 0.0:
			return
		var f := UiTheme.font()
		var fs := UiTheme.font_small()
		var tw := f.get_string_size(b.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var sw := fs.get_string_size(b.sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var w := maxf(tw, sw) + 64.0
		var full_h := 46.0
		var h := roundf(full_h * b._k)
		var x := roundf(320.0 - w / 2.0)
		var y := 10.0
		# rollers
		draw_rect(Rect2(x - 6, y - 3, w + 12, 5), UiTheme.WOOD)
		draw_rect(Rect2(x - 8, y - 2, 3, 3), UiTheme.GOLD)
		draw_rect(Rect2(x + w + 5, y - 2, 3, 3), UiTheme.GOLD)
		# paper
		draw_rect(Rect2(x, y + 2, w, h), UiTheme.PAPER)
		draw_rect(Rect2(x, y + 2, 3, h), b.accent)
		draw_rect(Rect2(x + w - 3, y + 2, 3, h), b.accent)
		if b._k > 0.75:
			var a := clampf((b._k - 0.75) / 0.25, 0.0, 1.0)
			# crest
			if _glyphs:
				draw_texture_rect_region(_glyphs, Rect2(x + 10, y + 13, 16, 16), Rect2(b.crest * 16, 0, 16, 16), Color(b.accent, a))
			draw_string(f, Vector2(x + 34, y + 22), b.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(UiTheme.INK, a))
			draw_string(fs, Vector2(x + 34, y + 37), b.sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(b.accent.darkened(0.25), a))
			# a thin accent line that sweeps under the title
			var k := clampf(b._t * 1.6 - 0.4, 0.0, 1.0)
			draw_rect(Rect2(x + 34, y + 26, (w - 44) * k, 1), Color(b.accent, a))
		draw_rect(Rect2(x - 6, y + 2 + h, w + 12, 5), UiTheme.WOOD)
		draw_rect(Rect2(x - 8, y + 3 + h, 3, 3), UiTheme.GOLD)
		draw_rect(Rect2(x + w + 5, y + 3 + h, 3, 3), UiTheme.GOLD)
