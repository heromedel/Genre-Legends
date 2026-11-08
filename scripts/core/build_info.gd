class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.2.0"
const BUILT := "2026-11-08 12:17 UTC"
const COMMIT := "659533b-dirty"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
