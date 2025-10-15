/* Arduino Realtime Audio Processing
   2 ADC 8-Bit Mode
   analog input 0 is used to sample the audio signal
   analog input 1 is used to control the mix
   PWM DAC with Timer2 as analog output
*/

#include <Arduino.h>
#include <math.h>

// cbi = Clear Bit, sbi = Set Bit i I/O-register
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))

// --- Globala variabler ---
boolean div32;
boolean div16;

volatile boolean sampleFlag;
volatile byte badc0; // ljudsample (ADC kanal 0)
volatile byte badc1; // potentiometer (ADC kanal 1)
volatile byte ibb;

int bufferIndex = 0;           // position i sinusbuffer
int soundSampleFromADC;        // inkommande ljud sample - DC offset borttagen
int sramBufferSampleValue;     // utgående sample (0-255)

byte sramBuffer[512];          // sinusvåg-buffer

// --- Setup ---
void setup() {
  Serial.begin(57600);

  // Initiera sinusbuffer
  float delta = (2.0 * M_PI) / 511.0;
  float phase = 0.0;
  for (int i = 0; i < 512; i++) {
    sramBuffer[i] = round(127 + 127 * sin(phase)); // 0-255
    phase += delta;
  }

  // --- ADC ---
  cbi(ADCSRA, ADPS2);
  sbi(ADCSRA, ADPS1);
  sbi(ADCSRA, ADPS0);

  sbi(ADMUX, ADLAR);
  sbi(ADMUX, REFS0);
  cbi(ADMUX, REFS1);
  cbi(ADMUX, MUX0); cbi(ADMUX, MUX1); cbi(ADMUX, MUX2); cbi(ADMUX, MUX3);

  // --- Timer2 PWM ---
  cbi(TCCR2A, COM2A0); sbi(TCCR2A, COM2A1);
  sbi(TCCR2A, WGM20); sbi(TCCR2A, WGM21); cbi(TCCR2B, WGM22);
  sbi(TCCR2B, CS20); cbi(TCCR2B, CS21); cbi(TCCR2B, CS22);
  sbi(DDRB,3);

  cbi(TIMSK0, TOIE0); sbi(TIMSK2, TOIE2);

  soundSampleFromADC = badc0;
  sbi(ADCSRA, ADSC);
}

// --- Loop ---
void loop() {
  while (!sampleFlag) { }
  sampleFlag = false;

  int dcOffset = 127;

  // --- Läs inkommande ljud och ta bort DC-offset ---
  soundSampleFromADC = badc0 - dcOffset;

  // --- Läs sinusvåg från buffer ---
  int sineSample = sramBuffer[bufferIndex] - dcOffset;

  // --- Multiplicera () ---
  long modulated = (long)soundSampleFromADC * (long)sineSample / 128L;

  // --- Mixstyrka från potentiometer ---
  float mix = map(badc1, 0, 255, 0, 255) / 255.0;
  long mixedSignal = (long)soundSampleFromADC * (1.0 - mix) + modulated * mix;

  // --- Begränsa till 8-bit ---
  if (mixedSignal > 127) mixedSignal = 127;
  if (mixedSignal < -127) mixedSignal = -127;

  // --- Lägg till DC-offset igen ---
  sramBufferSampleValue = mixedSignal + dcOffset;

  // --- Skicka till PWM ---
  OCR2A = sramBufferSampleValue;

  // --- Öka bufferIndex med konstant steg för frekvens ---
  bufferIndex = (bufferIndex + 2) & 511; // minsta steg = 2, ej 0 för att undvika "reverb-ljud"
}

// --- Timer2 ISR ---
ISR(TIMER2_OVF_vect) {
  div32 = !div32;
  if (div32) {
    div16 = !div16;
    if (div16) {
      badc0 = ADCH;       // sampla kanal 0
      sbi(ADMUX, MUX0);   // växla till kanal 1
      sampleFlag = true;
    } else {
      badc1 = ADCH;       // sampla kanal 1
      cbi(ADMUX, MUX0);   // växla tillbaka till kanal 0
    }
    ibb++; ibb--; ibb++; ibb--;
    sbi(ADCSRA, ADSC);    // starta nästa ADC-konvertering
  }
}
