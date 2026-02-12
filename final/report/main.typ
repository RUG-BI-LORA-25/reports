#import "@preview/charged-ieee:0.1.4": ieee
#import "@preview/cetz:0.3.2": canvas, draw
#import "@preview/dashy-todo:0.1.3": todo

#let td = (..args) => text(size: 0.6em)[#todo(stroke: blue, ..args)]
#let gpt(body) = block(
  inset: 1pt,
  // fill: rgb("#ffdfdf"),
  // [#text(size: 7pt, fill: red, weight: "bold")[SLOP]#linebreak()#body]
  [#body]

)

#show: ieee.with(
  title: [LoRaWAN Network Implementation and Optimization],
  
  abstract: [
    // #td[this is terrible and sounds way too AI'd]
    This report presents the design and evaluation of a single-channel LoRaWAN network optimized for throughput and energy efficiency. We describe our experimental setup and investigate strategies for adaptive spreading factor allocation and transmit power control in the presence of inter-node interference utilizing Proportional-integral-derivative (PID) control. Our results demonstrate that careful parameter tuning can significantly improve performance in constrained single-channel scenarios.
  ],
  authors: (
    (
      name: "B. Karakostov",
      department: [S5230837],
      organization: [University of Groningen],
      location: [Groningen, Netherlands],
      email: "b.karakostov@student.rug.nl"
    ),
    (
      name: "M. David",
      department: [S5528984],
      organization: [University of Groningen],
      location: [Groningen, Netherlands],
      email: "m.david.5@student.rug.nl"
    ),
    (
      name: "R. Zare Hassanpour",
      department: [Project Supervisor],
      organization: [University of Groningen],
      location: [Groningen, Netherlands],
      email: "r.zare.hassanpour@rug.nl"
    )
  ),
  bibliography: bibliography("refs.yml", style: "ieee")
)
// #td[no index-terms, do we need them?]

= Introduction
LoRaWAN (Long Range Wide Area Network) is a low-power wide-area network protocol designed for wireless battery-operated devices in regional, national, or global networks. Built on top of the LoRa (Long Range) physical layer modulation, LoRaWAN defines the communication protocol and system architecture, while LoRa itself handles the physical layer that enables long-range links.

The technology operates in unlicensed ISM (Industrial, Scientific, and Medical) radio bands -- typically 868 MHz (EU868) and 433 MHz (EU433) in Europe, 915 MHz in North America, and 433 MHz in Asia. In this work we focus on the 433 MHz band.

LoRaWAN@lorawan-spec is well suited for Internet of Things (IoT) applications because it provides:
- Long-range communication, enabled by LoRa's chirp spread spectrum modulation;
- Low power consumption, thanks to optimized sleep modes and minimal transmission overhead;
- Secure communication via end-to-end AES-128 encryption as required by the specification.

The architecture follows a star-of-stars topology: end devices (sensors/actuators) communicate directly with gateways, which relay messages to a central network server over standard IP. This avoids complex multi-hop routing and simplifies network management.

An important feature of LoRaWAN is the use of multiple spreading factors (SF7-SF12), which trade off data rate for range and robustness. In a production deployment, multi-channel gateways based on the Semtech SX1301/SX1302 concentrator can receive on several SFs and channels simultaneously. However, many low-cost or experimental setups rely on single-channel gateways, which can only listen on one SF and one frequency at a time. This severely limits throughput and makes the choice of transmission parameters critical -- a problem this work directly addresses.

LoRaWAN defines three device classes with different capabilities and power profiles, summarized in Table 1.

#figure(
  table(
    columns: 4,
    align: (left, left, left, left),
    table.header(
      [*Class*], [*Receive Windows*], [*Power Consumption*], [*Use Cases*]
    ),
    [Class A], [Two short windows after each uplink], [Lowest], [Battery-powered sensors],
    [Class B], [Class A + scheduled receive slots], [Medium], [Actuators with predictable downlink],
    [Class C], [Continuous (except when transmitting)], [Highest], [Mains-powered devices, low-latency applications],
  ),
  caption: [LoRaWAN Device Classes]
)

#gpt[
Class A devices offer the lowest power consumption and are most suitable for battery-operated sensors. Class B devices enable more predictable downlink latency through time-synchronized beacons. Class C devices provide minimal latency but require continuous power supply.
]

The protocol uses several algorithms(notably Adaptive Data Rate -- ADR) to optimize transmission parameters including spreading factor, bandwidth, and transmission power based on conditions. Spreading factors range from SF7 (fastest data rate, shortest range) to SF12 (slowest data rate, longest range). Table 2 shows the characteristics of each.
#figure(
  table(
    columns: 5,
    align: (center, center, center, center, left),
    table.header(
      [*SF*], [*Data Rate\ (bps)*], [*Sensitivity\ (dBm)*], [*Relative\ Range*], [*Characteristics*]
    ),
    [SF7], [5470], [-123], [1×], [Fastest, shortest range, lowest ToA],
    [SF8], [3125], [-126], [1.4×], [Balanced speed and range],
    [SF9], [1760], [-129], [2×], [Good compromise for urban areas],
    [SF10], [980], [-132], [2.8×], [Reliable for medium-long range],
    [SF11], [440], [-134.5], [4×], [Long range, high reliability],
    [SF12], [250], [-137], [5.6×], [Maximum range, highest ToA],
  ),
  caption: [LoRa Spreading Factor Characteristics (125 kHz bandwidth, EU868)]
)
// #td[these are EU868 numbers but we use 433 MHz]

= Motivation
In a standard multi-channel deployment, gateways can receive on multiple SFs and frequencies concurrently, so parameter allocation is relatively forgiving. On a single-channel gateway, however, all nodes must share one frequency and typically one SF at any given time, making collisions far more likely and parameter choices far more consequential. When multiple nodes transmit on the same channel, inter-node interference degrades signal quality, causing packet loss, retransmissions, and increased energy consumption.

This work focuses on that constrained scenario: a small multi-node LoRaWAN network operating over a single channel. The central question is: *how can we maximize data throughput while minimizing energy consumption when all nodes share a single receive channel and inter-node interference is unavoidable?*

= Related Work
Several studies have examined LoRaWAN performance and the impact of parameter selection. Magrin et al.@magrin-lorawan provide a thorough analysis of how different LoRaWAN parameter settings: spreading factor, bandwidth, coding rate, and transmission power, affect network performance metrics such as packet delivery ratio, energy consumption, and fairness. Their simulation-based study highlights the strong interdependence between these parameters and the difficulty of finding a single optimal configuration.

Lavric and Popa@lavric-scalability evaluate LoRaWAN scalability in large-scale wireless sensor networks, showing that alongside node density increases, collision rates grow significantly, particularly when all nodes use the same spreading factor. These results underline the need for intelligent SF allocation strategies in dense deployments.

On the energy side, de Andrade et al.@andrade-battery propose a dynamic SF reallocation strategy that accounts for the battery levels of individual nodes. By periodically redistributing SF assignments across the network, their approach reduces collisions between same-SF transmissions and extends overall network lifetime. This is directly relevant to our work, as we also aim to balance SF diversity against energy efficiency.

Kamarudin et al.@kamarudin-review present a broader review of LoRaWAN performance, covering indoor and outdoor scenarios, and identify key open issues including interference management, adaptive data rate behavior, and gateway capacity limitations. Their work provides context for understanding where single-channel setups fall short compared to multi-channel concentrators.

#gpt[
Our work builds on these findings by focusing specifically on the single-channel case, where the trade-offs identified in the literature become even more pronounced. Rather than relying on simulation alone, we implement a real hardware testbed using an SDR-based gateway for full control over the physical layer.
]
= Experimental Setup
== Objectives
#gpt[
We investigate how a three-node LoRa network can optimize the trade-off between data rate and energy consumption by employing adaptive transmit power control combined with dynamic spreading factor (SF) allocation. Each node will adjust its transmit power based on gateway feedback of the received signal-to-noise ratio (SNR), using a PID-based control loop to maintain reliable communication while minimizing energy use. Simultaneously, the network will leverage SF diversity and coordinated timing to mitigate interference between nodes, allowing high-SF nodes to operate at lower power and low-SF nodes to maintain higher data rates. The study aims to develop and evaluate strategies that dynamically balance throughput, energy efficiency, and interference management in a small multi-node LoRa network, providing insights for scalable, energy-conscious IoT deployments.
]

== Network Hierarchy
Our setup implements the standard LoRaWAN star-of-stars topology, illustrated in @fig:net_topology. This architecture consists of end devices communicating directly with a central gateway via LoRa modulation, while the gateway connects to backend servers through standard IP networking (UDP).
#figure(
  canvas(length: 0.6cm, {
    import draw:  *
    
    // End devices with labels below
    circle((0, 0), radius: 0.4, name: "node1")
    content((0, -0.9), text(size: 6pt)[Node 1])
    
    circle((2, -1.5), radius: 0.4, name: "node2")
    content((2, -2.4), text(size: 6pt)[Node 2])
    
    // Gateway
    rect((5.5, -0.5), (7.5, 0.5), name: "gw")
    content((6.5, -1), text(size: 6pt)[HackRF Gateway])
    
    // Network Server
    rect((9, -0.5), (11, 0.5), name: "ns")
    content((10, -1), text(size: 6pt)[Chirpstack])
    
    // Connections
    line((0.4, 0), (5.5, 0), stroke: (dash: "dashed"))
    line((2.3, -1.3), (5.5, -0.3), stroke: (dash: "dashed"))
    line((7.5,0), (9, 0))
  }),
  caption: [Network Topology]
) <fig:net_topology>
== Hardware Configuration
#gpt[
Our experimental setup consists of multiple components forming a complete LoRaWAN network. The gateway uses a software-defined radio (SDR) approach, giving us low-level control over the LoRa physical layer.
]

=== Nodes
// #td[photo?]
STM32F401RE microcontroller with a hat(as shown in the GitHub repository@pcb), consisting of:
- SX1278 LoRa transceiver module operating at 433 MHz;
- BME280 environmental sensor (temperature, humidity, pressure);
- Standard photoresistor for light measurement;
- An SSD1306 OLED screen for display.

=== Gateway
Our gateway is built around a HackRF One@hackrf software-defined radio (SDR), controlled via GNU Radio and the `gr-lora_sdr`@gr-lora-sdr@gr-lora-sdr-updated@gr-lora-sdr-repo out-of-tree module. Unlike traditional single-channel gateways (e.g., ESP32-based), the HackRF approach gives us full control over the physical layer, letting us tune parameters like spreading factor, bandwidth, and sample rate at runtime.

The gateway software stack consists of:
- _GNU Radio flowgraph (Python)_: handles LoRa modulation/demodulation via `gr-lora_sdr` blocks and interfaces with the HackRF through `gr-osmosdr`;
- _Packet Forwarder_: implements the Semtech UDP packet forwarder protocol to relay received packets to ChirpStack;
- _Transmitter_: handles downlink by encoding and modulating LoRaWAN frames for transmission via the HackRF.

The whole system is containerized using Docker, with `gr-lora_sdr` built from source in a multi-stage build.
// #td[maybe mention the docker setup briefly? perhaps not]

==== Receiver chain
@fig:rx_flowchart shows the GNU Radio Companion schematic of the receive chain. The actual implementation lives in `receiver.py`@code, where the flowgraph is constructed programmatically. The signal path is:

$ &"HackRF Source"\ &-> "Frame Sync" -> "FFT Demod" -> "Gray Demapping" \
&-> "Deinterleaver" -> "Hamming Dec." -> "Header Dec." \
&-> "Dewhitening" -> "CRC Verify" -> "Packet Sink" $

The `Frame Sync` block locks onto the LoRa preamble and synchronizes with the incoming chirps. After demodulation and decoding, packets are passed to a custom `LoRaPacketSink` block that forwards them to the packet forwarder via a callback. The oversampling factor is computed as $S_r / B_w$, and the minimum buffer size is set to $ceil(S_r / B_w dot 2^("SF") + 2)$, as each LoRa symbol spans $2^("SF")$ samples at a given bandwidth (and the +2 is a magic number).

===== SNR and RSSI Estimation
The `frame_sync` block has an optional second output port (type `float32`) that, when connected, enables per-packet SNR estimation from the preamble. Internally, the block dechirps each preamble upchirp by multiplying with the ideal downchirp, takes the FFT, and computes:

$ "SNR" = 10 log_10 (E_"peak" / (E_"total" - E_"peak")) $

where $E_"peak"$ is the energy in the strongest FFT bin and $E_"total"$ is the total energy across all bins. The estimate is averaged over all usable preamble symbols. The block produces five floats per frame on port 1: SNR, CFO, STO, SFO, and an off-by-one indicator. A lightweight `SyncLogSink` block captures these values per SF chain.

Since the HackRF One is not a calibrated receiver, absolute RSSI cannot be measured directly. Instead, we derive it from the SNR estimate and the receiver noise floor. The noise floor of any receiver is:

$ N_"floor" = N_0 |_("dBm/Hz") + 10 log_10 (B_w) + "NF" $
For our configuration ($B_w = 125 "kHz"$, $"NF" = 11 "dB"$), this gives $N_"floor" approx -112 "dBm"$. The noise figure is the only device-specific parameter and is configurable via an environment variable. RSSI is then:

$ "RSSI" = N_"floor" + "SNR" $

#figure(
  image("assets/receiver.pdf", width: 100%),
  caption: [GNU Radio Companion schematic of the LoRa receive chain]
) <fig:rx_flowchart>

==== Transmitter chain
@fig:tx_flowchart shows the transmit chain schematic. Again, the real implementation is in `transmitter.py`@code. The signal path mirrors the receiver in reverse:

$ "Whitening" &-> "Header" -> "Add CRC" \
&-> "Hamming Enc." -> "Interleaver" \
&-> "Gray Demap" -> "Modulate" \
&-> "HackRF Sink" $

Downlink packets arrive as raw bytes from ChirpStack (via `PULL_RESP`), get wrapped as PMT messages, and are posted to the whitening block's input port. The transmitter starts the flowgraph, waits for the frame to be fully transmitted, and then stops.

#figure(
  image("assets/transmitter.pdf", width: 100%),
  caption: [GNU Radio Companion schematic of the LoRa transmit chain]
) <fig:tx_flowchart>

==== Packet Forwarder
The packet forwarder bridges the GNU Radio flowgraph and ChirpStack. It implements the Semtech UDP protocol@semtech-udp (PUSH_DATA, PULL_DATA, PULL_RESP, etc.) and formats received packets as `rxpk` JSON objects with the appropriate metadata (frequency, data rate string like `SF12BW125`, RSSI, SNR). It also handles downlink scheduling by listening for `PULL_RESP` messages and routing them to the transmitter.

==== Multi-SF / Multi-BW Reception
We run multiple parallel receiver chains, each tuned to a different spreading factor, sharing the same HackRF source. Since LoRa spreading factors are orthogonal#footnote[
  Each SF corresponds to a different chirp rate, so signals with different SFs do not interfere with each other.
]
, a single capture can be split into multiple demodulation pipelines. This mitigates the single-channel limitation by allowing simultaneous reception of packets transmitted with different SFs.


==== Half-Duplex Operation
The HackRF One cannot receive and transmit at the same time (its half-duplex), so when ChirpStack wants to send a downlink the packet forwarder has to stop the receiver, spin up the transmitter, wait for the frame to go out, and restart the receiver. We compensate for the timing with a configurable timestamp offset (`TMST_OFFSET_US`, set to 2.5 s by default) that accounts for GNU Radio pipeline and HackRF USB buffering latency, so the downlink RF signal actually shows up when the node's RX window is open. On the node side, RX1 opens 5.5 s after TX and RX2 at 7.5 s, with a 250 ms scan guard.

==== Network Server
We run ChirpStack v4@code as the network server, deployed in Docker alongside PostgreSQL 14, Redis 7, Mosquitto 2 (MQTT broker), and the ChirpStack Gateway Bridge. The gateway bridge is set up for the EU433 band with MQTT topics prefixed by `eu433/`. ChirpStack does device management, packet deduplication, MAC commands, and data routing. The built-in ADR is disabled, as our PD controller sends data rate and power commands through the ChirpStack gRPC API instead.

==== Simulation
For testing at larger scale than our physical setup allows, we set up an ns-3 simulation environment with the LoRaWAN module from Magrin et al.@magrin-lorawan (`signetlabdei/lorawan`). The `setup.sh` script clones ns-3, grabs the LoRaWAN module and builds with examples and tests. This lets us compare our physical measurements with simulation results.

== Methodology

=== Channel Access: Slotted TDMA
Since all nodes share one frequency channel, if two transmit at the same time a collision will arise. To avoid this we use a simple TDMA scheme. Each node gets a fixed slot index $s in {0, 1, ..., N_"slots" - 1}$, and the $n$-th uplink from node $s$ happens at:

$ t_"tx" (s, n) = t_0 + n dot T_"interval" + s dot T_"interval" / N_"slots" $

Right now $T_"interval" = 60$ s and $N_"slots" = 2$. The slot offset is computed at compile time:

$ "TDMA_SLOT_OFFSET_MS" = T_"interval" / N_"slots" times s $

Each node is offset by 30 seconds from the other, which leaves enough time for the uplink, both RX windows, and processing. There is no hardware clock sync -- the nodes need to be started roughly at the same time, and the fixed-interval loop in the firmware keeps things lined up. We have not encountered any collisions with this setup.

=== PD-Based Transmit Power and Spreading Factor Control
Instead of using ChirpStack's built-in ADR, we wrote our own PD (proportional-derivative) control loop that adjusts each node's TX power and spreading factor independently. The controller is a C shared library (`libalgo.so`) called from a Python wrapper (`wrapper.py`). The wrapper subscribes to uplink events over MQTT and pushes downlink commands through the ChirpStack gRPC API.

==== Per-Node State
The controller keeps track of each node's state in a hash table (using `uthash`):
- Current spreading factor $"SF" in [7, 12]$, starts at SF7;
- Current TX power $P in [2, 17]$ dBm, starts at 14 dBm;
- Previous error $e_(k-1)$, starts at 0;
- Stability counter -- how many frames in a row the node has had excess margin at minimum power.

==== SNR Target
Each spreading factor needs a different minimum SNR to demodulate reliably. We use these targets:

#figure(
  table(
    columns: 7,
    align: center,
    table.header([*SF*], [7], [8], [9], [10], [11], [12]),
    [*Target SNR (dB)*], [$-7.5$], [$-10.0$], [$-12.5$], [$-15.0$], [$-17.5$], [$-20.0$],
  ),
  caption: [SNR demodulation targets per spreading factor]
)

==== Control Law
When an uplink arrives, the gateway has already estimated the SNR from the preamble (see SNR and RSSI Estimation above). The error signal is:

$ e_k = "SNR"_"target"("SF") - "SNR"_"measured" $

Positive error means the link is weaker than desired, negative means there is extra margin. The PD law gives us a power adjustment:

$ Delta P = K_p dot e_k + K_d dot (e_k - e_(k-1)) $

with $K_p = 0.5$ and $K_d = 0.1$. We quantize to 2 dBm steps (what the SX1278 supports) and clamp to the allowed range:

$ P_(k+1) = "clamp"(P_k + "round"(Delta P \/ 2) dot 2, thin P_"min", thin P_"max") $

==== SF Escalation and De-Escalation
We provide a heuristic that manages SF changes:

- _SF goes up (link stressed):_ If measured SNR is below target, or even at max power the SNR margin would still be less than a comfort threshold ($C = 10$ dB), we increase SF up by one, set TX power back to $P_"max"$, and reset the PD state (previous error and stability counter go to zero). This lets the controller start fresh at the more robust config.

- _SF goes down (too much margin):_ If the error exceeds a margin threshold ($M = 5$ dB) and TX power has already been at $P_"min"$ for at least $W = 3$ frames in a row, we drop SF by one. Power gets reset to $P_"max"$ again and PD state is cleared, so the controller can re-converge at the faster data rate.


==== Closed-Loop Integration
The full loop can be summarized as follows (see @fig:control_loop):

+ Node transmits sensor data over LoRa.
+ HackRF gateway demodulates and sends the packet (with RSSI/SNR) to ChirpStack via UDP.
+ ChirpStack publishes the uplink to the MQTT broker.
+ Python wrapper gets the MQTT message, pulls out RSSI and SF, converts to internal DR ($"DR" = 12 - "SF"$), calls the C `pid()` function.
+ The result (new DR and TX power) gets packed as 8 bytes ($2 times "int32"$, little-endian) and enqueued as a downlink on FPort 2 through ChirpStack's gRPC API. Any old queued downlinks get flushed first so the node always gets the latest command.
+ Node receives the downlink, unpacks the `State` struct, and calls `lora.reBegin(params)` which updates the target DR. Takes effect on the next uplink.

#figure(
  canvas(length: 0.55cm, {
    import draw: *
    
    rect((0, -0.4), (2.5, 0.4), name: "node")
    content((1.25, 0), text(size: 5pt)[Node])
    
    rect((4, -0.4), (7, 0.4), name: "gw")
    content((5.5, 0), text(size: 5pt)[HackRF GW])
    
    rect((8.5, -0.4), (11.5, 0.4), name: "cs")
    content((10, 0), text(size: 5pt)[ChirpStack])
    
    rect((13, -0.4), (16, 0.4), name: "pd")
    content((14.5, 0), text(size: 5pt)[PD Controller])
    
    line((2.5, 0.2), (4, 0.2), mark: (end: ">"))
    content((3.25, 0.7), text(size: 4pt)[LoRa])
    
    line((7, 0.2), (8.5, 0.2), mark: (end: ">"))
    content((7.75, 0.7), text(size: 4pt)[UDP])
    
    line((11.5, 0.2), (13, 0.2), mark: (end: ">"))
    content((12.25, 0.7), text(size: 4pt)[MQTT])
    
    line((13, -0.2), (11.5, -0.2), mark: (end: ">"))
    content((12.25, -0.7), text(size: 4pt)[gRPC])
    
    line((8.5, -0.2), (7, -0.2), mark: (end: ">"))
    content((7.75, -0.7), text(size: 4pt)[UDP])
    
    line((4, -0.2), (2.5, -0.2), mark: (end: ">"))
    content((3.25, -0.7), text(size: 4pt)[LoRa DL])
  }),
  caption: [Closed-loop control: uplink path (top), downlink path (bottom)]
) <fig:control_loop>

= Results
// Results pending -- data collection from PD controller evaluation and ns-3 simulations in progress.

= Discussion
// Discussion pending results.

= Limitations & Future Work
There are a few limitations with what we have so far.

Since the HackRF cannot RX and TX at the same time, sending downlinks means we have to stop receiving. Combined with LoRaWAN's narrow RX windows (especially at high SFs where packets take a long time), we have hardcoded a $approx 15$ second delay in the loop. We also altered the underlying `RadioLib` to support this.  The PD controller deals with this by always flushing old commands and sending the latest state, but it still slows down how fast the control loop converges.

Our TDMA scheme uses fixed slot assignments set at compile time with no clock sync. Works fine for two nodes, but scaling up would need some kind of dynamic slot allocation, maybe coordinated through downlink MAC commands.

The controller is PD, not PID -- there's no integral component, which means it cannot fully eliminate steady-state error. 

We tested with two physical nodes even though the original plan was three. A third node would stress-test the TDMA scheme more and give us better data on interference.

= LLM Transparency
Parts of this project involved large language model assistance:
- This report was produced (structured and checked) with the help of Claude Opus 4.6 (Anthropic).
- The TDMA logic and transmission chain implementation were heavily assisted by Claude Opus 4.6.