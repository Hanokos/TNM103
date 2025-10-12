s.boot;

// Synth med Bandpassfilter (BPF)
(
SynthDef(\bandpassSynth, {
    arg inputFrequency = 220, amp = 0.3, gate = 0,
        attack = 0.01, decay = 0.3, sustain = 0.5, release = 1.0,
        cutoff = 440, rq = 0.5, detune = 1.01;

    var osc1, osc2, sub, mixed, env, filtered;

    // Två oscillatorer + suboktav
    osc1 = Saw.ar(inputFrequency);
    osc2 = Saw.ar(inputFrequency * detune);
    sub  = Saw.ar(inputFrequency/2);

    mixed = (osc1 + osc2 + sub) * 0.33;

    // Bandpassfilter
    filtered = BPF.ar(mixed, cutoff, rq);

    // Envelop
    env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction:0);
    filtered = filtered * env * amp;

    Out.ar(0, filtered ! 2);
}).add;
)

// Skapa synth
~myBPSynth = Synth(\bandpassSynth);

// Spela A-moll med gate-simulering
(
var notes = [57, 60, 64, 69];
~noteLoop = fork {
    loop {
        notes.do { |midi|
            ~myBPSynth.set(\inputFrequency, midi.midicps, \gate, 1);
            0.15.wait;
            ~myBPSynth.set(\gate, 0);
            0.15.wait;
        };
    };
};
)


// scope
s.scope;
FreqScope.new(400, 400);

// Testa bandpassfilter
~myBPSynth.set(\cutoff, 220, \rq, 0.9);   // smalt band, lågt centrum
~myBPSynth.set(\cutoff, 440, \rq, 0.5);   // lite bredare band
~myBPSynth.set(\cutoff, 880, \rq, 0.3);   // tydlig bandpass runt 880 Hz
~myBPSynth.set(\cutoff, 2000, \rq, 0.1);  // mycket smalt bandpass, nästan visslande

// STOP
~noteLoop.stop;
~myBPSynth.free;
s.stop; s.freeAll;
