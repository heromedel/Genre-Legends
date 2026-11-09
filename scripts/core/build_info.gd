class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.4.0-dev"
const BUILT := "2026-11-09 06:25 UTC"
const COMMIT := "659dd99-dirty"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
