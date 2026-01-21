import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    width: implicitWidth
    height: implicitHeight
    Plasmoid.icon: "view-statistics"
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh"
            icon.name: "view-refresh"
            onTriggered: root.refreshNow()
        }
    ]

    property string command: Plasmoid.configuration.command || "codexbar usage --status --provider codex --source cli"
    property int refreshIntervalSec: Math.max(10, Plasmoid.configuration.refreshInterval || 60)
    property var usageItems: []
    property var metaData: ({})
    property string warningText: ""
    property string errorText: ""
    property int sessionPercent: -1
    property int weeklyPercent: -1
    property string lastUpdatedText: ""
    property double lastUpdatedAt: 0
    property int compactWidth: Math.max(Kirigami.Units.gridUnit * 6, sessionText.implicitWidth + Kirigami.Units.gridUnit * 2)
    onRefreshIntervalSecChanged: usageSource.interval = root.refreshIntervalSec * 1000

    function parseOutput(stdoutText, stderrText) {
        var lines = (stdoutText + "\n" + stderrText).split(/\r?\n/)
        var items = []
        var meta = { account: "", plan: "", status: "", version: "" }
        var warnings = []
        var lastUsageIndex = -1

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.length === 0) {
                continue
            }
            if (line.indexOf("libcurl") !== -1) {
                continue
            }
            if (line.indexOf("Resets ") === 0) {
                if (lastUsageIndex >= 0) {
                    items[lastUsageIndex].reset = line.substring(7).trim()
                }
                continue
            }
            if (line.indexOf("codexbar:") === 0) {
                if (line.indexOf("libcurl") === -1) {
                    warnings.push(line)
                }
                continue
            }
            if (line.indexOf("Codex ") === 0) {
                meta.version = line
                continue
            }

            var match = line.match(/^([^:]+):\s*(.*)$/)
            if (!match) {
                continue
            }

            var key = match[1].trim()
            var value = match[2].trim()
            var lowerKey = key.toLowerCase()

            if (lowerKey === "credits") {
                lastUsageIndex = -1
                continue
            }

            if (lowerKey === "resets") {
                if (lastUsageIndex >= 0) {
                    items[lastUsageIndex].reset = value
                }
                continue
            }

            if (lowerKey === "account") {
                meta.account = value
                lastUsageIndex = -1
                continue
            }

            if (lowerKey === "plan") {
                meta.plan = value
                lastUsageIndex = -1
                continue
            }

            if (lowerKey === "status") {
                meta.status = value
                lastUsageIndex = -1
                continue
            }

            var percentMatch = value.match(/(\d+(?:\.\d+)?)%\s*left/i)
            var item = {
                label: key,
                raw: value,
                percent: null,
                reset: ""
            }

            if (percentMatch) {
                item.percent = parseFloat(percentMatch[1])
            }

            items.push(item)
            lastUsageIndex = items.length - 1
        }

        usageItems = items
        metaData = meta
        warningText = warnings.join("\n")
        var stderrLines = stderrText.split(/\r?\n/)
        var cleanedErrors = []
        for (var s = 0; s < stderrLines.length; s++) {
            var errLine = stderrLines[s].trim()
            if (errLine.length === 0) {
                continue
            }
            if (errLine.indexOf("codexbar:") === 0) {
                if (errLine.indexOf("libcurl") === -1) {
                    cleanedErrors.push(errLine)
                }
                continue
            }
            if (errLine.indexOf("libcurl") !== -1) {
                continue
            }
            cleanedErrors.push(errLine)
        }
        errorText = cleanedErrors.join("\n")

        sessionPercent = -1
        weeklyPercent = -1
        for (var j = 0; j < items.length; j++) {
            var label = items[j].label.toLowerCase()
            if (label === "session" && items[j].percent !== null) {
                sessionPercent = items[j].percent
            }
            if (label === "weekly" && items[j].percent !== null) {
                weeklyPercent = items[j].percent
            }
        }
        if (sessionPercent < 0 && items.length > 0 && items[0].percent !== null) {
            sessionPercent = items[0].percent
        }

        var now = new Date()
        lastUpdatedAt = now.getTime()
        lastUpdatedText = "Updated " + Qt.formatDateTime(now, "hh:mm")
    }

    function refreshNow() {
        usageSource.disconnectSource(root.command)
        usageSource.connectSource(root.command)
    }

    onCommandChanged: refreshNow()

    Plasma5Support.DataSource {
        id: usageSource
        engine: "executable"
        connectedSources: [root.command]
        interval: root.refreshIntervalSec * 1000

        onNewData: function (sourceName, data) {
            var stdoutText = data && data["stdout"] ? data["stdout"] : ""
            var stderrText = data && data["stderr"] ? data["stderr"] : ""
            root.parseOutput(stdoutText, stderrText)
        }
    }

    compactRepresentation: Item {
        id: compactRoot
        clip: true
        implicitWidth: root.compactWidth
        implicitHeight: Kirigami.Units.gridUnit * 2
        Layout.minimumWidth: root.compactWidth
        Layout.preferredWidth: root.compactWidth
        Layout.minimumHeight: Kirigami.Units.gridUnit * 2

        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }

        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            Text {
                id: sessionText
                text: sessionPercent >= 0 ? (sessionPercent.toFixed(0) + "%") : "—"
                font.bold: true
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
                horizontalAlignment: Text.AlignLeft
                color: Kirigami.Theme.textColor
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    fullRepresentation: Item {
        id: fullRoot
        implicitWidth: Kirigami.Units.gridUnit * 22
        implicitHeight: contentLayout.implicitHeight + Kirigami.Units.gridUnit

        ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "view-statistics"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    Kirigami.Heading {
                        text: "KodexBar"
                        level: 3
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    PlasmaComponents.Label {
                        text: metaData.account ? (metaData.account + (metaData.plan ? " · " + metaData.plan : "")) : ""
                        opacity: 0.7
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    PlasmaComponents.Label {
                        text: metaData.status ? metaData.status : ""
                        opacity: 0.7
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    PlasmaComponents.Label {
                        text: lastUpdatedText
                        opacity: 0.6
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    PlasmaComponents.Label {
                        text: Plasmoid.metaData.version ? ("v" + Plasmoid.metaData.version) : ""
                        opacity: 0.5
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                PlasmaComponents.ToolButton {
                    icon.name: "view-refresh"
                    onClicked: root.refreshNow()
                    Accessible.name: "Refresh"
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            Repeater {
                model: usageItems

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            text: modelData.label
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        PlasmaComponents.Label {
                            visible: modelData.percent === null
                            text: modelData.raw
                            opacity: 0.7
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    PlasmaComponents.ProgressBar {
                        visible: modelData.percent !== null
                        from: 0
                        to: 100
                        value: modelData.percent === null ? 0 : modelData.percent
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        visible: modelData.percent !== null || (modelData.reset && modelData.reset.length > 0)
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            text: modelData.percent !== null ? (modelData.percent.toFixed(0) + "% left") : ""
                            opacity: 0.6
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        visible: modelData.reset && modelData.reset.length > 0
                        text: "Resets " + modelData.reset
                        opacity: 1
                        Layout.fillWidth: true
                        wrapMode: Text.NoWrap
                        elide: Text.ElideNone
                        color: Kirigami.Theme.textColor
                    }

                    Kirigami.Separator { Layout.fillWidth: true }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            PlasmaComponents.Label {
                visible: errorText.length > 0
                text: errorText
                color: Kirigami.Theme.negativeTextColor
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
        }
    }
}
