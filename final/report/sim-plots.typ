#import "@preview/lilaq:0.5.0" as lq

// ── Load and parse the simulation CSV ────────────────────────────
#let raw-data = lq.load-txt(
  read("assets/data.csv"),
  delimiter: ",",
  header: true,
  converters: (
    time_s:              float,
    node:                float,
    rx_power_dbm:        float,
    snr_db:              float,
    snr_target_db:       float,
    sf_used:             float,
    sf_new:              float,
    tx_power_used_dbm:   float,
    tx_power_new_dbm:    float,
    margin_db:           float,
    frequency_hz:        float,
    rest:                str,
  ),
)

// Extract columns as typed arrays
#let time      = raw-data.at("time_s")
#let node      = raw-data.at("node").map(x => int(x))
#let rxpow     = raw-data.at("rx_power_dbm")
#let snr       = raw-data.at("snr_db")
#let target    = raw-data.at("snr_target_db")
#let sf-used   = raw-data.at("sf_used").map(x => int(x))
#let sf-new    = raw-data.at("sf_new").map(x => int(x))
#let txpow-used = raw-data.at("tx_power_used_dbm")
#let txpow-new = raw-data.at("tx_power_new_dbm")
#let margin    = raw-data.at("margin_db")

#let n-rows = time.len()
#let indices = range(n-rows)

// Get indices belonging to each node
#let idx0 = indices.filter(i => node.at(i) == 0)
#let idx1 = indices.filter(i => node.at(i) == 1)
#let idx2 = indices.filter(i => node.at(i) == 2)

// Helper: select array elements at given indices
#let sel(arr, idxs) = idxs.map(i => arr.at(i))

// Colors
#let c0 = rgb("#3366cc")  // blue
#let c-secondary = rgb("#dc3912")  // red


// ── 2. SF and TX Power over Time ─────────────────────────────────
#figure(
  lq.diagram(
    title: [Spreading Factor and TX Power over Time (simulation)],
    xlabel: [Time (s)],
    ylabel: [Parameter Value],
    width: 100%, height: 7cm,
    legend: (position: top),

    lq.plot(sel(time, idx0), sel(sf-used, idx0).map(x => float(x)),
      color: c0, mark: "o", mark-size: 2pt, step: end, label: [Spreading Factor]),
    
    lq.plot(sel(time, idx0), sel(txpow-used, idx0),
      color: c-secondary, mark: "s", mark-size: 2pt, label: [TX Power (dBm)]),
  ),
  caption: [Spreading factor and transmit power adaptation over time under PD control.],
) <fig:sim-params>


// ── 3. SNR with Target Reference ────────────────────────────────
#figure(
  lq.diagram(
    title: [SNR Tracking (simulation)],
    xlabel: [Time (s)],
    ylabel: [SNR (dB)],
    width: 100%, height: 7cm,
    legend: (position: top),

    lq.plot(sel(time, idx0), sel(snr, idx0),
      color: c0, mark: "o", mark-size: 2pt, label: [Measured SNR]),

    // SNR target as dashed reference line
    lq.plot(sel(time, idx0), sel(target, idx0),
      stroke: (paint: c0, dash: "dashed", thickness: 0.5pt), mark: none, label: [Target SNR]),
  ),
  caption: [SNR tracking performance showing measured SNR (solid) and target SNR (dashed). The PD controller adjusts TX power and SF to maintain SNR near the target.],
) <fig:sim-snr-tracking>
