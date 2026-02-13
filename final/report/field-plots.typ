#import "@preview/lilaq:0.5.0" as lq

// ── Load and parse the walk-test CSV ──────────────────────────────
#let raw-data = lq.load-txt(
  read("assets/walktest.csv"),
  delimiter: ",",
  header: true,
  converters: (
    time:        str,
    snr:         float,
    rssi:        float,
    sf:          float,
    tx_power:    float,
    dl_sf:       str,
    dl_powe:     str,
    gateway:     str,
    node:        str,
    distance_m:  float,
    rest:        str,
  ),
)

#let time-raw  = raw-data.at("time")
#let snr       = raw-data.at("snr")
#let rssi      = raw-data.at("rssi")
#let sf        = raw-data.at("sf").map(x => int(x))
#let tx-power  = raw-data.at("tx_power")
#let gateway   = raw-data.at("gateway")
#let node      = raw-data.at("node")
#let distance  = raw-data.at("distance_m")

#let n-rows = snr.len()
#let indices = range(n-rows)

// Compute elapsed time in minutes from the first timestamp.
#let parse-seconds(ts) = {
  let t-part = ts.split("T").at(1)
  let hms = t-part.split(":")
  let h = int(hms.at(0))
  let m = int(hms.at(1))
  let s = float(hms.at(2))
  h * 3600.0 + m * 60.0 + s
}

#let abs-seconds = time-raw.map(ts => parse-seconds(ts))
#let t0 = abs-seconds.at(0)
#let time-min = abs-seconds.map(s => (s - t0) / 60.0)

// Helper: select array elements at given indices
#let sel(arr, idxs) = idxs.map(i => arr.at(i))

#let color-main = rgb("#3366cc")
#let color-secondary = rgb("#dc3912")

// SNR targets per SF (same as used in PD controller)
#let snr-targets = (
  "7":  -7.5,
  "8":  -10.0,
  "9":  -12.5,
  "10": -15.0,
  "11": -17.5,
  "12": -20.0,
)

// Map SF to target SNR for each data point
#let snr-target = sf.map(s => snr-targets.at(str(s)))

// ── 1. SNR and RSSI over Time ────────────────────────────────────
#figure(
  lq.diagram(
    title: [SNR and RSSI over Time (field test)],
    xlabel: [Elapsed time (min)],
    ylabel: [Signal Strength],
    width: 100%, height: 7cm,
    legend: (position: right + horizon),

    lq.plot(time-min, snr,
      color: color-main, mark: "o", mark-size: 3pt, label: [SNR (dB)]),
    lq.plot(time-min, rssi,
      color: color-secondary, mark: "s", mark-size: 3pt, label: [RSSI (dBm)]),
    
    // SNR target as dashed reference
    lq.plot(time-min, snr-target,
      stroke: (paint: color-main, dash: "dashed", thickness: 0.5pt), mark: none, label: [SNR Target]),
  ),
  caption: [Measured SNR and RSSI over elapsed time during the field test. Both gateway and node were mobile. Dashed line shows the SNR target for the current spreading factor.],
) <fig:field-time>


// ── 2. SNR and RSSI vs Distance ──────────────────────────────────
#figure(
  lq.diagram(
    title: [SNR and RSSI vs Distance (field test)],
    xlabel: [Distance (m)],
    ylabel: [Signal Strength],
    width: 100%, height: 7cm,
    legend: (position: right + horizon),

    lq.plot(distance, snr,
      color: color-main, mark: "o", mark-size: 4pt, stroke: none, label: [SNR (dB)]),
    lq.plot(distance, rssi,
      color: color-secondary, mark: "s", mark-size: 4pt, stroke: none, label: [RSSI (dBm)]),
  ),
  caption: [SNR and RSSI as a function of estimated node-gateway distance. Distance is measured from the gateway's location (first listed node, or primera) to each node position.],
) <fig:field-distance>


// ── 3. SF and TX Power over Time ─────────────────────────────────
#figure(
  lq.diagram(
    title: [Spreading Factor and TX Power over Time (field test)],
    xlabel: [Elapsed time (min)],
    ylabel: [Parameter Value],
    width: 100%, height: 7cm,
    legend: (position: right + horizon),

    lq.plot(time-min, sf.map(x => float(x)),
      color: color-main, mark: "o", mark-size: 3pt, step: end, label: [Spreading Factor]),
    lq.plot(time-min, tx-power,
      color: color-secondary, mark: "s", mark-size: 3pt, label: [TX Power (dBm)]),
  ),
  caption: [Spreading factor and transmit power used by the node at each uplink during the field test.],
) <fig:field-params>
