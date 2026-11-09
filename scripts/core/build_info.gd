class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.5.1"
const BUILT := "2026-11-09 15:28 UTC"
const COMMIT := "28658fd-dirty"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
