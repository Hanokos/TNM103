/* overdrive.ino
   Overdrive/distorsion för 8-bitars samplad signal (Arduino).
   In: ADC kanal 0 (ljud) -> badc0
       ADC kanal 1 (potentiometer) -> badc1
   Out: PWM OCR2A (pin 11)
   Använder Timer2 overflow ISR för ADC-sampling (samma schema som i labbmaterialet).
*/

#include <Arduino.h>
#include <math.h>

// --- hjälpmakron: definiera tidigt för att undvika preprocessor-problem ---
#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

// --- Delas med ISR ---
volatile boolean div32 = false;
volatile boolean div16 = false;
volatile boolean sampleFlag = false; 
volatile byte badc0 = 127; // ljudsample (ADC kanal 0)
volatile byte badc1 = 127; // potentiometer (ADC kanal 1)

int soundSampleFromADC = 127;     // inkommande sample (0..255)
byte sramBufferSampleValue = 127; // utgående sample

// --- setup och loop ---
void setup() {
  Serial.begin(57600);

  // ADC prescaler 64 -> ungefär som i tidigare exempel (justera vid behov)
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

  // Timer2: PWM fast mode på OC2A (pin 11)
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

  // Stäng Timer0 overflow interrupt (kan vara satt i andra projekt)
  cbi(TIMSK0, TOIE0);
  // Aktivera Timer2 overflow interrupt
  sbi(TIMSK2, TOIE2);

  // starta ADC konvertering
  sbi(ADCSRA, ADSC);

  // initvärden
  soundSampleFromADC = badc0;
  sramBufferSampleValue = 127;
}

void loop() {
  // Vänta på nytt sample från ISR
  while (!sampleFlag) {
    // busy wait - sampleFlag sätts i ISR
  }
  sampleFlag = false;

  // kopiera atomärt (lokal kopia)
  uint8_t adc = badc0; // ljud
  uint8_t pot = badc1; // potentiometer

  // spara inkommande i den variabel vi ombeds använda
  soundSampleFromADC = (int)adc;

  // Ta bort DC-offset: 8-bit ADC 0..255 -> centra runt 0: -127..+128
  int centered = (int)soundSampleFromADC - 127;

  // Mappa potentiometern till en gainfaktor.
  // Enligt labbinstruktion: se till att gain som lägst är 1 (annars blir det helt tyst).
  // Här mappar vi pot 0..255 -> gain 1.0 .. 4.0 (kan justeras).
  float potf = (float)pot / 255.0f;      // 0.0 .. 1.0
  float gain = 1.0f + potf * 3.0f;       // 1.0 .. 4.0

  // Multiplicera (i flyttal för smooth överdrive)
  float processed = (float)centered * gain;

  // Hårdlimitera för att undvika att PWM går utanför 8-bitars område
  if (processed > 127.0f) processed = 127.0f;
  if (processed < -127.0f) processed = -127.0f;

  // Återställ DC-offset och skriv i sramBufferSampleValue
  int outSample = (int)round(processed) + 127;
  if (outSample < 0) outSample = 0;
  if (outSample > 255) outSample = 255;
  sramBufferSampleValue = (byte)outSample;

  // Skriv till PWM-utgång
  OCR2A = sramBufferSampleValue;

  // (Valfritt) Debugging - kommentera bort vid realtidstest för att undvika glitchar
  // Serial.print("adc:"); Serial.print(adc);
  // Serial.print(" pot:"); Serial.print(pot);
  // Serial.print(" gain:"); Serial.print(gain);
  // Serial.print(" out:"); Serial.println(outSample);
}

// Timer2 overflow ISR -> trigger ADC-sampling (samma schema som i kursmaterialet)
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
    sbi(ADCSRA, ADSC);      // starta nästa conversion
  }
}
