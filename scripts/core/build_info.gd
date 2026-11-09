class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.4.2"
const BUILT := "2026-11-09 08:46 UTC"
const COMMIT := "0b8ac45-dirty"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
