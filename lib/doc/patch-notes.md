# patch notes

## spiral

subdivide & layer recent past arpeggiations and spiral upward. slight feedback from play head 2 (with a -2/1 ratio) creates an upward pitch & rhythm cascade by octaves, with playback direction flipping at each additional layer.

**input:** plucked synthesizer arpeggio, synced to global clock

**key settings**
- clock tempo: 48bpm
- rates. divide each rate by 2 to hear more recent, less layered slices of the past
  - rate rec: 2x
  - rate 1: 1x
  - rate 2: -4x
- clock mult: 1.0. increase to other whole number values to loop longer slices of the arp.
- feedback
  - rec > rec: low, around 0.1
  - 1 > rec: 0
  - 2 > rec: very low, around 0.02. increase to raise the volume of octave pitch cascade.
- mix
  - vol 1: 1.0
  - vol 2: 0.5
  - vol rec: 0.22
- filter
  - hp: 0.25
  - lp: 0.7. set brightness of octave pitch cascade.
  - q: 0.6. adjusts icyness

## circle of polyrhythms

variation of [spiral](#spiral), with an upward cascade at the ratio of 3/2. harmonies ascend in accordance with the circle of fifths while polyrythmic counterpoint begins at 3:2 and grows both faster & more complex with each additional feedback layer.

**input:** plucked synthesizer arpeggio, synced to global clock

**key settings**
- clock tempo: 45bpm
- rates
  - rate rec: 2x
  - rate 1: 3x
  - rate 2: -2x
- clock mult: 1.0. increase to other whole number values to loop longer slices of the arp.
- feedback
  - rec > rec: very low, around 0.01
  - 1 > rec: very low, around 0.05. increase to raise the volume of cascade.
  - 2 > rec: 0
- mix
  - vol 1: 1.0
  - vol 2: 0.5
  - vol rec: 0.22
- filter
  - hp: 0.25
  - lp: 0.7. set brightness of octave pitch cascade.
  - q: 0.7. adjusts icyness


