class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.3.1"
const BUILT := "2026-11-08 22:51 UTC"
const COMMIT := "8e0fb3c-dirty"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
