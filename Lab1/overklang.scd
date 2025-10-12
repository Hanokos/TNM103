s.boot;

// Synth
(
SynthDef(\intervalDetune, {
    arg freq1 = 220, freq2 = 329.63, detune = 1, amp = 1;
    var sig1, sig2, out;

    // 2 sinusoscillatore
    sig1 = SinOsc.ar(freq1 + detune);   // frekvens 1 + detune
    sig2 = SinOsc.ar(freq2 - detune);   // frekvens 2 - detune

    out = (sig1 + sig2) * (amp);  // dela med 2 för att undvika clipping
    Out.ar(0, out ! 2);
}).add;
)

// Funktion
(
~playIntervalDetune = { |name, args = #[]|
    ~current.free;
    ~current = Synth(name, args);
};
)

// PLAY
~playIntervalDetune.(\intervalDetune);

// Testa olika detune-värden

// Ändra detune
~current.set(\detune, 0);
~current.set(\detune, 0.1);
~current.set(\detune, 0.5);
~current.set(\detune, 1.0);
~current.set(\detune, 5.0);
~current.set(\detune, 75);

// Ändra intervall
~current.set(\freq1, 220);
~current.set(\freq1, 220*2);

~current.set(\freq2, 220*2);
~current.set(\freq2, 220/2);
~current.set(\freq2, 329.63);


// Ändra amplitud
~current.set(\amp, 0.3);
~current.set(\amp, 0.5);
~current.set(\amp, 1);

// STOP
~current.free;
s.stop;
s.freeAll;
