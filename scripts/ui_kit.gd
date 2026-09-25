extends RefCounted
## Shared, small UI primitives. All sizes are in the 1152 × 648 design canvas.

const FONT = preload("res://assets/fonts/DejaVuSans.ttf")
const BOLD = preload("res://assets/fonts/DejaVuSans-Bold.ttf")
const MONO = preload("res://assets/fonts/DejaVuSansMono.ttf")
const TEXT = Color(0.90, 0.96, 0.91)
const MUTED = Color(0.59, 0.69, 0.64)
const LIME = Color(0.72, 0.98, 0.39)
const CYAN = Color(0.43, 0.88, 0.83)
const AMBER = Color(1.0, 0.76, 0.40)
const INK = Color(0.034, 0.073, 0.074)

static func box(fill: Color = Color(0.034, 0.073, 0.074, 0.94), edge: Color = Color(0.32, 0.48, 0.32, 0.8), radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(8)
	return style

static func panel(pos: Vector2, dimensions: Vector2, fill: Color = Color(0.034, 0.073, 0.074, 0.94)) -> Panel:
	var node := Panel.new()
	node.position = pos
	node.size = dimensions
	node.add_theme_stylebox_override("panel", box(fill))
	return node

static func label(text: String, pos: Vector2, dimensions: Vector2, font_size: int = 14, color: Color = TEXT, face: String = "sans") -> Label:
	var node := Label.new()
	node.text = text
	node.position = pos
	node.size = dimensions
	node.add_theme_font_override("font", MONO if face == "mono" else (BOLD if face == "bold" else FONT))
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	node.add_theme_constant_override("shadow_offset_x", 1)
	node.add_theme_constant_override("shadow_offset_y", 1)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

static func button(text: String, pos: Vector2, dimensions: Vector2, primary: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.position = pos
	node.size = dimensions
	node.focus_mode = Control.FOCUS_ALL
	node.add_theme_font_override("font", BOLD)
	node.add_theme_font_size_override("font_size", 13)
	node.add_theme_color_override("font_color", INK if primary else TEXT)
	node.add_theme_color_override("font_hover_color", INK)
	node.add_theme_color_override("font_disabled_color", MUTED)
	node.add_theme_stylebox_override("normal", box(LIME if primary else Color(0.07, 0.15, 0.13), LIME if primary else Color(0.32, 0.53, 0.39)))
	node.add_theme_stylebox_override("hover", box(Color(0.83, 1.0, 0.62), LIME))
	node.add_theme_stylebox_override("pressed", box(Color(0.53, 0.78, 0.32), LIME))
	node.add_theme_stylebox_override("disabled", box(Color(0.09, 0.13, 0.12), Color(0.20, 0.28, 0.24)))
	node.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, CYAN))
	return node

static func option(pos: Vector2, dimensions: Vector2) -> OptionButton:
	var node := OptionButton.new()
	node.position = pos
	node.size = dimensions
	node.add_theme_font_override("font", MONO)
	node.add_theme_font_size_override("font_size", 12)
	node.add_theme_color_override("font_color", TEXT)
	node.add_theme_stylebox_override("normal", box(Color(0.075, 0.14, 0.13), Color(0.25, 0.48, 0.34)))
	node.add_theme_stylebox_override("hover", box(Color(0.13, 0.23, 0.19), LIME))
	node.add_theme_stylebox_override("pressed", box(Color(0.13, 0.23, 0.19), LIME))
	return node

static func line(pos: Vector2, width: float, color: Color = Color(0.33, 0.52, 0.37, 0.75)) -> ColorRect:
	var node := ColorRect.new()
	node.color = color
	node.position = pos
	node.size = Vector2(width, 1)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
