#import "@preview/lilaq:0.5.0" as lq

// ── Load and parse the field-test CSV ─────────────────────────────
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
    distance_m:  float,
  ),
)

#let time-raw  = raw-data.at("time")
#let snr       = raw-data.at("snr")
#let rssi      = raw-data.at("rssi")
#let sf        = raw-data.at("sf").map(x => int(x))
#let tx-power  = raw-data.at("tx_power")
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

#let color-main = rgb("#3366cc")
#let color-secondary = rgb("#dc3912")
#let color-location = rgb("#2ca02c")

#let t-switch-1 = (time-min.at(12) + time-min.at(13)) / 2.0
#let t-switch-2 = (time-min.at(17) + time-min.at(18)) / 2.0
#let location-stroke = (paint: color-location, dash: "dotted", thickness: 0.8pt)

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

// ── 1. SNR over Time with Target ─────────────────────────────────
#figure(
  {
    set text(size: 7pt)
    lq.diagram(
      title: [SNR Tracking (field test)],
    xlabel: [Elapsed time (min)],
    ylabel: [SNR (dB)],
    width: 100%, height: 6cm,
    legend: (position: top + right, inset: 0.2em),

    lq.plot(time-min, snr,
      color: color-main, mark: "o", mark-size: 3pt, label: [Measured SNR]),
    lq.plot(time-min, snr-target,
      stroke: (paint: color-secondary, dash: "dashed", thickness: 0.5pt), mark: none, label: [Target SNR]),
    lq.vlines(t-switch-1, t-switch-2, stroke: location-stroke, label: [Location change]),
  )
  },
  caption: [Measured SNR and target SNR (dashed) over time. Green dotted lines mark the transitions from 100#sym.space.thin m to 250#sym.space.thin m and from 250#sym.space.thin m to 400#sym.space.thin m.],
) <fig:field-time>


#figure(
  {
    set text(size: 5pt)
    lq.diagram(
      title: [Spreading Factor and TX Power over Time (field test)],
    xlabel: [Elapsed time (min)],
    ylabel: [Parameter Value],
    width: 100%, height: 6cm,
    legend: (position: top + right, inset: 0.2em),

    lq.plot(time-min, sf.map(x => float(x)),
      color: color-main, mark: "o", mark-size: 3pt, step: end, label: [Spreading Factor]),
    lq.plot(time-min, tx-power,
      color: color-secondary, mark: "s", mark-size: 3pt, label: [TX Power (dBm)]),
    lq.vlines(t-switch-1, t-switch-2, stroke: location-stroke, label: [Location change]),
  )
  },
  caption: [SF and TX power adapted by the PD controller. Green dotted lines mark location changes. As distance increases, the controller raises TX power first and then SF.],
) <fig:field-params>


#figure(
  {
    set text(size: 7pt)
    lq.diagram(
      title: [SNR and RSSI vs Distance (field test)],
    xlabel: [Distance (m)],
    ylabel: [dB],
    width: 100%, height: 6cm,
    legend: (position: right, inset: 0.2em),

    lq.plot(distance, snr,
      color: color-main, mark: "o", mark-size: 3pt, label: [SNR (dB)]),
    lq.plot(distance, rssi,
      color: color-secondary, mark: "s", mark-size: 3pt, label: [RSSI (dBm)]),
  )
  },
  caption: [SNR and RSSI as a function of distance from the gateway. Both degrade with increasing distance, as expected from free-space path loss.],
) <fig:field-distance>
