s.boot;

// SynthDef med BLowPass (2:a ordningen) och BLowPass4 (4:e ordningen)
(
SynthDef(\lowpassOrders, {
    arg inputFrequency = 220, amp = 0.3, gate = 0,
        attack = 0.01, decay = 0.3, sustain = 0.5, release = 1.0,
        cutoff = 400, rq = 0.8, detune = 1.01,
        filterType = 0; // 0 = BLowPass, 1 = BLowPass4

    var osc1, osc2, sub, mixed, env, filtered;

    // två oscillatorer + suboktav
    osc1 = Saw.ar(inputFrequency);
    osc2 = Saw.ar(inputFrequency * detune);
    sub  = Saw.ar(inputFrequency/2);

    mixed = (osc1 + osc2 + sub) * 0.33;

    // välj filterordning
    filtered = Select.ar(
        filterType,
        [
            BLowPass.ar(mixed, cutoff, rq),   // andra ordningen (12 dB/oktav)
            BLowPass4.ar(mixed, cutoff, rq)   // fjärde ordningen (24 dB/oktav)
        ]
    );

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
~myFilterSynth = Synth(\lowpassOrders);

// spela A-moll (A, C, E, A)
(
var notes = [57, 60, 64, 69];
~noteLoop = fork {
    loop {
        notes.do { |midi|
            ~myFilterSynth.set(\inputFrequency, midi.midicps, \gate, 1);
            0.15.wait;
            ~myFilterSynth.set(\gate, 0);
            0.15.wait;
        };
    };
};
)

// Testa filtertyper och resonans
~myFilterSynth.set(\filterType, 0, \cutoff, 400, \rq, 1);   // BLowPass (12 dB/oktav)
~myFilterSynth.set(\filterType, 1, \cutoff, 400, \rq, 1);   // BLowPass4 (24 dB/oktav)

~myFilterSynth.set(\filterType, 0, \cutoff, 800, \rq, 0.6); // BLowPass, mer resonans
~myFilterSynth.set(\filterType, 1, \cutoff, 800, \rq, 0.6); // BLowPass4, mer resonans

// STOP
~noteLoop.stop;
~myFilterSynth.free;
s.freeAll;
