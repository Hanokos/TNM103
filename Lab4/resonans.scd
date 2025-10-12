s.boot;

// Synth med resonant filter (RLPF eller RHPF)
(
SynthDef(\resonantSynth, {
    arg inputFrequency = 220, amp = 0.3, gate = 0,
        attack = 0.01, decay = 0.3, sustain = 0.5, release = 1.0,
        cutoff = 440, rq = 0.5, detune = 1.01;

    var osc1, osc2, sub, mixed, env, filtered;

    // Två oscillatorer + suboktav
    osc1 = Saw.ar(inputFrequency);
    osc2 = Saw.ar(inputFrequency * detune);
    sub  = Saw.ar(inputFrequency/2);

    mixed = (osc1 + osc2 + sub) * 0.33;

    // Resonant filter: byt RLPF <-> RHPF
    filtered = RLPF.ar(mixed, cutoff, rq);
    // filtered = RHPF.ar(mixed, cutoff, rq); // använd denna rad istället om du vill ha resonant högpass

    // Envelop
    env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction:0);
    filtered = filtered * env * amp;

    Out.ar(0, filtered ! 2);
}).add;
)

// Skapa synth
~myResSynth = Synth(\resonantSynth);

// Spela A-moll med gate-simulering
(
var notes = [57, 60, 64, 69];
~noteLoop = fork {
    loop {
        notes.do { |midi|
            ~myResSynth.set(\inputFrequency, midi.midicps, \gate, 1);
            0.15.wait;
            ~myResSynth.set(\gate, 0);
            0.15.wait;
        };
    };
};
)

// scope
s.scope;
FreqScope.new(400, 400);

// Testa cutoff och resonans
~myResSynth.set(\cutoff, 220, \rq, 0.9);   // nästan inget resonans
~myResSynth.set(\cutoff, 440, \rq, 0.5);   // tydligare resonans
~myResSynth.set(\cutoff, 880, \rq, 0.2);   // stark resonans
~myResSynth.set(\cutoff, 1200, \rq, 0.05); // extrem resonans, nära självsvängning

// STOP
~noteLoop.stop;
~myResSynth.free;
s.stop; s.freeAll;
