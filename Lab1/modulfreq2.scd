s.boot;

//Synths
(
SynthDef(\freqModSin, {
    arg freqMod = 0.5, freqCarrier = 329.63, amp = 0.5, modRange = 10;
    var mod, out;

    mod = SinOsc.kr(freqMod).range(0-modRange, modRange);
    out = SinOsc.ar(freqCarrier + mod, mul: amp);
    Out.ar(0, out ! 2);
}).add;

SynthDef(\freqModTri, {
    arg freqMod = 0.5, freqCarrier = 329.63, amp = 0.5, modRange = 10;
    var mod, out;

    mod = SinOsc.kr(freqMod).range(0-modRange, modRange);
    out = LFTri.ar(freqCarrier + mod, mul: amp);
    Out.ar(0, out ! 2);
}).add;

SynthDef(\freqModSaw, {
    arg freqMod = 0.5, freqCarrier = 329.63, amp = 0.5, modRange = 10;
    var mod, out;

    mod = SinOsc.kr(freqMod).range(0-modRange, modRange);
    out = LFSaw.ar(freqCarrier + mod, mul: amp);
    Out.ar(0, out ! 2);
}).add;

SynthDef(\freqModPulse, {
    arg freqMod = 0.5, freqCarrier = 329.63, width = 0.5, amp = 0.5, modRange = 10;
    var mod, out;

    mod = SinOsc.kr(freqMod).range(0-modRange, modRange);
    out = LFPulse.ar(freqCarrier + mod, 0, width, mul: amp);
    Out.ar(0, out ! 2);
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
~playWave.(\freqModSin);
~playWave.(\freqModTri);
~playWave.(\freqModSaw);
~playWave.(\freqModPulse);

// Ändra styrsignal
~current.set(\freqMod, 0.1);
~current.set(\freqMod, 1);
~current.set(\freqMod, 5);
~current.set(\freqMod, 20);

// Ändra modul omfång
~current.set(\modRange, 5);   // Mindre modulering
~current.set(\modRange, 10);  // Större modulering
~current.set(\modRange, 100); // Mycket större modulering

// Ändra ljudsignal
~current.set(\freqCarrier, 220);
~current.set(\freqCarrier, 440);

// STOP
~current.free;
s.stop;
s.freeAll;
