s.boot;

//Synths
(
SynthDef(\freqModWave, {
    arg freqMod = 0.0, freqCarrier = 329.63;
    var sin1, sin2;

    // Styrsignal LFO
    sin1 = SinOsc.kr(freqMod); // svänger mellan -1 och 1

    // ljudsignal Huvudoscillator
    sin2 = SinOsc.ar(freqCarrier + sin1);

    Out.ar(0, sin2 ! 2);
}).add;
)

// Funktion
(
~playWave = { |name, args = #[]|
    ~current.free;              // stoppa pågående
    ~current = Synth(name, args);
};
)

// PLAY
~playWave.(\freqModWave);

// Ändra styrsignal (sin1)
~current.set(\freqMod, 0.1);
~current.set(\freqMod, 1);  // långsam
~current.set(\freqMod, 5);    // snabb
~current.set(\freqMod, 9);  // snabbare
~current.set(\freqMod, 100);  // extreme

// Ändra ljudsignal (sin2)
~current.set(\freqCarrier, 440)
~current.set(\freqCarrier, 220)
~current.set(\freqCarrier, 329.63)

// STOP
~current.free;
s.stop;
s.freeAll;
