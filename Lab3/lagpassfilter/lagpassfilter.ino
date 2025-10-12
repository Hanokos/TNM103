/* Arduino Realtime Audio Processing
   Anpassad för lågpassfilter (EMA) med badc0 och badc1
*/

#include <Arduino.h>
#include <math.h>

#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))

// Delas med ISR
volatile boolean div32;
volatile boolean div16;
volatile boolean sampleFlag; 
volatile byte badc0; // ljudsample (ADC kanal 0)
volatile byte badc1; // potentiometer (ADC kanal 1)
volatile byte ibb;

int bufferIndex;
int bufferIndex2;

int soundSampleFromADC;
int soundSampleFromSramBuffer;
byte sramBufferSampleValue;
byte sramBuffer[512];

// --- NYA GLOBALA VARIABLER FÖR LÅGPASS ---
float lpAlpha = 0.5;      // alpha (0.0 - 1.0)
int lpFilteredSample = 127; // filtrerat sample, håll det i int

void setup()
{
  fillSramBufferWithWaveTable();
  Serial.begin(57600);

  // ADC prescaler 64 -> cirka 16MHz/64 = 250kHz ADC-clock (för TIM2-sampling)
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

  // Timer2 prescaler = 1
  sbi(TCCR2B, CS20);
  cbi(TCCR2B, CS21);
  cbi(TCCR2B, CS22);

  sbi(DDRB, 3); // pin 11 som PWM (OCR2A)

  cbi(TIMSK0, TOIE0);
  sbi(TIMSK2, TOIE2);

  // init filter state med ett neutralt värde (mitten)
  lpFilteredSample = 127;
  soundSampleFromADC = badc0;
}

// huvudloopen: vänta på nytt sample, läs badc0 och badc1, beräkna alpha, filter, skriv ut
void loop()
{
  // Vänta tills ett sample finns
  while (!sampleFlag) {
    // busy wait - sampleFlag sätts i ISR
  }

  sampleFlag = false;           // ta emot detta sample

  // kopiera atomärt (lokal kopia) för stabilitet
  uint8_t adc = badc0;          // ljudsample från kanal 0
  uint8_t pot = badc1;          // potentiometer från kanal 1

  // enligt instruktionen: begränsa pot till ~4% .. ~78% av 255
  const int POT_MIN = (int)round(0.04f * 255.0f); // ≈10
  const int POT_MAX = (int)round(0.78f * 255.0f); // ≈199

  int potC = pot;
  if (potC < POT_MIN) potC = POT_MIN;
  if (potC > POT_MAX) potC = POT_MAX;

  // mappa potC (POT_MIN..POT_MAX) till alpha (0.0..1.0) med flyttal
  lpAlpha = (float)(potC - POT_MIN) / (float)(POT_MAX - POT_MIN);
  if (lpAlpha < 0.0f) lpAlpha = 0.0f;
  if (lpAlpha > 1.0f) lpAlpha = 1.0f;

  // enligt instruktionen: soundSampleFromADC ska få badc0
  soundSampleFromADC = adc;

  // EMA / IIR-lågpass:
  // filtered[n] = alpha * input[n] + (1-alpha) * filtered[n-1]
  lpFilteredSample = (int)(lpAlpha * (float)soundSampleFromADC + (1.0f - lpAlpha) * (float)lpFilteredSample);

  // skriv ut till PWM
  OCR2A = (uint8_t)lpFilteredSample;

  // (valfritt) debugging via serial - kommentera bort om du får glitchar
  // Serial.print("adc:"); Serial.print(adc); Serial.print(" pot:"); Serial.print(pot);
  // Serial.print(" alpha:"); Serial.print(lpAlpha); Serial.print(" out:"); Serial.println(lpFilteredSample);
}

// tom funktion, finns kvar för kompatibilitet
void fillSramBufferWithWaveTable(){
  // inget behövs här för denna uppgift
}

// Timer2 overflow ISR -> trigger ADC-sampling (som i din originalkod)
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
      cbi(ADMUX, MUX0);      // växla till kanal 0
    }
    ibb++; ibb--; ibb++; ibb--;
    sbi(ADCSRA, ADSC);      // starta nästa conversion
  }
}
