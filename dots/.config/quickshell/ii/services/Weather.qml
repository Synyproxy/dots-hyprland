pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning

import qs.modules.common

Singleton {
    id: root

    // 10 minute
    readonly property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property string city: Config.options.bar.weather.city
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    property bool gpsActive: Config.options.bar.weather.enableGPS

    onUseUSCSChanged: root.getData()
    onCityChanged: root.getData()

    property var location: ({
            valid: false,
            lat: 0,
            lon: 0
        })

    property var data: ({
            uv: 0,
            humidity: 0,
            sunrise: 0,
            sunset: 0,
            windDir: 0,
            wCode: 0,
            city: "",
            wind: "",
            precip: "",
            visib: "",
            press: "",
            temp: "",
            tempFeelsLike: "",
            lastRefresh: ""
        })

    // =========================
    // FORMAT DATA
    // =========================

    function refineData(data) {
        let temp = {};

        temp.uv = 0; // no UV
        temp.humidity = (data?.main?.humidity || 0) + "%";
        const timeOptions = {
            hour: '2-digit',
            minute: '2-digit'
        };
        temp.sunrise = data?.sys?.sunrise ? new Date(data.sys.sunrise * 1000).toLocaleTimeString([], timeOptions) : "00:00";
        temp.sunset = data?.sys?.sunset ? new Date(data.sys.sunset * 1000).toLocaleTimeString([], timeOptions) : "00:00";
        // temp.sunrise = data?.sys?.sunrise ? new Date(data.sys.sunrise * 1000).toLocaleTimeString() : "0";
        //
        // temp.sunset = data?.sys?.sunset ? new Date(data.sys.sunset * 1000).toLocaleTimeString() : "0";

        temp.windDir = data?.wind?.deg || 0;
        temp.wCode = data?.weather?.[0]?.id || 0;
        temp.city = data?.name || "City";

        if (root.useUSCS) {
            temp.wind = (data?.wind?.speed || 0) + " mph";
            temp.precip = "0 in";
            temp.visib = ((data?.visibility || 0) / 1609).toFixed(1) + " mi";
            temp.press = (data?.main?.pressure || 0) + " hPa";
            temp.temp = (data?.main?.temp || 0) + "°F";
            temp.tempFeelsLike = (data?.main?.feels_like || 0) + "°F";
        } else {
            temp.wind = (data?.wind?.speed || 0) + " m/s";
            temp.precip = "0 mm";
            temp.visib = ((data?.visibility || 0) / 1000).toFixed(1) + " km";
            temp.press = (data?.main?.pressure || 0) + " hPa";
            let roundedTemp = Math.round(data?.main?.temp || 0);
            let roundedFeels = Math.round(data?.main?.feels_like || 0);

            temp.temp = roundedTemp + "°C";
            temp.tempFeelsLike = roundedFeels + "°C";
        }

        temp.lastRefresh = DateTime.time + " • " + DateTime.date;

        root.data = temp;
    }

    // =========================
    // FETCH DATA
    // =========================

    function getData() {
        let apiKey = "8b05d62206f459e1d298cbe5844d7d87";

        if (apiKey === "") {
            console.error("[WeatherService] Missing OpenWeather API key.");
            return;
        }

        let units = root.useUSCS ? "imperial" : "metric";
        let url = "https://api.openweathermap.org/data/2.5/weather?";

        if (root.gpsActive && root.location.valid) {
            url += `lat=${root.location.lat}&lon=${root.location.lon}`;
        } else {
            url += `q=${formatCityName(root.city)}`;
        }

        url += `&units=${units}`;
        url += `&appid=${apiKey}`;

        let command = `curl -s "${url}"`;

        fetcher.command[2] = command;
        fetcher.running = true;
    }

    function formatCityName(cityName) {
        return cityName.trim().split(/\s+/).join('+');
    }

    Component.onCompleted: {
        if (!root.gpsActive)
            return;
        console.info("[WeatherService] Starting GPS service.");
        positionSource.start();
    }

    // =========================
    // PROCESS (CURL)
    // =========================

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                try {
                    const parsedData = JSON.parse(text);

                    if (parsedData.cod && parsedData.cod !== 200) {
                        console.error("[WeatherService] API error:", parsedData.message);
                        return;
                    }

                    root.refineData(parsedData);
                } catch (e) {
                    console.error("[WeatherService] JSON parse error:", e.message);
                }
            }
        }
    }

    // =========================
    // GPS
    // =========================

    PositionSource {
        id: positionSource
        updateInterval: root.fetchInterval

        onPositionChanged: {
            if (position.latitudeValid && position.longitudeValid) {
                root.location.lat = position.coordinate.latitude;
                root.location.lon = position.coordinate.longitude;
                root.location.valid = true;
                root.getData();
            } else {
                root.gpsActive = root.location.valid ? true : false;
                console.error("[WeatherService] Failed to get GPS location.");
            }
        }

        onValidityChanged: {
            if (!positionSource.valid) {
                positionSource.stop();
                root.location.valid = false;
                root.gpsActive = false;
                console.error("[WeatherService] Could not acquire valid GPS backend.");
            }
        }
    }

    // =========================
    // TIMER (fallback when GPS disabled)
    // =========================

    Timer {
        running: !root.gpsActive
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: !root.gpsActive
        onTriggered: root.getData()
    }
}
