class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.6.0"
const BUILT := "2026-11-10 00:03 UTC"
const COMMIT := "7fbd04e-dirty"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
