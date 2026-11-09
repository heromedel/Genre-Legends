class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.5.1"
const BUILT := "2026-11-09 11:45 UTC"
const COMMIT := "b3e01f8-dirty"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
