class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.6.2"
const BUILT := "2026-11-11 05:43 UTC"
const COMMIT := "eb4dc4f"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
