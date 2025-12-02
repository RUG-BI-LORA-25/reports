#import "@preview/polylux:0.4.0": *

#set page(paper: "presentation-16-9")
#set text(size: 25pt, font: "Montserrat")

#show link: it => underline(text(fill: blue, it))

#slide[
  #set align(horizon)
  = Progress report: Sensors
  Boyan & Mihai

  #datetime.today().display()
]

#slide[
  == The framework debacle
  #set text(size: 18pt)
  #table(
    columns: 2,
    align: horizon,
    inset: 6pt,
    stroke: 0.5pt,
    column-gutter: 12pt,
    [
      *Name*
    ],
    [
      *Comfort level*
    ],
    [
      Arduino
    ],
    [
      High: comfortable with C++ and Arduino.
    ],
    [
      CMSIS
    ],
    [
      Very low: can read examples and tweak small bits, but not comfortable writing code from scratch.
    ],
    [
      LibOpenCM3
    ],
    [
      Very low: only superficial familiarity with the API and build setup.
    ],
    [
      Standard Peripheral Library
    ],
    [
      No.
    ],
    [
      STM32Cube / HAL
    ],
    [
      Low-medium: can follow, but not fully understand, time-pressured in terms of learning (the manual is 2000+ pages).
    ],
  )
  #uncover(2)[
  #text(fill: red, size: 27pt)[
    *Opinions?*
  ]
]
]

#slide[
  == Our experience with the HAL
  #set text(size: 20pt)
  #v(20pt)
  - Initial experiments with STM32CubeMX generated code were promising.
  - We started hating the IDE very quickly.
  - Tried to move to VSCode + Makefile, but the HAL documentation is not great (especially for our capabilities).
  - Moved to PlatformIO for easier dependency management.
  - Realized we don't have enough time to learn about:
    - ARM Cortex-M architecture
    - STM32 peripherals
    - HAL API
  In that order, so we...
]

#slide[
  == ... switched to Arduino
  #set text(size: 20pt)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 20pt,
    align: (left, center),
    [
      #v(24pt)
      - Benefits:
        - Familiar environment. 
        - Lots of examples online.
        - Simple API for basic peripherals.
      - Downsides:
        - Less control over hardware.
        - Performance overhead.
        - Limited access to advanced features (debatable, can still use the HAL if needed).
    ],
    image("images/platformio.png", width: 75%)
    )
]

#slide[
  == Intermezzo -- The Sensor interface
  #v(15%)
  Looks like this:
  #set text(size: 20pt)
  #align(center)[
  ```cpp
  #include <Arduino.h>

  class Sensor {
  public:
      virtual bool begin() = 0;
      virtual auto data() = 0; // return type is sensor-specific struct
  };
  ```
  ]
  We call the `begin()` method in `setup()` and `data()` in `loop()`.
]

#slide[
  #set align(horizon)
  = Actual Progress
  :)
]

#slide[
  == BME280 sensor
  #set text(size: 20pt)
  #v(20pt)
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 20pt,
      align: (horizon, center),
      [
        - #link("https://github.com/adafruit/Adafruit_BME280_Library", "Adafruit BME280 library") used
        - Using I2C interface (SDA: PB9, SCL: PB8)
      ],
      image("images/bme280.png", width: 75%)
    )
  ]

// Photoresistor
#slide[
  == Photoresistor
  #set text(size: 20pt)
  #v(20pt)
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 20pt,
      align: (horizon, center),
      [
        - Simple voltage divider circuit used (10 k$Omega$ resistor to GND, photoresistor to VCC)
        - Analog reading from pin PA0
      ],
      image("images/photoresistor.png", width: 75%)
    )
  ]

// DHT11
#slide[
  == DHT11 sensor
  #set text(size: 20pt)
  #v(20pt)
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 20pt,
      align: (horizon, center),
      [
        - Just reading the digital pin (PC14)
      ],
      image("images/dht11.png", width: 75%)
    )
  ]


#slide[
  #set align(horizon)
  = We're ready for LoRa!
]