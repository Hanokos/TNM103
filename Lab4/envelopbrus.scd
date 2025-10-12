s.boot;

// SynthDef
// med två oscillatorer + sub + noise + HPF + LFO (cutoff override möjlig)
(
SynthDef(\firstSynthEnvNoiseSubLFO, {
    arg inputFrequency = 220, amp = 0.2, gate = 0,
        attack = 0.01, decay = 0.3, sustain = 0.5, release = 1.0,
        cutoff = 0, cutoffMin = 200, cutoffMax = 2000, // cutoff override + LFO-range
        lfoFreq = 0.5,                                 // LFO-hastighet
        noiseType = 0, noiseMix = 0, noiseLevel = 0.5,
        detune = 1.01;

    var osc1, osc2, sub, noise, mixed, env, cutoffFreq, filtered;

    osc1 = Saw.ar(inputFrequency);
    osc2 = Saw.ar(inputFrequency * detune);
    sub  = Saw.ar(inputFrequency/2);

    noise = Select.ar(
        noiseType.clip(0,4),
        [
            WhiteNoise.ar(noiseLevel),
            PinkNoise.ar(noiseLevel),
            BrownNoise.ar(noiseLevel),
            GrayNoise.ar(noiseLevel),
            ClipNoise.ar(noiseLevel)

			// WhiteNoise = platt spektrum, alla frekvenser lika starka.
            // PinkNoise = kraften minskar med högre frekvens (1/f).
            // BrownNoise = kraftigt lutande mot låga frekvenser (1/f²).
			// GrayNoise = hörselanpassat, olika styrka beroende på frekvens.
			// ClipNoise = kraftig i både låg och hög, kan klippa toppen.



        ]
    );

    mixed = (osc1 + osc2 + sub + (noise * noiseMix)) * 0.25;

    // Om cutoff > 0 används det värdet, annars LFO mellan cutoffMin och cutoffMax
    cutoffFreq = (cutoff > 0).if(cutoff, SinOsc.kr(lfoFreq).range(cutoffMin, cutoffMax));

    filtered = HPF.ar(mixed, cutoffFreq);

    env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction:0);
    filtered = filtered * env * amp;

    Out.ar(0, filtered ! 2);
}).add;
)

// Skapa synth
~myFirstSynth = Synth(\firstSynthEnvNoiseSubLFO);

// Spela A-moll (MIDI: A, C, E, A) med gate-simulering
(
var notes = [57, 60, 64, 69];
~noteLoop = fork {
    loop {
        notes.do { |midi|
            ~myFirstSynth.set(\inputFrequency, midi.midicps, \gate, 1);
            0.15.wait;
            ~myFirstSynth.set(\gate, 0);
            0.15.wait;
        };
    };
};
)

// Olika brus
~myFirstSynth.set(\noiseType, 0, \noiseMix, 0.5); // White noise
~myFirstSynth.set(\noiseType, 1, \noiseMix, 0.8); // Pink noise
~myFirstSynth.set(\noiseType, 2, \noiseMix, 0.5); // Brown noise
~myFirstSynth.set(\noiseType, 3, \noiseMix, 0.8); // Gray noise
~myFirstSynth.set(\noiseType, 4, \noiseMix, 0.5); // Clip noise

// Stäng av brus helt
~myFirstSynth.set(\noiseMix, 0);

// HPF
~myFirstSynth.set(\cutoff, 220);
~myFirstSynth.set(\cutoff, 440);
~myFirstSynth.set(\cutoff, 2200);  // ljusare

// sätt denna först innan LFO
~myFirstSynth.set(\cutoff, 0);

//  LFO
~myFirstSynth.set(\lfoFreq, 0.2);      // långsam svepning
~myFirstSynth.set(\lfoFreq, 2);        // snabbare
~myFirstSynth.set(\cutoffMin, 300, \cutoffMax, 4000); // större range

// STOP
~noteLoop.stop;
~myFirstSynth.free;
 s.stop; s.freeAll;


// VISA
s.scope;
FreqScope.new(400, 400);
