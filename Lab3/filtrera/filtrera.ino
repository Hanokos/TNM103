#include <Arduino.h>
#include <math.h>

#define WAVETABLE_SIZE 512
#define SAMPLE_RATE 8000   // 8 kHz, samplingsfrekvens

byte sramBuffer[WAVETABLE_SIZE];
volatile uint16_t bufferIndex = 0; // index i wavetable
volatile uint8_t stepValue = 2;    // fast frekvens

// Filtervariabler
float alpha = 0.3;         // lågpass alpha
float alpha2 = 0.0;        // bandpass alpha
int lowpassSample = 0;
int lowpassSample2 = 0;
int highpassSample = 0;
int bandpassSample = 0;
int bandstopSample = 0;
int soundSample = 0;

// Filterläge: 0=Lågpass,1=Högpass,2=Bandpass,3=Bandstopp
int filterMode = 0;  

// Vågtabsval: 0=Sinus,1=Sågtand,2=Fyrkant,3=Triangel
int waveMode = 0;  

// Fyll buffert med vald vågform
void fillSramBuffer(int waveType) {
  for (int i = 0; i < WAVETABLE_SIZE; i++) {
    float val = 0.0;
    switch (waveType) {
      case 0: val = 127.0 * sin(2.0 * M_PI * i / WAVETABLE_SIZE); break;  // sinus
      case 1: val = ((255.0 / WAVETABLE_SIZE) * i) - 127.0; break;          // sågtand
      case 2: val = (i < WAVETABLE_SIZE/2) ? 127.0 : -127.0; break;         // fyrkant
      case 3: // triangel
        if (i < WAVETABLE_SIZE/2)
          val = -127.0 + (i * 255.0 / (WAVETABLE_SIZE/2));
        else
          val = 127.0 - ((i - WAVETABLE_SIZE/2) * 255.0 / (WAVETABLE_SIZE/2));
        break;
    }
    sramBuffer[i] = (byte)round(val + 127.0); // skala till 0-255
  }
}

// Timer1 interrupt
ISR(TIMER1_COMPA_vect) {
  bufferIndex = (bufferIndex + stepValue) & (WAVETABLE_SIZE - 1); // öka index
  soundSample = sramBuffer[bufferIndex];                            // läs sample

  // Filtrera beroende på filterläge
  switch (filterMode) {
    case 0: // lågpass
      lowpassSample = alpha * soundSample + (1 - alpha) * lowpassSample;
      OCR2A = lowpassSample;
      break;

    case 1: // högpass
      lowpassSample = alpha * soundSample + (1 - alpha) * lowpassSample;
      highpassSample = soundSample - lowpassSample + 127;  // DC-korrigering
      OCR2A = constrain(highpassSample, 0, 255);
      break;

    case 2: // bandpass
      alpha2 = sqrt(alpha); 
      lowpassSample = alpha * soundSample + (1 - alpha) * lowpassSample;
      lowpassSample2 = alpha2 * soundSample + (1 - alpha2) * lowpassSample2;
      bandpassSample = lowpassSample2 - lowpassSample + 127; // DC-korrigering
      OCR2A = constrain(bandpassSample, 0, 255);
      break;

    case 3: // bandstopp
      alpha2 = sqrt(alpha);
      lowpassSample = alpha * soundSample + (1 - alpha) * lowpassSample;
      lowpassSample2 = alpha2 * soundSample + (1 - alpha2) * lowpassSample2;
      bandpassSample = lowpassSample2 - lowpassSample;
      bandstopSample = soundSample - bandpassSample;
      OCR2A = constrain(bandstopSample, 0, 255);
      break;
  }
}

// Timer setup
void setupTimers() {
  TCCR2A = _BV(COM2A1) | _BV(WGM21) | _BV(WGM20); // PWM pin 11
  TCCR2B = _BV(CS20);

  TCCR1A = 0;
  TCCR1B = _BV(WGM12) | _BV(CS11); // CTC
  OCR1A = (uint16_t)((F_CPU / (8UL * SAMPLE_RATE)) - 1);
  TIMSK1 = _BV(OCIE1A); // enable interrupt
}

void setup() {
  Serial.begin(115200);
  pinMode(11, OUTPUT);
  fillSramBuffer(waveMode);   // fyll startvåg
  setupTimers();
  Serial.println("Vågformsfilter test startar...");
}

void loop() {
  int potValue = analogRead(A1);               // läs potentiometer
  alpha = 0.04 + (0.74 * potValue / 1023.0);  // mappa alpha 0.04-0.78

  // byt filterläge via Serial 0-3
  if (Serial.available()) {
    char c = Serial.read();
    if (c >= '0' && c <= '3') {
      filterMode = c - '0';
      Serial.print("Filterläge ändrat till: ");
      Serial.println(filterMode);
    } else if (c >= '4' && c <= '7') {       // byt vågform
      waveMode = c - '4';
      fillSramBuffer(waveMode);
      Serial.print("Vågform ändrad till: ");
      Serial.println(waveMode);
    }
  }

  Serial.println(OCR2A); // skicka PWM-värde till Serial Plotter
}
