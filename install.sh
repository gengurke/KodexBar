#!/usr/bin/env bash
set -euo pipefail

kpackagetool6 -t Plasma/Applet -i .

echo "Installed. Add it via Plasma \"Add Widgets\"."
