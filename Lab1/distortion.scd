s.boot;

// Synth med hård clip
(
SynthDef(\clipDistortion, {
    arg freq = 220, amp = 0.5;
    var sig;

    sig = SinOsc.ar(freq, mul: amp);

    // Hård klippning mellan -0.5 och 0.5
    sig = sig.clip(-0.5, 0.5);
    Out.ar(0, sig ! 2);
}).add;

// Synth med mjuk clip
SynthDef(\softDistortion, {
    arg freq = 220, amp = 0.5;
    var sig;

    sig = SinOsc.ar(freq, mul: amp);

    // Mjuk klippning
    sig = sig.softclip(-0.5, 0.5);
    Out.ar(0, sig ! 2);
}).add;
)

// Funktion
(
~playWave = { |name, args = #[]|
    ~current.free;
    ~current = Synth(name, args);
};
)

// PLAY
~playWave.(\clipDistortion); // Hård klippning
~playWave.(\softDistortion); // Mjuk klippning

// Ändra frekvens
~current.set(\freq, 220);
~current.set(\freq, 440);

// Ändra amplitud
~current.set(\amp, 0.8);
~current.set(\amp, 0.6);
~current.set(\amp, 0.5);

// STOP
~current.free;
s.stop;
s.freeAll;