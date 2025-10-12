s.boot;

// Synths
(
SynthDef(\triWave, {
    arg freq = 220.0, iphase = 0.0;
    var sig = LFTri.ar(freq: freq, iphase: iphase, mul: 1.0, add: 0.0);
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\sawWave, {
    arg freq = 220.0, iphase = 0.0;
    var sig = LFSaw.ar(freq: freq, iphase: iphase, mul: 1.0, add: 0.0);
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\pulseWave, {
    arg freq = 220.0, iphase = 0.0, width = 0.5;
    var sig = LFPulse.ar(freq: freq, iphase: iphase, width: width, mul: 1.0, add: 0.0);

    Out.ar(0, sig ! 2);
}).add;
)

// funktion
(
~playWave = { |name, args = #[]|
    ~current.free;             // stoppa pågående
    ~current = Synth(name, args);
};
)

// PLAY
~playWave.(\triWave);
~playWave.(\sawWave);
~playWave.(\pulseWave);
~playWave.(\pulseWave, [\freq, 220, \width, 0.2]);
~playWave.(\pulseWave, [\freq, 220, \width, 0.9]);
~playWave.(\pulseWave, [\freq, 220, \width, 1]);
~playWave.(\pulseWave, [\freq, 220, \width, 0]);


// Byt till 440Hz
~current.set(\freq, 440);

// STOP
~current.free;
s.stop;
s.freeAll;
