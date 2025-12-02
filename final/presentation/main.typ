#import "@preview/polylux:0.4.0": *

#set page(paper: "presentation-16-9")
#set text(size: 25pt, font: "Montserrat")

#show link: it => underline(text(fill: blue, it))

#slide[
  #set align(horizon)
  = LoRaWan testing NAME WIP
  #line(length: 100%)
  Boyan & Mihai
  #text(fill: gray, style: "italic")[=== Bachelor Internship 2025]

  #datetime.today().display()
]
