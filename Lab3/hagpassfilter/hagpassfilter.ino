#include <Arduino.h>
#include <math.h>

// Högpass = original – lågpass

#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))

//  Globala variabler för sampling 
volatile boolean div32;
volatile boolean div16;
volatile boolean sampleFlag; 
volatile byte badc0; // ljudsample ADC kanal 0
volatile byte badc1; // potentiometer ADC kanal 1
volatile byte ibb;

// Globala variabler för filter 
int soundSampleFromADC;       // senaste ljudsample
float lpAlpha = 0.5;          // alpha för lågpass
int lpFilteredSample = 127;   // lågpass-output
int hpFilteredSample = 127;   // högpass-output

// tom funktion för kompatibilitet
void fillSramBufferWithWaveTable() { }

void setup()
{
  Serial.begin(57600);

  //  ADC
  cbi(ADCSRA, ADPS2);
  sbi(ADCSRA, ADPS1);
  sbi(ADCSRA, ADPS0);

  sbi(ADMUX, ADLAR);  // 8-bit ADC i ADCH
  sbi(ADMUX, REFS0);  // VCC som referens
  cbi(ADMUX, REFS1);
  cbi(ADMUX, MUX0);   // starta på kanal 0
  cbi(ADMUX, MUX1);
  cbi(ADMUX, MUX2);
  cbi(ADMUX, MUX3);

  // Timer2 PWM fast
  cbi(TCCR2A, COM2A0);
  sbi(TCCR2A, COM2A1);
  sbi(TCCR2A, WGM20);
  sbi(TCCR2A, WGM21);
  cbi(TCCR2B, WGM22);

  sbi(TCCR2B, CS20);  // prescaler = 1
  cbi(TCCR2B, CS21);
  cbi(TCCR2B, CS22);

  sbi(DDRB, 3); // pin 11 som PWM

  cbi(TIMSK0, TOIE0);
  sbi(TIMSK2, TOIE2);

  lpFilteredSample = 127;
  hpFilteredSample = 127;
  soundSampleFromADC = badc0;
}

void loop()
{
  // Vänta tills ett sample finns
  while (!sampleFlag) {}
  sampleFlag = false;

  uint8_t adc = badc0;   // ljudsample
  uint8_t pot = badc1;   // potentiometer

  //  Lågpass alpha med begränsning 4%-78% 
  const int POT_MIN = (int)round(0.04f * 255.0f); // ≈10
  const int POT_MAX = (int)round(0.78f * 255.0f); // ≈199

  int potC = pot;
  if (potC < POT_MIN) potC = POT_MIN;
  if (potC > POT_MAX) potC = POT_MAX;

  lpAlpha = (float)(potC - POT_MIN) / (float)(POT_MAX - POT_MIN);
  if (lpAlpha < 0.0f) lpAlpha = 0.0f;
  if (lpAlpha > 1.0f) lpAlpha = 1.0f;

  //  Lågpassfilter 
  soundSampleFromADC = adc;
  lpFilteredSample = (int)(lpAlpha * (float)soundSampleFromADC + (1.0f - lpAlpha) * (float)lpFilteredSample);

  //  Högpassfilter: input - lowpass 
  int inputCentered = (int)soundSampleFromADC - 127;
  int lpCentered = lpFilteredSample - 127;
  int hpCentered = inputCentered - lpCentered;
  hpFilteredSample = hpCentered + 127;

  // --- Skicka till PWM ---
  OCR2A = (uint8_t)hpFilteredSample;
}

// Timer2 
ISR(TIMER2_OVF_vect) {
  div32 = !div32;
  if (div32) {
    div16 = !div16;
    if (div16) {
      badc0 = ADCH;           // sampla kanal 0
      sbi(ADMUX, MUX0);      // växla till kanal 1
      sampleFlag = true;
    } else {
      badc1 = ADCH;          // sampla kanal 1
      cbi(ADMUX, MUX0);      // växla tillbaka till kanal 0
    }
    ibb++; ibb--; ibb++; ibb--;
    sbi(ADCSRA, ADSC);        // starta nästa ADC-konversion
  }
}
