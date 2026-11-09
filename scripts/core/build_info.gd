class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.4.0"
const BUILT := "2026-11-09 07:09 UTC"
const COMMIT := "5ed7905-dirty"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
