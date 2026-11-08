#!/usr/bin/env bash
# Serves the exported build locally on port 8060 for the browser playtesters.
cd "$(dirname "$0")/../../play" && exec python3 -m http.server 8060 --bind 127.0.0.1
