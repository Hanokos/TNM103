s.boot;

// Synth
(
SynthDef(\pulsePWM, { // fyrkants våg
    arg freq = 220.0, pwmFreq = 1.0, pwmRange = 0.5, iphase = 0.0;
    var pwm, sig;

    // modulera pulsbredden
    // Använder pwmRange för att kontrollera moduleringsomfånget
    pwm = SinOsc.kr(pwmFreq).range(0.0 - pwmRange, pwmRange);

    // pwn som input för width:
    sig = LFPulse.ar(freq: freq, iphase: iphase, width: pwm, mul: 1.0, add: 0.0);

    Out.ar(0, sig ! 2);
}).add;
)

// Funktion
(
~playWave = { |name, args = #[]|
    ~current.free;             // stoppa pågående
    ~current = Synth(name, args);
};
)

// PLAY
~playWave.(\pulsePWM);

// Ändra moduleringsfrekvenser (pwnfreq)
~current.set(\pwmFreq, 0.5); // långsam
~current.set(\pwmFreq, 2);
~current.set(\pwmFreq, 10); // Snabb

// Ändra moduleringsomfång(pwmRange)
~current.set(\pwmRange, 0.1);
~current.set(\pwmRange, 0.2);
~current.set(\pwmRange, 0.4);
~current.set(\pwmRange, 0);
~current.set(\pwmRange, 1);

// Ändra
~current.set(\freq, 110);
~current.set(\freq, 440);

// STOP
~current.free;