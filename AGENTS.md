# KodexBar (Plasma 6)

## Overview
This repo is a KDE Plasma 6 applet (plasmoid) that wraps the `codexbar` CLI and shows usage data (session/week/credits/etc.) with progress bars. It is designed for Fedora 43 KDE Plasma 6.5 and refreshes every 60 seconds.

## Architecture
- **Plasma applet (QML only):** The widget is a standard Plasma Applet using the canonical Plasma 6 QML APIs. No extra services or daemons are required.
- **Data flow:** `Plasma5Support.DataSource` runs `codexbar usage --status --provider codex --source cli` every minute. Output is parsed in QML and bound to UI properties.
- **UI:** Compact representation shows session percent only. Full representation shows a header plus usage rows with progress bars and reset times.

## Key files
- `metadata.json`: Plasma applet metadata and entry point.
- `contents/ui/main.qml`: Main UI and CLI parsing logic.
- `contents/config/config.qml`: Settings pages for the widget.
- `contents/ui/configGeneral.qml`: General settings UI (command + refresh interval).
- `contents/config/main.xml`: Default settings values.

## Parsing behavior
- Lines like `Session: 98% left` and `Weekly: 88% left` are parsed into usage items with progress bars.
- `Resets ...` lines are attached to the most recent usage item.
- `Account`, `Plan`, and `Status` are shown in the header.
- Lines starting with `codexbar:` are treated as warnings (libcurl messages are ignored).
- `Credits` lines are skipped in the popup.

## Settings
- **Command:** Override the CLI command used to fetch usage.
- **Refresh interval:** Polling interval in seconds (minimum 10s).

## Refresh cadence
- The widget runs the CLI every 60 seconds (interval = 60000ms).

## Install / run (Plasma 6)
From this repo root, install locally with:
- `kpackagetool6 -t Plasma/Applet -i .`
- or run `./install.sh`

To update after changes:
- `kpackagetool6 -t Plasma/Applet -u .`
- or run `./update.sh`

Then add the widget from the Plasma “Add Widgets” menu.
