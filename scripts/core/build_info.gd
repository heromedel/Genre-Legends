class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.5.2"
const BUILT := "2026-11-09 15:36 UTC"
const COMMIT := "9bf818a"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
