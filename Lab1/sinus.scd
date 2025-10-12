s.boot; // starta enhet/server

//Synths
// Fasförskjuten sinus
(
SynthDef(\phaseTest, {
    arg freq = 220.0, phase = pi/2, mul = 1.0, add = 0.0;
    var sig = SinOsc.ar(freq, phase, mul, add);
    Out.ar(0, sig ! 2); // skickar monosignal till vänster och höger kanal
}).add;

// DC
SynthDef(\offsetTest, {
    arg freq = 220.0, offset = 0.5, mul = 1.0;
    var sig = SinOsc.ar(freq, 0, mul) + offset; // sin(2πft)+0.5 ger medelvärde 0.5

    Out.ar(0, sig ! 2);
}).add;

// Amplitudändring
SynthDef(\ampTest, {
    arg freq = 220.0, amp = 0.5, phase = 0.0;
    var sig = SinOsc.ar(freq, phase) * amp;
    Out.ar(0, sig ! 2);
}).add;
)

// Funktion
(
~playWave = { |name, args = #[]|
    ~current.free;              // stoppa pågående
    ~current = Synth(name, args);
};
)

// PLAY
~playWave.(\phaseTest); // Fasförskjuten
~playWave.(\offsetTest);  // DC offset

~playWave.(\ampTest);
~playWave.(\ampTest, [\amp, 0.2]); // Lägre amplitud

// Ändra freq
~current.set(\freq, 330);
~current.set(\freq, 440);

// scope
s.scope;
FreqScope.new(400, 400);


// STOP
~current.free;
s.stop;
s.freeAll;
