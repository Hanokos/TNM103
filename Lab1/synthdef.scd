s.boot;

// SynthDef
(
SynthDef(\firstSynth, {
    arg inputFrequency = 220, amp = 0.2;
    var sig;

    // Enkel sinus som använder inputFrequency
    sig = SinOsc.ar(inputFrequency, 0, amp);

    Out.ar(0, sig ! 2);
}).add;
)

// Skapa synth
~myFirstSynth = Synth.new(\firstSynth).register;

// Ändra frekvens
~myFirstSynth.set(\inputFrequency, 440);
~myFirstSynth.set(\inputFrequency, 220);

// Array med MIDI-noter (A-moll: A, C, E, A)
(
var notes = [57, 60, 64, 69]; // MIDI-noter

~noteLoop = fork {
    loop {
        for(0, notes.size-1, { arg index;
            ~myFirstSynth.set(\inputFrequency, notes[index].midicps);
            0.3.wait;
        });
    }
};
)

// STOP

~noteLoop.stop;
~myFirstSynth.free;

s.stop;
s.freeAll; // ctrl + .