import QtQuick

Item {
    id: root

    required property var theme
    required property var config
    required property var state   // shared WeatherState instance
    property bool compact: true

    property string cityLabel: config.weatherCity || "Your location"

    function _iconFor(code) {
        if (code === 0) return "sunny";
        if (code >= 1 && code <= 3) return "partly_cloudy_day";
        if (code === 45 || code === 48) return "foggy";
        if (code >= 51 && code <= 67) return "rainy";
        if (code >= 71 && code <= 77) return "weather_snowy";
        if (code >= 80 && code <= 82) return "rainy";
        if (code >= 85 && code <= 86) return "weather_snowy";
        if (code >= 95) return "thunderstorm";
        return "cloud";
    }
    function _labelFor(code) {
        if (code === 0) return "Clear sky";
        if (code >= 1 && code <= 3) return "Partly cloudy";
        if (code === 45 || code === 48) return "Fog";
        if (code >= 51 && code <= 57) return "Drizzle";
        if (code >= 61 && code <= 67) return "Rain";
        if (code >= 71 && code <= 77) return "Snow";
        if (code >= 80 && code <= 82) return "Rain showers";
        if (code >= 85 && code <= 86) return "Snow showers";
        if (code >= 95) return "Thunderstorm";
        return "Cloudy";
    }

    Column {
        anchors.centerIn: parent
        spacing: root.compact ? 6 : 12
        visible: !root.state.loaded

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "cloud_off"
            font.family: root.theme.iconFontFamily
            font.pixelSize: root.compact ? 20 : 34
            color: root.theme.subtext
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.state.loading ? "Loading…" : (root.state.errored ? "Couldn't fetch weather" : "No Weather")
            color: root.theme.subtext
            font.pixelSize: root.theme.fontSizeSmall
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: refreshLabel.implicitWidth + 24
            height: 26
            radius: 13
            color: root.theme.accent

            Text {
                id: refreshLabel
                anchors.centerIn: parent
                text: "Refresh"
                color: root.theme.bg
                font.pixelSize: root.theme.fontSizeSmall
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.state.refresh()
            }
        }
    }

    // Compact (Overview tab card)
    Column {
        anchors.centerIn: parent
        spacing: 2
        visible: root.state.loaded && root.compact

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Text {
                text: root._iconFor(root.state.weatherCode)
                font.family: root.theme.iconFontFamily
                font.pixelSize: 22
                color: root.theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: Math.round(root.state.tempC) + "°C"
                color: root.theme.text
                font.pixelSize: 18
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root._labelFor(root.state.weatherCode)
            color: root.theme.subtext
            font.pixelSize: root.theme.fontSizeSmall
        }
    }

    // Full (Weather tab) — current conditions + details + hourly strip
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16
        visible: root.state.loaded && !root.compact

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14
            Text {
                text: root._iconFor(root.state.weatherCode)
                font.family: root.theme.iconFontFamily
                font.pixelSize: 48
                color: root.theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }
            Column {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: Math.round(root.state.tempC) + "°C"
                    color: root.theme.text
                    font.pixelSize: 34
                    font.bold: true
                }
                Text {
                    text: root._labelFor(root.state.weatherCode) + " · " + root.cityLabel
                    color: root.theme.subtext
                    font.pixelSize: root.theme.fontSizeSmall
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 28

            Column {
                spacing: 2
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "thermostat"; font.family: root.theme.iconFontFamily; font.pixelSize: 18; color: root.theme.subtext }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Feels " + Math.round(root.state.feelsLikeC) + "°"; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall }
            }
            Column {
                spacing: 2
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "water_drop"; font.family: root.theme.iconFontFamily; font.pixelSize: 18; color: root.theme.subtext }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(root.state.humidity) + "%"; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall }
            }
            Column {
                spacing: 2
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "air"; font.family: root.theme.iconFontFamily; font.pixelSize: 18; color: root.theme.subtext }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(root.state.windKmh) + " km/h"; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall }
            }
            Column {
                spacing: 2
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "wb_sunny"; font.family: root.theme.iconFontFamily; font.pixelSize: 18; color: root.theme.subtext }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "UV " + Math.round(root.state.uvIndex); color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 28
            visible: root.state.sunrise !== null && root.state.sunset !== null

            Column {
                spacing: 2
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "wb_twilight"; font.family: root.theme.iconFontFamily; font.pixelSize: 16; color: root.theme.subtext }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.state.sunrise ? Qt.formatDateTime(root.state.sunrise, "h:mm AP") : "—"
                    color: root.theme.text
                    font.pixelSize: root.theme.fontSizeSmall - 1
                }
            }
            Column {
                spacing: 2
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "nightlight"; font.family: root.theme.iconFontFamily; font.pixelSize: 16; color: root.theme.subtext }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.state.sunset ? Qt.formatDateTime(root.state.sunset, "h:mm AP") : "—"
                    color: root.theme.text
                    font.pixelSize: root.theme.fontSizeSmall - 1
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: root.theme.border }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 18

            Repeater {
                model: root.state.hourly
                Column {
                    required property var modelData
                    spacing: 4
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(modelData.time, "h AP")
                        color: root.theme.subtext
                        font.pixelSize: root.theme.fontSizeSmall - 1
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root._iconFor(modelData.code)
                        font.family: root.theme.iconFontFamily
                        font.pixelSize: 18
                        color: root.theme.accent
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(modelData.temp) + "°"
                        color: root.theme.text
                        font.pixelSize: root.theme.fontSizeSmall
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: modelData.precipChance > 0
                        text: Math.round(modelData.precipChance) + "%"
                        color: root.theme.accentDim
                        font.pixelSize: root.theme.fontSizeSmall - 2
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Text {
                visible: root.state.lastUpdated !== null
                anchors.verticalCenter: parent.verticalCenter
                text: root.state.lastUpdated ? "Updated " + Qt.formatDateTime(root.state.lastUpdated, "h:mm AP") : ""
                color: root.theme.subtext
                font.pixelSize: root.theme.fontSizeSmall - 2
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: refreshLabel2.implicitWidth + 24
                height: 26
                radius: 13
                color: root.theme.card
                Text { id: refreshLabel2; anchors.centerIn: parent; text: "Refresh"; color: root.theme.text; font.pixelSize: root.theme.fontSizeSmall }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.state.refresh() }
            }
        }
    }
}
