s.boot;

// Synth
(
SynthDef(\simpleFM, {
    arg freqCarrier = 329.63, freqMod = 329.63, amp = 0.5;
    var mod, car, out;

    // modulator
    mod = SinOsc.ar(freqMod)//.range(0, 5);

    // bärvågen
    car = SinOsc.ar(freqCarrier * mod, mul: amp);
    out = car;
    Out.ar(0, out ! 2);
}).add;

// oscillator 2 utan modulator
SynthDef(\carrierOnly, {
    arg freqCarrier = 329.63, amp = 0.5;
    var car;

    car = SinOsc.ar(freqCarrier, mul: amp);
    Out.ar(0, car ! 2);
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
~playWave.(\simpleFM);
~playWave.(\carrierOnly);

// 1. Spela bara bärvågen (ingen FM)
~playWave.(\simpleFM, [\freqCarrier, 329.63, \freqMod, 0]);
// Hör en ren sinus

// 2. Spela FM med oscillator 1 = bärvågen
~current.set(\freqMod, 329.63);

// Ändra FM-syntes
~current.set(\freqMod, 0);
~current.set(\freqMod, 1);
~current.set(\freqMod, 10);
~current.set(\freqMod, 110);
~current.set(\freqMod, 220);
~current.set(\freqMod, 329.63); // samma som carrier
~current.set(\freqMod, 440);
~current.set(\freqMod, 880);
~current.set(\freqMod, 1760);

// Ändra carrier
~current.set(\freqCarrier, 220);
~current.set(\freqCarrier, 440);

// STOP
~current.free;
s.stop;
s.freeAll;

