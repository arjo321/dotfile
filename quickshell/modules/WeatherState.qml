import QtQuick

QtObject {
    id: state

    // Set once by whoever creates this (Dashboard.qml).
    property var config: null

    property bool loading: false
    property bool loaded: false
    property bool errored: false
    property real tempC: 0
    property real feelsLikeC: 0
    property real humidity: 0
    property real windKmh: 0
    property int weatherCode: 0
    property var hourly: []   // [{time, temp, code, precipChance}, ...] next few hours
    property var sunrise: null
    property var sunset: null
    property real uvIndex: 0
    property var lastUpdated: null

    function refresh() {
        if (!state.config) return;
        state.loading = true;
        state.errored = false;
        var lat = state.config.weatherLat || 26.7271;
        var lon = state.config.weatherLon || 88.3953;
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat
                + "&longitude=" + lon
                + "&current=temperature_2m,weather_code,relative_humidity_2m,apparent_temperature,wind_speed_10m"
                + "&hourly=temperature_2m,weather_code,precipitation_probability"
                + "&daily=sunrise,sunset,uv_index_max"
                + "&forecast_days=1&temperature_unit=celsius&wind_speed_unit=kmh&timezone=auto";

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            state.loading = false;
            if (xhr.status !== 200) { state.errored = true; return; }
            try {
                var data = JSON.parse(xhr.responseText);
                state.tempC = data.current.temperature_2m;
                state.weatherCode = data.current.weather_code;
                state.feelsLikeC = data.current.apparent_temperature;
                state.humidity = data.current.relative_humidity_2m;
                state.windKmh = data.current.wind_speed_10m;

                if (data.daily) {
                    state.sunrise = data.daily.sunrise && data.daily.sunrise[0] ? new Date(data.daily.sunrise[0]) : null;
                    state.sunset = data.daily.sunset && data.daily.sunset[0] ? new Date(data.daily.sunset[0]) : null;
                    state.uvIndex = data.daily.uv_index_max ? data.daily.uv_index_max[0] : 0;
                }

                var hrs = [];
                if (data.hourly && data.hourly.time) {
                    var now = new Date();
                    for (var i = 0; i < data.hourly.time.length && hrs.length < 6; i++) {
                        var t = new Date(data.hourly.time[i]);
                        if (t < now) continue;
                        hrs.push({
                            time: t,
                            temp: data.hourly.temperature_2m[i],
                            code: data.hourly.weather_code[i],
                            precipChance: data.hourly.precipitation_probability ? data.hourly.precipitation_probability[i] : 0
                        });
                    }
                }
                state.hourly = hrs;
                state.loaded = true;
                state.lastUpdated = new Date();
            } catch (e) {
                state.errored = true;
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // Auto-refresh every 15 minutes once we have a first successful fetch —
    // shared across every WeatherWidget that points at this state, so it
    // only ever needs to actually run once, anywhere.
    property Timer _autoTimer: Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: state.loaded
        onTriggered: state.refresh()
    }
}
