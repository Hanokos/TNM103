s.boot;

// Synths
(
SynthDef(\ampModSin, {
    arg freqMod = 1, freqCarrier = 329.63, amp = 0.5;
    var mod, car, out;

    // Kontrollsignal
    mod = SinOsc.kr(freqMod).range(0.9, 1);  // Konverterar till range 0.9 - 1

    car = SinOsc.ar(freqCarrier, mul: amp);
    out = car * mod;
    Out.ar(0, out ! 2);
}).add;

SynthDef(\ampModTri, {
    arg freqMod = 1, freqCarrier = 329.63, amp = 0.5;
    var mod, car, out;

    mod = SinOsc.kr(freqMod).range(0, 1);
    car = LFTri.ar(freqCarrier, mul: amp);
    out = car * mod;

    Out.ar(0, out ! 2);
}).add;

SynthDef(\ampModSaw, {
    arg freqMod = 1, freqCarrier = 329.63, amp = 0.5;
    var mod, car, out;

    mod = SinOsc.kr(freqMod).range(0, 1);
    car = LFSaw.ar(freqCarrier, mul: amp);
    out = car * mod;

    Out.ar(0, out ! 2);
}).add;

SynthDef(\ampModPulse, {
    arg freqMod = 1, freqCarrier = 329.63, width = 0.5, amp = 0.5;
    var mod, car, out;

    mod = SinOsc.kr(freqMod).range(0, 1);
    car = LFPulse.ar(freqCarrier, 0, width, mul: amp);
    out = car * mod;

    Out.ar(0, out ! 2);
}).add;
)

// Funktion för att spela
(
~playWave = { |name, args = #[]|
    ~current.free;
    ~current = Synth(name, args);
};
)

// PLAY
~playWave.(\ampModSin); // 0,9 - 1 range
~playWave.(\ampModTri);
~playWave.(\ampModSaw);
~playWave.(\ampModPulse);

// Ändra första oscillatorn
~current.set(\freqMod, 0.5);  // Långsam
~current.set(\freqMod, 5);    // Mellan
~current.set(\freqMod, 20);   // Snabb
~current.set(\freqMod, 50);   // Snabbare

// Ändra
~current.set(\freqCarrier, 220);
~current.set(\freqCarrier, 440);

// STOP
~current.free;
s.stop;
s.freeAll;