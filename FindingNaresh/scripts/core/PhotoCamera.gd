class_name PhotoCamera
extends RefCounted

## A snapshot of the world from a point: one render of an offscreen camera
## into a texture (Naresh's photo, E3). Costs one extra frame of rendering,
## once. Headless there is nothing to render: returns null.

## Renders the world from `xf` (camera transform) at `size`, with `fov`
## (vertical, degrees). Await it: `var tex = await PhotoCamera.take(...)`.
static func take(from: Node, xf: Transform3D, size := Vector2i(640, 480), fov := 52.0) -> ImageTexture:
	if DisplayServer.get_name() == "headless":
		return null
	var vp := SubViewport.new()
	vp.name = "PhotoViewport"
	vp.size = size
	vp.world_3d = from.get_viewport().world_3d
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var cam := Camera3D.new()
	cam.fov = fov
	cam.near = 0.1
	cam.far = 3000.0
	cam.cull_mask = 1               # the shared world only: no one's private layers
	vp.add_child(cam)
	from.add_child(vp)
	cam.global_transform = xf
	cam.current = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	if img == null:
		return null
	return ImageTexture.create_from_image(img)
