s.boot;

// SynthDef
(
SynthDef(\clubWithDelayReverb, {
    arg bufnum = 0, amp = 0.3, gate = 1,
        cutoff = 1000, rq = 0.8,
        attack = 0.01, decay = 0.3, sustain = 0.5, release = 1.0,
        delayTime = 0.2, delayDecay = 0.66,
        reverb = 0;  // 0 = delay, 1 = reverb

    var audioFile, env, filtered, dry, wet, dt;

    // spela upp ljudfil
    audioFile = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), loop: 1);

    // filtrera ljudet
    filtered = RLPF.ar(audioFile, cutoff.max(20), rq.max(0.01));

    // envelop
    env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction:0);
    filtered = filtered * env * amp;

    dry = filtered;

    // Välj delaytid beroende på reverb-flag
    // 0 = delay med fast tid, 1 = reverb med slumpad kort tid
    dt = Select.kr(reverb, [delayTime, TRand.kr(0.01, 0.03, Impulse.kr(5))]);

    // Schroeders tre allpassfilter i serie
    wet = dry;// TA BROT FÖR 1 ALLPASS
    3.do { // TA BROT FÖR 1 ALLPASS
        wet = AllpassC.ar(wet, maxdelaytime: 0.2, delaytime: dt, decaytime: delayDecay);
    }; // TA BORT FÖR 1 ALLPASS

    // mixa original och effekt
    filtered = dry + wet * 0.5;

    Out.ar(0, filtered ! 2);
}).add;
)

// VISA
s.scope;
FreqScope.new(400, 400);

// Läs in WAV-fil och starta synth
(
var clubBuffer;
fork {
    clubBuffer = Buffer.read(s, "C:/LJUDTEKNIK/Lab4/club.wav");
    1.0.wait;

    ~clubSynth = Synth(\clubWithDelayReverb, [\bufnum, clubBuffer.bufnum]);
};
)

// ÄNDRA
~clubSynth.set(\reverb, 0); // delay
~clubSynth.set(\reverb, 0.8); // reverb
~clubSynth.set(\cutoff, 500); // mörkare
~clubSynth.set(\cutoff, 2000); // ljusare
~clubSynth.set(\rq, 0.3); // mer resonans

// STOP
 ~clubSynth.free;
clubBuffer.free;
 s.freeAll;
