class_name Browser
## Talks to the web page around the game (only does anything in the web build).
## Audio: iPad Safari can suspend or interrupt the page's audio (another app, a call, the screen dimming)
## and never bring it back. The head include watches the audio context, resumes it on the next tap or key,
## and keeps a list of what happened for the play log (audio_events).
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


## What happened to the page's audio since the last call ("audio is now suspended", ...), oldest first.
static func audio_events() -> Array:
	if not OS.has_feature("web"):
		return []
	var text = JavaScriptBridge.eval("JSON.stringify((window.glAudio && window.glAudio.events.splice(0)) || [])", true)
	var parsed = JSON.parse_string(str(text)) if text != null else []
	return parsed if parsed is Array else []
