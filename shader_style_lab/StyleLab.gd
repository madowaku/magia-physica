extends Node3D
## Shader Style Lab M0.1: isolated, dependency-free Godot 4.6 prototype.
## Open res://shader_style_lab/StyleLab.tscn and press F6.

const STYLE_SHADER = preload("res://shader_style_lab/style_lab.gdshader")
var display_material: ShaderMaterial
var current_style := 1
var style_label: Label
var turntable: Node3D

func _ready() -> void:
    _build_stage()
    _build_ui()
    _apply_style()

func _process(delta: float) -> void:
    turntable.rotate_y(delta * 0.32)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_SPACE:
            current_style = (current_style + 1) % 3
            _apply_style()

func _build_stage() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#eaf1ff")
    environment.environment = env
    add_child(environment)

    var camera := Camera3D.new()
    camera.position = Vector3(3.4, 2.3, 5.6)
    camera.look_at_from_position(camera.position, Vector3(0, 0.35, 0))
    camera.current = true
    add_child(camera)

    turntable = Node3D.new()
    add_child(turntable)
    display_material = ShaderMaterial.new()
    display_material.shader = STYLE_SHADER

    var body := MeshInstance3D.new()
    var body_mesh := SphereMesh.new()
    body_mesh.radius = 0.95
    body_mesh.height = 1.9
    body.mesh = body_mesh
    body.material_override = display_material
    turntable.add_child(body)

    var hat := MeshInstance3D.new()
    var hat_mesh := CylinderMesh.new()
    hat_mesh.top_radius = 0.05
    hat_mesh.bottom_radius = 0.9
    hat_mesh.height = 1.5
    hat.mesh = hat_mesh
    hat.mesh.surface_set_material(0, display_material)
    hat.position.y = 1.5
    turntable.add_child(hat)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(24, 24)
    panel.custom_minimum_size = Vector2(340, 0)
    layer.add_child(panel)
    var stack := VBoxContainer.new()
    panel.add_child(stack)
    var header := Label.new()
    header.text = "MGSF Shader Style Lab M0.1"
    stack.add_child(header)
    style_label = Label.new()
    stack.add_child(style_label)
    var switch_button := Button.new()
    switch_button.text = "Switch style (Space)"
    switch_button.pressed.connect(_next_style)
    stack.add_child(switch_button)
    _add_slider(stack, "Light bands", 2, 8, 3, "bands")
    _add_slider(stack, "Ink strength", 0, 1, 0.75, "outline_strength")
    _add_slider(stack, "Ink threshold", 0, 1, 0.23, "outline_threshold")
    var note := Label.new()
    note.text = "Demo geometry only. Import GLB to apply this ShaderMaterial."
    stack.add_child(note)

func _add_slider(stack: VBoxContainer, title: String, low: float, high: float, initial: float, parameter: String) -> void:
    var caption := Label.new()
    caption.text = title
    stack.add_child(caption)
    var slider := HSlider.new()
    slider.min_value = low
    slider.max_value = high
    slider.step = 0.01 if high <= 1.0 else 1.0
    slider.value = initial
    slider.value_changed.connect(func(value: float) -> void:
        display_material.set_shader_parameter(parameter, value)
    )
    stack.add_child(slider)

func _next_style() -> void:
    current_style = (current_style + 1) % 3
    _apply_style()

func _apply_style() -> void:
    display_material.set_shader_parameter("style_mode", current_style)
    var labels := ["Smooth shaded", "Toon ink", "Quantized toon"]
    style_label.text = "Style: " + labels[current_style]
