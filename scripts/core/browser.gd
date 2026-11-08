class_name Browser
## Talks to the web page around the game (only does anything in the web build).
## Full screen: the page itself enters full screen on the player's next tap, because browsers only allow it
## from a tap. The script that does it lives in the export's head include (export_presets.cfg).


static func set_fullscreen_wanted(wanted: bool) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.glFullscreen && (window.glFullscreen.want = %s);" % ("true" if wanted else "false"), true)


static func leave_fullscreen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(document.exitFullscreen||document.webkitExitFullscreen||function(){}).call(document);", true)
