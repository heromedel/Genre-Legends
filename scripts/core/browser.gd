class_name Browser
## Talks to the web page around the game (only does anything in the web build).
## Full screen: the page itself enters full screen on the player's next tap, because browsers only allow it
## from a tap. The script that does it lives in the export's head include (export_presets.cfg).


static func set_fullscreen_wanted(wanted: bool) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.glFullscreen && (window.glFullscreen.want = %s);" % ("true" if wanted else "false"), true)


## Removes the offline copy of the game (the service worker and its cached files) and reloads the page,
## so the newest build loads from the site. Saves live in separate storage and are not touched.
static func clear_cache_and_reload() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""(async function () {
		try { if (navigator.serviceWorker) { const regs = await navigator.serviceWorker.getRegistrations(); for (const r of regs) { await r.unregister(); } } } catch (e) {}
		try { if (window.caches) { const keys = await caches.keys(); for (const k of keys) { await caches.delete(k); } } } catch (e) {}
		window.location.reload();
	})();""", true)


static func leave_fullscreen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(document.exitFullscreen||document.webkitExitFullscreen||function(){}).call(document);", true)
