#import "@preview/polylux:0.4.0": *

#set page(paper: "presentation-16-9")
#set text(size: 25pt, font: "Montserrat")

#show link: it => underline(text(fill: blue, it))

#slide[
  #set align(horizon)
  = Progress report: PCB and Simulation
  Boyan & Mihai

  #datetime.today().display()
]

#slide[
  = Practical matters: The LoRa module
  #align(center)[#text(fill: red)[STM32 LoRa hats are no longer manufactured]]
  #v(1em)
  - Their documentation is lacklustre anyway
  - So what module?
    - RA-0nH? Created by Semtech. Guaranteed to work.
    - Waveshare module? Good docs, easy to approach. Not trivial for PCB design though...
    - ESP32 board? Fully functional and trivial, but very overkill. Also expensive.
]
#slide[
  = The solution
  #set align(horizon)
  #grid(
    columns: (1fr, auto),
    align: (left, center),
    [
      We have designed our very own PCB to house all of the required sensors and LoRa components. We will be using our own inventory of screens.
    ],
    image("assets/pcb.png", width: 60%)
  )
]

#slide[
  #text(size:100pt)[INSERT CASE HERE]
]

#slide[
  = Simulation setup
  #set align(horizon)
  #set text(size: 50pt)
  #image("assets/chirpstack.png") +
  #link("https://github.com/UniCT-ARSLab/LWN-Simulator", "LWN-Simulator")

]

#slide[
  = Dashboard
  
  #set align(horizon+center)
  #image("assets/screen1.png", width: 80%)
]

#slide[
  #set align(horizon+center)
  #image("assets/screen2.png", width: 80%)
  Find on #link("lora.cartof.io")
]

#slide[
  = Miscellaneous News
  We've already started to write documentation about our process, in order to avoid having to do a lot of work towards the end of the project. Let us know if you'd like to be included in the organization!
]