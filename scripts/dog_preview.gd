class_name DogPreview
extends Control
## Always-available local phenotype composition, entirely driven by GeneticsEngine.

var configuration: Dictionary = {}
var genetics := GeneticsEngine.new()

func set_configuration(new_configuration: Dictionary) -> void:
	configuration = new_configuration.duplicate(true)
	queue_redraw()

func _dominant(gene_id: String) -> bool:
	var genotype: String = str(configuration.get(gene_id, genetics.default_configuration().get(gene_id, "")))
	return genetics.dominant_expressed(gene_id, genotype)

func _visual(gene_id: String) -> String:
	var mapping: Dictionary = genetics.trait_for(gene_id).get("visual", {})
	return str(mapping.get("dominant" if _dominant(gene_id) else "recessive", ""))

func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _draw() -> void:
	var ratio: float = minf(size.x / 220.0, size.y / 170.0)
	var offset: Vector2 = (size - Vector2(220, 170) * ratio) * 0.5
	draw_set_transform(offset, 0.0, Vector2(ratio, ratio))
	var fur_visual: Dictionary = genetics.trait_for("fur_color").get("visual", {})
	var eye_visual: Dictionary = genetics.trait_for("eye_color").get("visual", {})
	var coat_key: String = "dominant" if _dominant("fur_color") else "recessive"
	var eye_key: String = "dominant" if _dominant("eye_color") else "recessive"
	var coat := Color(str(fur_visual.get(coat_key, "#875c41")))
	var shade: Color = coat.darkened(0.23)
	var highlight: Color = coat.lightened(0.16)
	var outline := Color("#1b2825")
	var eye := Color(str(eye_visual.get(eye_key, "#f5b454")))
	var long_coat: bool = _visual("fur_length") == "long"
	var tall_legs: bool = _visual("leg_structure") == "long"
	var leg_top: float = 112.0 if tall_legs else 125.0

	# Grounding shadow and simple pixel silhouette, drawn from back to front.
	draw_ellipse_shadow(Color(0.0, 0.0, 0.0, 0.35))
	if _visual("tail_type") == "long":
		_poly([Vector2(67, 83), Vector2(47, 75), Vector2(31, 54), Vector2(21, 57), Vector2(31, 84), Vector2(45, 98), Vector2(70, 100)], outline)
		_poly([Vector2(67, 87), Vector2(48, 81), Vector2(34, 64), Vector2(30, 65), Vector2(37, 82), Vector2(48, 93), Vector2(70, 96)], shade)
	else:
		_poly([Vector2(66, 83), Vector2(46, 81), Vector2(39, 91), Vector2(52, 104), Vector2(74, 104)], outline)
		_poly([Vector2(66, 87), Vector2(49, 86), Vector2(46, 92), Vector2(56, 99), Vector2(74, 98)], shade)

	# Far limbs; the short-leg option still reaches the ground.
	draw_rect(Rect2(77, leg_top, 22, 41 if tall_legs else 28), outline)
	draw_rect(Rect2(79, leg_top, 17, 37 if tall_legs else 25), shade)
	draw_rect(Rect2(146, leg_top, 21, 41 if tall_legs else 28), outline)
	draw_rect(Rect2(148, leg_top, 16, 37 if tall_legs else 25), shade)
	_poly([Vector2(67, 76), Vector2(85, 62), Vector2(143, 65), Vector2(166, 81), Vector2(170, 112), Vector2(151, 129), Vector2(86, 129), Vector2(63, 112)], outline)
	_poly([Vector2(70, 79), Vector2(87, 67), Vector2(140, 69), Vector2(162, 84), Vector2(165, 109), Vector2(148, 123), Vector2(88, 123), Vector2(69, 109)], coat)
	_poly([Vector2(88, 72), Vector2(137, 73), Vector2(149, 83), Vector2(89, 82)], highlight)
	if long_coat:
		for x in [77, 96, 118, 142, 158]:
			_poly([Vector2(x, 116), Vector2(x + 12, 119), Vector2(x + 6, 134)], coat)
	# Near legs and paws, with dark clean feet.
	draw_rect(Rect2(91, leg_top, 20, 42 if tall_legs else 29), outline)
	draw_rect(Rect2(94, leg_top, 15, 36 if tall_legs else 24), coat)
	draw_rect(Rect2(153, leg_top, 20, 42 if tall_legs else 29), outline)
	draw_rect(Rect2(156, leg_top, 15, 36 if tall_legs else 24), coat)
	draw_rect(Rect2(89, 150, 29, 7), outline)
	draw_rect(Rect2(149, 150, 30, 7), outline)

	# Head and muzzle.
	_poly([Vector2(146, 63), Vector2(157, 43), Vector2(180, 41), Vector2(197, 54), Vector2(207, 83), Vector2(189, 98), Vector2(159, 94), Vector2(142, 79)], outline)
	_poly([Vector2(149, 64), Vector2(160, 47), Vector2(178, 45), Vector2(194, 56), Vector2(201, 82), Vector2(187, 93), Vector2(161, 89), Vector2(147, 76)], coat)
	if _visual("ear_type") == "upright":
		_poly([Vector2(153, 58), Vector2(148, 19), Vector2(172, 36), Vector2(175, 52)], outline)
		_poly([Vector2(156, 52), Vector2(153, 28), Vector2(169, 39), Vector2(170, 51)], shade)
		_poly([Vector2(178, 48), Vector2(190, 17), Vector2(197, 56)], outline)
		_poly([Vector2(181, 44), Vector2(190, 29), Vector2(192, 51)], shade)
	else:
		_poly([Vector2(153, 41), Vector2(140, 50), Vector2(143, 77), Vector2(157, 80), Vector2(170, 53)], outline)
		_poly([Vector2(153, 45), Vector2(145, 54), Vector2(147, 74), Vector2(155, 75), Vector2(164, 53)], shade)
		_poly([Vector2(181, 43), Vector2(201, 42), Vector2(208, 71), Vector2(198, 79), Vector2(187, 66)], outline)
		_poly([Vector2(184, 48), Vector2(197, 46), Vector2(203, 68), Vector2(198, 74), Vector2(190, 62)], shade)
	_poly([Vector2(178, 74), Vector2(208, 71), Vector2(211, 86), Vector2(194, 96), Vector2(176, 89)], highlight)
	draw_rect(Rect2(199, 77, 12, 8), outline)
	draw_circle(Vector2(183, 66), 6.0, outline)
	draw_circle(Vector2(183, 65), 3.0, eye)
	draw_circle(Vector2(184, 64), 1.0, Color.WHITE)
	# A small fluorescent collar connects the dog to the lab's visual language.
	draw_rect(Rect2(149, 87, 13, 5), outline)
	draw_rect(Rect2(151, 87, 8, 3), Color("#b5f866"))
	draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow(color: Color) -> void:
	# Short horizontal bands avoid any external texture or image dependency.
	for index in range(6):
		draw_rect(Rect2(55 + index * 5, 157 + index, 122 - index * 10, 2), color)
