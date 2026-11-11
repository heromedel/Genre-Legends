class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.6.1"
const BUILT := "2026-11-11 04:40 UTC"
const COMMIT := "b7e006d-dirty"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
