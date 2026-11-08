class_name BuildInfo
## Written by tools/export_web.sh on every export. Do not edit by hand.

const VERSION := "0.3.0-dev"
const BUILT := "2026-11-08 15:18 UTC"
const COMMIT := "3f93763-dirty"


static func label() -> String:
	return "v%s (built %s from %s)" % [VERSION, BUILT, COMMIT]
