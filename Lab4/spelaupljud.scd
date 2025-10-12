s.boot;

// SynthDef för club.wav + filtrering + brus + envelop
(
SynthDef(\clubWithNoise, {
    arg bufnum = 0, amp = 0.3, gate = 1,
        cutoff = 1000, rq = 0.8,
        attack = 0.01, decay = 0.3, sustain = 0.5, release = 1.0,
        noiseType = 0,    // 0=White,1=Pink,2=Brown,3=Gray,4=Clip
        noiseMix = 0.0,   // 0 = inget brus
        noiseLevel = 0.2;

    var audioFile, env, filtered, noise, mixed, noiseIndex;

    // spela upp club.wav
    audioFile = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), loop: 1);

    // välj brus
    noiseIndex = noiseType.clip(0,4).asInteger;
    noise = Select.ar(
        noiseIndex,
        [
            WhiteNoise.ar(noiseLevel),
            PinkNoise.ar(noiseLevel),
            BrownNoise.ar(noiseLevel),
            GrayNoise.ar(noiseLevel),
            ClipNoise.ar(noiseLevel)
        ]
    );

    // mixa ljudfil med brus
    mixed = audioFile * (1 - noiseMix) + (noise * noiseMix);

    // filtrera mixen
    filtered = RLPF.ar(mixed, cutoff.max(20), rq.max(0.01)); // undvik 0 i cutoff/rq

    // envelop
    env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction:0);
    filtered = filtered * env * amp;

    Out.ar(0, filtered ! 2);
}).add;
)

// Scope
s.scope;
FreqScope.new(400, 400);

// Läs in WAV-fil och starta synth
(
var clubBuffer;
fork {
    clubBuffer = Buffer.read(s, "C:/LJUDTEKNIK/Lab4/club.wav");
    1.0.wait; // vänta tills buffer är fylld

    // skapa synth
    ~clubSynth = Synth(\clubWithNoise, [\bufnum, clubBuffer.bufnum]);
};
)

// ÄNDRA: olika brus
 ~clubSynth.set(\noiseType, 0, \noiseMix, 0);
 ~clubSynth.set(\noiseType, 0, \noiseMix, 0.3); // White noise 30%
 ~clubSynth.set(\noiseType, 1, \noiseMix, 0.5); // Pink noise 50%
 ~clubSynth.set(\noiseType, 2, \noiseMix, 0.4); // Brown noise 40%
 ~clubSynth.set(\noiseType, 3, \noiseMix, 0.3); // Gray noise 30%
 ~clubSynth.set(\noiseType, 4, \noiseMix, 0.5); // Clip noise 50%

// ÄNDRA
 ~clubSynth.set(\cutoff, 500);
 ~clubSynth.set(\cutoff, 2000);
 ~clubSynth.set(\rq, 0.2);
 ~clubSynth.set(\rq, 0.8);

// STOP
 ~clubSynth.free;
clubBuffer.free;
 s.freeAll;
