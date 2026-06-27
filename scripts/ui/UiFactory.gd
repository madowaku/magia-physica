extends RefCounted
class_name UiFactory

var root: Control
var panel_color: Color
var border_color: Color

func _init(root_control: Control, default_panel_color: Color, accent_color: Color) -> void:
	root = root_control
	panel_color = default_panel_color
	border_color = accent_color

func full_rect(node: Control) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0

func set_box(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom

func add_background(path: String, darken: float = 0.22) -> void:
	var tex_rect := TextureRect.new()
	full_rect(tex_rect)
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(path):
		tex_rect.texture = load(path)
	root.add_child(tex_rect)
	if darken > 0.0:
		var overlay := ColorRect.new()
		full_rect(overlay)
		overlay.color = Color(0.0, 0.0, 0.0, darken)
		root.add_child(overlay)

func make_panel(bg: Color = Color(0.02, 0.035, 0.035, 0.84), border: bool = true) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border_color
	if border:
		style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func add_label(parent: Node, text: String, font_size: int = 22, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func add_label_nowrap(parent: Node, text: String, font_size: int = 22, color: Color = Color.WHITE, min_width: float = 0.0) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if min_width > 0.0:
		label.custom_minimum_size = Vector2(min_width, 0)
	parent.add_child(label)
	return label

func add_button(parent: Node, text: String, callback: Callable, min_size: Vector2 = Vector2(220, 52)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	var font_size := 22
	if min_size.y <= 32:
		font_size = 15
	elif min_size.y <= 40:
		font_size = 17
	elif min_size.y <= 46:
		font_size = 19
	button.add_theme_font_size_override("font_size", font_size)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func add_texture(parent: Node, path: String, min_size: Vector2 = Vector2(120, 120), stretch: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.custom_minimum_size = min_size
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = stretch
	if ResourceLoader.exists(path):
		texture_rect.texture = load(path)
	parent.add_child(texture_rect)
	return texture_rect
