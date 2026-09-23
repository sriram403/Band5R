class_name ToonMat
extends RefCounted

## Central place for the cartoon look. Every mesh in the world should get its
## material from here so the art direction can be retuned in one file.

const OUTLINE_COLOR := Color(0.10, 0.08, 0.14)

static var _cache: Dictionary = {}

## Banded-diffuse material with an inverted-hull outline pass.
##   outline   : hull thickness in metres (0 disables the outline)
##   rough     : surface roughness
##   emission  : optional glow colour, use Color(0,0,0) for none
static func make(color: Color, outline := 0.014, rough := 0.92, emission := Color(0, 0, 0)) -> StandardMaterial3D:
	var key := "%s|%.4f|%.2f|%s" % [color.to_html(), outline, rough, emission.to_html()]
	if _cache.has(key):
		return _cache[key]

	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = 0.0
	m.metallic_specular = 0.0
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if emission.r + emission.g + emission.b > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 1.4
	if outline > 0.0:
		m.next_pass = _outline(outline)
	_cache[key] = m
	return m


## Flat unshaded colour, used for road paint, signage and UI-ish surfaces.
static func flat(color: Color, outline := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if outline > 0.0:
		m.next_pass = _outline(outline)
	return m


## Additive translucent material for light shafts and glows.
static func glow(color: Color, alpha := 0.08) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	m.no_depth_test = false
	return m


## Water-ish surface: slightly transparent, smooth, faint rim.
static func water(color := Color(0.28, 0.58, 0.72, 0.82)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.12
	m.metallic = 0.25
	m.metallic_specular = 0.7
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	return m


static func _outline(width: float) -> StandardMaterial3D:
	var o := StandardMaterial3D.new()
	o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	o.albedo_color = OUTLINE_COLOR
	o.cull_mode = BaseMaterial3D.CULL_FRONT
	o.grow = true
	o.grow_amount = width
	o.disable_receive_shadows = true
	o.shadow_to_opacity = false
	return o
