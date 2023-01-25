# patch notes

## steam grains

with **clock mult** near-minimum, rpls traverses into the texural domain, forming a cloud of reipitched grains around the input signal. play with **clock mult** to affect grain size, and **fade** to effect pseudo-envelope quality & texture.

**input:** slow attack chords with lots of noise

**key settings**
- clock tempo: 120bpm. affects grain size.
- clock mult: low, 0.0 - 1.0. affects grain size, very expressive.
- fade: 0.01 - 0.04. grain "envelope", affects texture.
- mix
  - vol 1: 0.8
  - vol 2: 1.0
- feedback
  - rec > rec: mid, 0.5-0.77
  - 1 > rec: 0
  - 2 > rec: 0
- rates
  - rate rec: 1
  - rate 1: 2
  - rate 2: -1/2
- filter
  - hp: 0.25
  - lp: 0.5 - 0.7
  - q: high, 0.6. emphasizes texture.

## spiraling

subdivide & layer recent past arpeggiations and spiral upward. slight feedback from play head 2 (with a -2/1 ratio) creates an upward pitch & rhythm cascade by octaves, with playback direction flipping at each additional layer.

**input:** plucked synthesizer arpeggio, synced to global clock

**key settings**
- clock tempo: 48bpm
- clock mult: 1.0. increase to other whole number values to loop longer slices of the arp.
- mix
  - vol 1: 1.0
  - vol 2: 0.5
  - vol rec: 0.22
- rates. divide each rate by 2 to hear more recent, less layered slices of the past
  - rate rec: 2
  - rate 1: 1
  - rate 2: -4
- feedback
  - rec > rec: low, around 0.1
  - 1 > rec: 0
  - 2 > rec: very low, around 0.02. increase to raise the volume of octave pitch cascade.
- filter
  - hp: 0.25
  - lp: 0.7. set brightness of octave pitch cascade.
  - q: 0.6. adjusts icyness

## circle of polyrhythms

variation of [spiraling](#spiraling), with an upward cascade at the ratio of 3/2. harmonies ascend in accordance with the circle of fifths while polyrythmic counterpoint begins at 3:2 and grows both faster & more complex with each additional feedback layer.

**input:** plucked synthesizer arpeggio, synced to global clock

**key settings**
- clock tempo: 45bpm
- clock mult: 1.0. increase to other whole number values to loop longer slices of the arp.
- mix
  - vol 1: 1.0
  - vol 2: 0.5
  - vol rec: 0.22
- rates
  - rate rec: 2
  - rate 1: 3
  - rate 2: -2
- feedback
  - rec > rec: very low, around 0.01
  - 1 > rec: very low, around 0.05. increase to raise the volume of cascade.
  - 2 > rec: 0
- filter
  - hp: 0.25
  - lp: 0.7. set brightness of octave pitch cascade.
  - q: 0.7. adjusts icyness


