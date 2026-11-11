class_name Browser
## Talks to the web page around the game (only does anything in the web build).
## Audio: iPad Safari can suspend or interrupt the page's audio (another app, a call, the screen dimming)
## and never bring it back. The head include watches the audio context, resumes it on the next tap or key,
## and keeps a list of what happened for the play log (audio_events).
## Full screen: the page itself enters full screen on the player's next tap, because browsers only allow it
## from a tap. The script that does it lives in the export's head include (export_presets.cfg).


static func set_fullscreen_wanted(wanted: bool) -> void:
	if OS.has_feature("web"):
		# Turning it on in Settings gives it two fresh tries (it gives up after two, so a browser that refuses
		# isn't asked on every tap: each ask can blur the page, which used to drop the player's touch).
		JavaScriptBridge.eval("window.glFullscreen && (window.glFullscreen.want = %s, window.glFullscreen.tries = 0);" % ("true" if wanted else "false"), true)


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


## What happened to the page itself since the last call ("page hidden", "window lost focus", ...), oldest
## first, so a reload or a lost touch can be matched to what the browser did just before it.
static func page_events() -> Array:
	return _drain("window.glPage && window.glPage.events")


## How this page load started: "navigate" (opened), "reload", "back_forward", or "" off the web.
static func navigation_type() -> String:
	if not OS.has_feature("web"):
		return ""
	var kind = JavaScriptBridge.eval("((performance.getEntriesByType && performance.getEntriesByType('navigation')[0]) || {}).type || 'unknown'", true)
	return str(kind) if kind != null else "unknown"


## How much memory the game holds, in MB: the WebAssembly heap on the web (it grows and never shrinks, and
## a tab that grows too large is the first one iPad Safari throws away), Godot's own count elsewhere.
static func memory_mb() -> float:
	if not OS.has_feature("web"):
		return OS.get_static_memory_usage() / 1048576.0
	var size = JavaScriptBridge.eval("(function(){try{var m=engine.rtenv;var b=(m.HEAP8&&m.HEAP8.buffer)||(m.wasmMemory&&m.wasmMemory.buffer);return b?b.byteLength/1048576:-1;}catch(e){return -1;}})()", true)
	return float(size) if size != null else -1.0


## What happened to the page's audio since the last call ("audio is now suspended", ...), oldest first.
static func audio_events() -> Array:
	return _drain("window.glAudio && window.glAudio.events")


## Empties one of the head include's event lists and returns what was in it.
static func _drain(list: String) -> Array:
	if not OS.has_feature("web"):
		return []
	var text = JavaScriptBridge.eval("JSON.stringify((%s && %s.splice(0)) || [])" % [list, list], true)
	var parsed = JSON.parse_string(str(text)) if text != null else []
	return parsed if parsed is Array else []
