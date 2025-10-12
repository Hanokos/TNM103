s.boot;

// SynthDef för självsvängande BLowPass4
(
SynthDef(\selfOscLPF4, {
    arg inputFrequency = 60, amp = 0.2, gate = 0,
        attack = 0.01, decay = 0.3, sustain = 0.5, release = 1.0,
        detune = 1.01;

    var osc1, osc2, sub, mixed, env, filtered;

    // två oscillatorer + suboktav
    osc1 = Saw.ar(inputFrequency.midicps);
    osc2 = Saw.ar(inputFrequency.midicps * detune);
    sub  = Saw.ar(inputFrequency.midicps/2);

    // mixa oscillatorer och sänk volym
    mixed = (osc1 + osc2 + sub) * 0.01;

    // BLowPass4 med maximal självsvängning
    filtered = BLowPass4.ar(mixed, inputFrequency.midicps, 0.01);

    // envelop (för kontroll över gate)
    env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction:0);
    filtered = filtered * env * amp;

    Out.ar(0, filtered ! 2);
}).add;
)

// scope
s.scope;
FreqScope.new(400, 400);

// skapa synth
~mySelfOsc = Synth(\selfOscLPF4);

// spela A-moll (A, C, E, A)
(
var notes = [57, 60, 64, 69];
~noteLoop = fork {
    loop {
        notes.do { |midi|
            ~mySelfOsc.set(\inputFrequency, midi, \gate, 1);
            0.15.wait;
            ~mySelfOsc.set(\gate, 0);
            0.15.wait;
        };
    };
};
)

// STOP
~noteLoop.stop;
~mySelfOsc.free;
s.freeAll;
