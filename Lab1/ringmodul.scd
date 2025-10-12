s.boot;

// Synth
(
SynthDef(\ringModSin, {
    arg freqMod = 200, freqCarrier = 329.63, amp = 0.5;
    var mod, car, out;

    mod = SinOsc.ar(freqMod); // modulator
    car = SinOsc.ar(freqCarrier, mul: amp);  // bärvågen
    out = car * mod;
    Out.ar(0, out ! 2);
}).add;

SynthDef(\ringModTri, {
    arg freqMod = 200, freqCarrier = 329.63, amp = 0.5;
    var mod, car, out;

    mod = SinOsc.ar(freqMod); // modulator
    car = LFTri.ar(freqCarrier, mul: amp);
    out = car * mod;
    Out.ar(0, out ! 2);
}).add;

SynthDef(\ringModSaw, {
    arg freqMod = 200, freqCarrier = 329.63, amp = 0.5;
    var mod, car, out;

    mod = SinOsc.ar(freqMod); // modulator
    car = LFSaw.ar(freqCarrier, mul: amp);
    out = car * mod;
    Out.ar(0, out ! 2);
}).add;

SynthDef(\ringModPulse, {
    arg freqMod = 200, freqCarrier = 329.63, width = 0.5, amp = 0.5;
    var mod, car, out;

    mod = SinOsc.ar(freqMod); // modulator
    car = LFPulse.ar(freqCarrier, 0, width, mul: amp);
    out = car * mod;
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
~playWave.(\ringModSin);
~playWave.(\ringModTri);
~playWave.(\ringModSaw);
~playWave.(\ringModPulse);

// Ändra modulatorfrekvens
~current.set(\freqMod, 1);    // långsam
~current.set(\freqMod, 200);
~current.set(\freqMod, 220);
~current.set(\freqMod, 329.63);
~current.set(\freqMod, 440);
~current.set(\freqMod, 1000);

// Ändra carrier
~current.set(\freqCarrier, 220);
~current.set(\freqCarrier, 329.63);
~current.set(\freqCarrier, 440);

// STOP
~current.free;
~current = nil;
s.stop;
s.freeAll;
