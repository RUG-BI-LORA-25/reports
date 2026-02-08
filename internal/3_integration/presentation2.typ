#import "@preview/polylux:0.4.0": *

#set page(paper: "presentation-16-9")
#set text(size: 25pt, font: "Agave Nerd Font")

#show link: it => underline(text(fill: blue, it))

#slide[
  #set align(horizon)
  = Progress report: Implementation & Integration
  Boyan & Mihai

  #datetime.today().display()
]

#slide[
  = LoRaWAN with RadioLib
  - Decided to use *RadioLib* for MAC layer to not reinvent the wheel
  - ABP activation over SX1278 on our custom PCB (and untested OTAA)
  - Full uplink/downlink cycle through our HackRF SDR gateway
  - Stack: Node $arrow.r$ HackRF (SDR) $arrow.r$ ChirpStack $arrow.r$ MQTT
]

#slide[
  = Channel access: a very primitive TDMA
  - No hardware clock sync between nodes
  - Simple slotted schedule: each node assigned a fixed offset
  $ t_"tx" = t_0 + n dot T_"interval" + "slot" dot T_"interval" / N_"slots" $
  - Currently $T_"interval" = 60$s, $N_"slots" = 2$
  - Rudimentary but works -- nodes must be started roughly together
]

#slide[
  = Proportional-Derivative controller
  #set text(size: 22pt)
  Per-node PD loop controlling TX power and spreading factor:
  $ e_k = "SNR"_"target"("SF") - "SNR"_"measured" $
  $ Delta P = K_p dot e_k + K_d dot (e_k - e_(k-1)) $
  Parameters: $K_p = 0.5$, $K_d = 0.1$, $P in [2, 17]$ dBm

  - If link is stressed ($"SNR" < "target"$) $arrow.r$ #text(fill: rgb("#b91c1c"))[SF $arrow.t$], TX $arrow.r P_"max"$
  - Else for $>=3$ consecutive frames $arrow.r$ #text(fill: rgb("#15803d"))[SF $arrow.b$]
  
  #v(0.5em)
  #slide[
    = PD controller: Examples
    #set text(size: 22pt)
    
    *Example 1:* SF7, target SNR = 7.5 dB, measured = 5 dB, prev error = 0
    $ e = 7.5 - 5 = 2.5 arrow.r Delta P = 0.5 dot 2.5 + 0.1 dot (2.5 - 0) = 1.5 "dBm" $
    
    
    *Example 2:* SF8, target SNR = 5 dB, measured = 0 dB
    $ e = 5 - 0 = 5 arrow.r "SNR < target (stress)" arrow.r #text(fill: rgb("#b91c1c"))[SF $arrow.t$ to SF9], P arrow.r P_"max" $
    PD state reset#footnote[
      // what does state reset mean
      Resets the error term $e$ to 0
    ]: $e_(k-1) := 0$, start optimising from $P = 17$ dBm


  ]
]

#slide[
  = System architecture
  #set text(size: 22pt)
  #set align(horizon)
  $ "Node" arrow.r^"LoRa" "HackRF GW" arrow.r^"UDP" "ChirpStack" arrow.r^"MQTT" "PD Controller" arrow.r^"gRPC" "Downlink" $
  #v(0.5em)
  - Everything runs on a single HackRF -- *half-duplex, one channel*
  - This constraint shaped every design decision
]

#slide[
  = Node (STM32 + SX1278)
  #set text(size: 22pt)
  #grid(columns: (1fr, 1fr), column-gutter: 1em, align: (left + horizon, center + horizon),
    [
      - Custom PCB with BME280 sensor + SX1278 LoRa
  
  
      - #text(fill: rgb("#b91c1c"))[Single channel means collisions with >1 node]
      - #text(fill: rgb("#15803d"))[Primitive TDMA -- fixed time slots per node]
    ],
    image("board.png", width: 100%)
  )
]

#slide[
  = HackRF SDR Gateway
  #set text(size: 22pt)
  #grid(columns: (1fr, 1fr), column-gutter: 1em, align: (left + horizon, center + horizon),
    [
      - GNU Radio flowgraph: demod LoRa $->$ Semtech UDP
      - #text(fill: rgb("#b91c1c"))[Half-duplex -- can't RX and TX simultaneously]
      - #text(fill: rgb("#15803d"))[Pre-computed TX timing offset]
      - #text(fill: rgb("#b91c1c"))[No frequency hopping -- one channel only]
      - #text(fill: rgb("#15803d"))[ChirpStack configured for single-channel EU433]
      - #text(fill: rgb("#15803d"))[Scans SF7-12 for every packet to receive everything]
    ],
    image("hackrf.png", width: 100%)
  )
]

#slide[
  = ChirpStack Network Server
  #set text(size: 22pt)
  #grid(columns: (1fr, 1fr), column-gutter: 1em, align: (left + horizon, center + horizon),
    [
      - Standard LoRaWAN network server
      - Handles MAC layer, device management, data routing
      - #text(fill: rgb("#b91c1c"))[ADR commands use standard algorithm -- not ours]
      - #text(fill: rgb("#15803d"))[Disabled built-in ADR, our PD controller sends MAC commands directly via gRPC API]
      - Publishes uplinks over MQTT for our controller to consume
    ],
    image("chirpstack.png", width: 100%)
  )
]

#slide[
  = PD Controller
  #set text(size: 22pt)
  #grid(columns: (1fr, .7fr), column-gutter: 1em, align: (left + horizon, center + horizon),
    [
      - C library (`libalgo`) + Python wrapper
      - Subscribes to MQTT uplinks, computes commands, pushes via gRPC
      - Per-node state tracked with `uthash`
      - #text(fill: rgb("#b91c1c"))[Downlink only works ~50% of the time (half-duplex)]
      - #text(fill: rgb("#15803d"))[Controller is idempotent -- repeats commands until acknowledged]
      - #text(fill: rgb("#b91c1c"))[SF changes reset SNR baseline]
      - #text(fill: rgb("#15803d"))[Reset PD state on SF transition, start from $P_"max"$]
    ],
    image("pythoncpp.png", width: 50%)
  )
]

#slide[
  = Current status
  #set text(size: 22pt)
  - #text(fill: rgb("#15803d"))[End-to-end LoRaWAN uplink + downlink working]
  - #text(fill: rgb("#15803d"))[PD controller integrated and responding to uplinks]
  - #text(fill: rgb("#15803d"))[Two physical nodes running concurrently]
  - #text(fill: rgb("#15803d"))[OLED display on nodes showing live status]
  - #text(fill: rgb("#b91c1c"))[No field/performance results yet -- coming very soon]
]

#slide[
  = NS3 simulation
  #set text(size: 22pt)
  - Set up NS3 LoRaWAN simulation environment
  - #text(fill: rgb("#15803d"))[Uplink and downlink working -- almost complete]
  - We need to validate ADR algorithm at scale alongside field tests
]

#slide[
  = TODOs (done by Wednesday)
  #set text(size: 22pt)
  - Make TDMA reliable -- try sync mechanisms other than "start at the same time"
  - Collect results with the PD controller
  - Run NS3 simulations and compare with physical measurements
  - Update the final report
  
  #v(1fr)
  #text(size: 18pt, fill: gray)[
    _Note: development of the core system took priority over building
    baseline algorithms to compare against. Comparative results may be limited._
  ]
]

#slide[
  #set align(center + horizon)
  #text(size: 72pt, weight: "bold")[Demo!]
]
