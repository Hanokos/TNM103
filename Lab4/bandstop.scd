s.boot;

// SynthDef med bandstoppfilter (notch)
(
SynthDef(\bandstopSynth, {
    arg inputFrequency = 220, amp = 0.3, gate = 0,
        attack = 0.01, decay = 0.3, sustain = 0.5, release = 1.0,
        cutoff = 1200, bw = 2.0, detune = 1.01;

    var osc1, osc2, sub, mixed, env, filtered;

    // två oscillatorer + suboktav
    osc1 = Saw.ar(inputFrequency);
    osc2 = Saw.ar(inputFrequency * detune);
    sub  = Saw.ar(inputFrequency/2);

    mixed = (osc1 + osc2 + sub) * 0.33;

    // bandstoppfilter
    // freq = center freq, bw = bandbredd (små tal ~1–6)
    filtered = BBandStop.ar(mixed, cutoff, bw);

    // envelop
    env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction:0);
    filtered = filtered * env * amp;

    Out.ar(0, filtered ! 2);
}).add;
)

// scope
s.scope;
FreqScope.new(400, 400);

// skapa synth
~myBSSynth = Synth(\bandstopSynth);

// spela A-moll (A, C, E, A)
(
var notes = [57, 60, 64, 69];
~noteLoop = fork {
    loop {
        notes.do { |midi|
            ~myBSSynth.set(\inputFrequency, midi.midicps, \gate, 1);
            0.15.wait;
            ~myBSSynth.set(\gate, 0);
            0.15.wait;
        };
    };
};
)

// Testa cutoff + bw
~myBSSynth.set(\cutoff, 440, \bw, 1);   // smalt notch kring 440 Hz
~myBSSynth.set(\cutoff, 880, \bw, 3);   // lite bredare notch
~myBSSynth.set(\cutoff, 1200, \bw, 6);  // väldigt bred notch
~myBSSynth.set(\cutoff, 2000, \bw, 2);  // notch högre upp

// STOP
~noteLoop.stop;
~myBSSynth.free;
s.freeAll;
