<h1 align="center">RPLS</h1>
<p align="center">
  <img src="https://raw.githubusercontent.com/andr-ew/rpls/v1/lib/doc/img/rpls.gif" alt="rpls screen animated gif. a triangle rotates on a black screen with dots represending tapeheads running across each edge of the triangle. the rpls main UI components surround the triangle, params: clk, vol1, vol2"/>
</p>
<br>

varispeed multitap echo. 3 taps (1 recording, 2 playing) cycle through 3 buffers. alter the rate of each playback tap independently from the record tap  to create sliced rhythmic & harmonic counterpoint from a single input signal, free of tape head collisions & audible clicks.

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

![the triangle at the center of the rpls script. 3 dots on the edges are labelled 'rec head', 'play head 1', 'play head 2'. the rotating edges of the triangle are labelled 'buffers'. K2 & K3 label the page & freeze controls](/lib/doc/img/rpls-02.png)

norns' keys are mapped in the top right:

- **K2**: increment page
- **K3**: freeze, buffers will loop the current contents. hold to clear.

the rotating triangle in the center of the screen illustrates the tape process powering rpls. each side of the triangle represents a buffer. one of the sides (dimly lit) is always having audio written to it by the record head. after writing to one side, the rec head cycles to the next one. at the same time, the two playheads are playing back the recorded material from the other two sides of the triangle. 

since the play heads never cross over the record head in the same buffer, they can play back recently recorded material at any speed & pitch without causing clicks.

### page `C`

### page `R`

### page `>`

### page `F`


## additional params
