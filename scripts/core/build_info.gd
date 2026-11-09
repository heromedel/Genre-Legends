class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.3.2"
const BUILT := "2026-11-09 01:21 UTC"
const COMMIT := "f91cbc7-dirty"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
