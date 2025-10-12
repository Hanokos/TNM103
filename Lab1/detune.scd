s.boot;

// Detune
(
SynthDef(\detuneWave, {
    arg freq = 220.0, detune = 1.0;
    var sig1, sig2, out;

    // 2 sinusoscillatore
    sig1 = SinOsc.ar(freq + detune);
    sig2 = SinOsc.ar(freq - detune);

	out = (sig1 + sig2);
    Out.ar(0, out ! 2);
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
~playWave.(\detuneWave);

// Ändra detune
~current.set(\detune, 0);
~current.set(\detune, 0.1);
~current.set(\detune, 0.5);
~current.set(\detune, 1.0);
~current.set(\detune, 5.0);
~current.set(\detune, 75);

// Ändra frekvens
~current.set(\freq, 440);
~current.set(\freq, 220);

// STOP
~current.free;
s.stop;
s.freeAll;
