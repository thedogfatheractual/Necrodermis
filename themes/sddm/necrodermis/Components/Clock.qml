// Based on sddm-astronaut-theme by Keyitdev
// https://github.com/Keyitdev/sddm-astronaut-theme
// Copyright (C) 2022-2025 Keyitdev
// Modified for Necrodermis by thedogfatheractual
// Distributed under the GPLv3+ License https://www.gnu.org/licenses/gpl-3.0.html

import QtQuick 2.15
import QtQuick.Controls 2.15

Column {
    id: clock

    width: parent.width / 2
    spacing: 0

    Label {
        id: headerTextLabel

        anchors.horizontalCenter: parent.horizontalCenter

        font.pointSize: root.font.pointSize * 3
        color: config.HeaderTextColor
        renderType: Text.QtRendering
        text: config.HeaderText
    }

    Label {
        id: timeLabel

        anchors.horizontalCenter: parent.horizontalCenter

        font.pointSize: root.font.pointSize * 9
        font.bold: true
        color: config.TimeTextColor
        renderType: Text.QtRendering

        function updateTime() {
            text = new Date().toLocaleTimeString(Qt.locale(config.Locale), config.HourFormat == "long" ? Locale.LongFormat : config.HourFormat !== "" ? config.HourFormat : Locale.ShortFormat)
        }
    }

    Label {
        id: dateLabel

        anchors.horizontalCenter: parent.horizontalCenter

        color: config.DateTextColor
        font.pointSize: root.font.pointSize * 2
        font.bold: true
        renderType: Text.QtRendering

        function updateTime() {
            text = new Date().toLocaleDateString(Qt.locale(config.Locale), config.DateFormat == "short" ? Locale.ShortFormat : config.DateFormat !== "" ? config.DateFormat : Locale.LongFormat)
        }
    }

    // ── NECRODERMIS WEATHER WIDGET ──
    // Reads /tmp/necro_weather.txt written by necro_weather.py at boot
    // Format: line 1 = ICAO • condition • temp • wind • flight cat
    //         line 2 = blank
    //         lines 3-7 = ASCII art
    Text {
        id: weatherDisplay

        anchors.horizontalCenter: parent.horizontalCenter

        topPadding: root.font.pointSize * 1.5
        bottomPadding: root.font.pointSize * 1.5

        color: config.DateTextColor
        font.pointSize: root.font.pointSize * 0.95
        font.family: config.Font
        renderType: Text.QtRendering
        horizontalAlignment: Text.AlignHCenter

        // Empty until first read — avoids a blank flash at login
        text: ""

        function loadWeather() {
            try {
                var xhr = new XMLHttpRequest()
                xhr.open("GET", "file:///tmp/necro_weather.txt", false)
                xhr.send()
                if (xhr.status === 0 && xhr.responseText.length > 0) {
                    text = xhr.responseText.trim()
                } else {
                    text = ""
                }
            } catch(e) {
                text = ""
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            dateLabel.updateTime()
            timeLabel.updateTime()
        }
    }

    // Refresh weather every 10 minutes
    Timer {
        interval: 600000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: weatherDisplay.loadWeather()
    }

    Component.onCompleted: {
        dateLabel.updateTime()
        timeLabel.updateTime()
        weatherDisplay.loadWeather()
    }
}
