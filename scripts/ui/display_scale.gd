extends RefCounted
## Web canvas dimensions are device pixels; HUD layout needs CSS pixels.
## Let Godot stretch the canvas and transform input together, including on Retina.
const POLL_SECONDS := 0.25
var elapsed := POLL_SECONDS

func refresh(window: Window, delta: float) -> void:
	if not OS.has_feature("web"):
		return
	elapsed += delta
	if elapsed < POLL_SECONDS:
		return
	elapsed = 0.0
	var metrics: Variant = JavaScriptBridge.eval("""(function () {
		const canvas = document.getElementById('canvas');
		if (!canvas) return null;
		const rect = canvas.getBoundingClientRect();
		return JSON.stringify([Math.round(rect.width), Math.round(rect.height)]);
	})()""")
	if not metrics is String:
		return
	var dimensions: Variant = JSON.parse_string(metrics)
	if not dimensions is Array or dimensions.size() != 2:
		return
	apply_css_size(window, Vector2i(int(dimensions[0]), int(dimensions[1])))

static func apply_css_size(window: Window, css_size: Vector2i) -> void:
	# Ignore transient zero-sized canvases while rotating or entering fullscreen.
	if css_size.x < 64 or css_size.y < 64:
		return
	if window.content_scale_mode != Window.CONTENT_SCALE_MODE_CANVAS_ITEMS:
		window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if window.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_IGNORE:
		window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	if window.content_scale_size != css_size:
		window.content_scale_size = css_size
