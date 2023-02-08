# patch notes

watch the full video: [link]

## 1. one osc band

[video]

independent record & playback rates set up one-to-many relationship with any sound. with two playheads both duplicating the input signal, things can get dense quickly – rpls shines with a sparse input signal. a single voice becomes a symphony, with rpls adding the bassline and the treble, at rhythmic multiples & divitions of the source.

**input:** monophonic sine wave melody, synced to global clock

**key settings**
- clock mult: 4.0
- mix
  - vol 1: 0.5
  - vol 2: 1.0
- feedback
  - rec > rec: 0
  - 1 > rec: 0
  - 2 > rec: 0
- rates
  - rate rec: 1
  - rate 1: 2
  - rate 2: -1/2
- filter
  - hp: 0.21
  - lp: 0.6
  - q: 0.6


## 2. spiraling

[video]

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

## 3. circle of polyrhythms

[video]

variation of [spiraling](#2. spiraling), with an upward cascade at a ratio of 3/2. harmonies ascend in accordance with the circle of fifths while polyrythmic counterpoint begins at 3:2 and grows both faster & more complex with each additional feedback layer.

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
  - lp: 0.7. set brightness of pitch cascade.
  - q: 0.7. adjusts icyness

## 4. steam grains

[video]

with **clock mult** near-minimum, rpls traverses into the texural domain, forming a cloud of reipitched grains around the input signal. play with **clock mult** to affect grain size, and **fade** to effect pseudo-envelope quality & texture.

**input:** long envelope chords with noise

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

## 5. locked groove

[video]

[watch the full live set for cachedmedia]

the **freeze** button allows rpls to dip their toes into the varispeed looping universe 🔂. while playing with long delay lines, listen for just the right moment to jam K3 and loop the moment indefinitely. use rpls as a choppy rhymic base – add additional layers with a second looper, or keep adding on in rpls by increasing **rec -> rec** feedback to 1.0 and unfreezing tempararily to accept more layers of sound while retaining the current conent.

**key settings**
- clock mult: 4.0. decrease to subdivide loop.
- freeze: ON. toggle OFF to fade out or add additional layers, depending on **rec > rec**.
- mix
  - vol 1: 0.5
  - vol 2: 1.0
- feedback
  - rec > rec: 0. increase to 1 to retain loop while unfrozen.
  - 1 > rec: 0
  - 2 > rec: 0


## 6. backup dancers

[video]

in rhythmic scenarios, playing an instrument into rpls is almost like having a digital companion playing along with you at divisions & multiples of the tempo. try playing your instrument and matching up your tempo with that of rpls.

**input:** small plucked or percussive instrument

**key settings**
- clock mult: 1.0, or whatever tempo you're feeling
- mix
  - vol 1: 0.5
  - vol 2: 1.0
- feedback
  - rec > rec: 0.5
  - 1 > rec: 0
  - 2 > rec: 0
- rates
  - rate rec: 1
  - rate 1: 2
  - rate 2: -1/2

