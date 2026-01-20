import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_command: commandField.text
    property alias cfg_refreshInterval: refreshIntervalSpin.value

    Kirigami.FormLayout {
        QQC2.TextField {
            id: commandField
            Kirigami.FormData.label: "Command"
            placeholderText: "codexbar usage --status --provider codex --source cli"
        }

        QQC2.SpinBox {
            id: refreshIntervalSpin
            Kirigami.FormData.label: "Refresh interval (seconds)"
            from: 10
            to: 3600
            stepSize: 10
            editable: true
        }
    }
}
