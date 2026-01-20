#!/usr/bin/env bash
set -euo pipefail

kpackagetool6 -t Plasma/Applet -u .

echo "Updated. If the widget does not refresh, toggle it off/on or log out/in."
