<h1 align="center">RPLS</h1>
<p align="center">
  <img src="https://raw.githubusercontent.com/andr-ew/rpls/v1/lib/doc/img/rpls.gif" alt="rpls screen animated gif. a triangle rotates on a black screen with dots represending tapeheads running across each edge of the triangle. the rpls main UI components surround the triangle, params: clk, vol1, vol2"/>
</p>
<br>

varispeed multitap echo. 3 taps (1 recording, 2 playing) cycle through 3 buffers. alter the rate of each playback tap independently from the record tap to create sliced rhythmic & harmonic counterpoint from the input signal in real-time, free from tape head collisions & audible clicks.

a spiritual successor to [alliterate](https://github.com/andr-ew/prosody#alliterate), inspired by strymon magneto.

currently in beta - any & all feedback is highly appreciated! feel free to create an issue here or send me an email andrewcshike@gmail.com :) (email is usually the best way to reach me). if you're running into trouble, be sure to check out the [issues](https://github.com/andr-ew/ndls/issues) section to see if your issue has already been logged ~

## hardware

**required**

- [norns](https://github.com/p3r7/awesome-monome-norns) (210927 or later)
- audio input

## install

```
~
```

## norns UI

### intro

![the triangle at the center of the rpls script. 3 dots on the edges are labelled 'rec head', 'play head 1', 'play head 2'. the rotating edges of the triangle are labelled 'buffers'. K2 & K3 are labelled](/lib/doc/img/rpls-02.png)

norns' keys are mapped in the top right:

- **K2:** increment page
- **K3:** freeze, buffers will loop the current contents. hold to clear.

the rotating triangle in the center of the screen illustrates the tape process powering rpls. each side of the triangle represents a buffer. one of the sides (dimly lit) is always having audio written to it by the record head. after writing to one side, the rec head cycles to the next one. at the same time, the two playheads are playing back the recorded material from the other two sides of the triangle. 

since the play heads never cross over the record head in the same buffer, they can play back recently recorded material at any speed & pitch without causing clicks.

### page `C`

![page C of rpls, E1-3 are labelled](/lib/doc/img/rpls-01.png)

- **E1:** clock multiple / division (**clock mult**). sets the rate at which tape heads cycle between buffers, measured in beats at the global clock tempo.
- **E3:** volume of playhead 1
- **E3:** volume of playhead 2

the **clock mult** param offers different windows into rpls depending on its use:
  - **low values, < 1:** pseudo-granular textures.
  - **mid values, 1 - 2:** chopped delay
  - **whole number values (1.0, 2.0...):** delay synced to the global clock
  - **large values, > 2:** chopped tape loops

### page `R`

![page R of rpls, E1-3 are labelled](/lib/doc/img/rpls-03.png)

- **E1:** rate of the record head
- **E3:** rate of play head 1
- **E3:** rate of pay head 2

rates 1 & 2 effectively set the _rate_, _pitch_, & _direction_ of playback for the playheads' repsective buffer slices. the actual playback rate of a playhead will always depend on the _ratio_ between that play head & the record head.

assuming **rate r = 1**, the following rhythmic & harmonic relationships are available:

| playback rate | pitch transposition | clock multiple/division |
| ---           | ---                 | ---                     |
| +- 1/2        | -1 octave           | 0.5x                    |
| +- 1          | unison              | 1x                      |
| +- 2          | +1 octave           | 2x                      |
| +- 3          | +1 octave + 5th     | 3x                      |
| +- 4          | +2 octaves          | 4x                      |
| +- 5          | +2 octaves + maj3rd | 5x                      |
| +- 6          | +2 octaves + 5th    | 6x                      |

with **rate > 1**, many more relationships are available, including common just-intonnation harmonies & polyrhythms:

| playback rate | record rate | pitch transposition | polyrhythm |
| ---           | ---         | ---                 | ---        |
| +- 3          | 2           | + 5th               | 3:2        |
| +- 4          | 3           | + 4th               | 4:3        |
| +- 2          | 3           | - 4th               | 2:3        |
| +- 5          | 4           | + maj 3rd           | 5:4        |
| +- 3          | 4           | - 5th               | 3:4        |
| +- 6          | 5           | + min 3rd           | 6:5        |
| +- 4          | 5           | - min 3rd           | 4:5        |

((pls let me know if I got any of this wrong, lol))

note that the range of **rate 1** on the negative side has been reduced to prevent collisions with the adjacent record head. 

### page `>`

![page > of rpls, E1-3 are labelled](/lib/doc/img/rpls-04.png)

- **E1:**
- **E3:**
- **E3:**

### page `F`

![page F of rpls, E1-3 are labelled](/lib/doc/img/rpls-05.png)

- **E1:**
- **E3:**
- **E3:**

## additional params
