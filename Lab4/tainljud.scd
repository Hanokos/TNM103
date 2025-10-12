s.boot;

// Lista ljudingångar
ServerOptions.inDevices.postln;

// SynthDef
(
SynthDef(\extInputFilter, {
    arg amp = 0.3, gate = 1,
        cutoff = 1000, rq = 0.8,
        attack = 0.01, decay = 0.3, sustain = 0.5, release = 1.0,
        inBus = 0;  // ljudingång (0 = första ingången)

    var input, env, filtered;

    // ta in ljud från externt
    input = SoundIn.ar(bus: inBus);

    // filtrera ljudet
    filtered = RLPF.ar(input, cutoff, rq);

    // envelop
    env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction:0);
    filtered = filtered * env * amp;

    Out.ar(0, filtered ! 2);
}).add;
)

// Starta synth,(0 eller 1 beroende på enhet)
~extSynth = Synth(\extInputFilter, [\inBus, 0]);

// VISA
s.meter;
s.scope;

// ÄNDRA
~extSynth.set(\cutoff, 500);    // mörkare ljud
~extSynth.set(\cutoff, 2000);   // ljusare ljud
~extSynth.set(\rq, 0.3);        // mer resonans
~extSynth.set(\rq, 0.8);

// STOP
 ~extSynth.free;
 s.freeAll;
