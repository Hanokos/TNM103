#include <Arduino.h>
#include <math.h>

#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))

//  Globala variabler för sampling 
volatile boolean div32;
volatile boolean div16;
volatile boolean sampleFlag; 
volatile byte badc0; // ljudsample ADC kanal 0
volatile byte badc1; // potentiometer ADC kanal 1
volatile byte ibb;

//  Globala variabler för reverb
#define WAVETABLE_SIZE 512
byte sramBuffer[WAVETABLE_SIZE];
volatile uint16_t bufferIndex;

int soundSampleFromADC;           // senaste ljudsample
int soundSampleFromSramBuffer;    // sample läst från buffer (centrerat och inverterat)
byte sramBufferSampleValue;       // slutligt ut-sample (0..255)

void fillSramBufferWithWaveTable() { } // tom för kompatibilitet

void setup()
{
  Serial.begin(57600);

  // ADC
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

  // TIMER2
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

  // init
  for (int i = 0; i < WAVETABLE_SIZE; ++i) sramBuffer[i] = 127;
  bufferIndex = 0;
  sramBufferSampleValue = 127;
  soundSampleFromADC = 127;

  // starta ADC
  sbi(ADCSRA, ADSC);
}

void loop()
{
  // Vänta tills ett sample finns
  while (!sampleFlag) {}
  sampleFlag = false;

  uint8_t adc = badc0;   // ljudsample 0..255
  uint8_t pot = badc1;   // potentiometer 0..255

  // Läs från buffer (0..255), ta bort DC-offset och vänd fas
  uint8_t bufRaw = sramBuffer[bufferIndex];
  int bufCentered = (int)bufRaw - 127;   // -127 .. +128
  int bufInverted = -bufCentered;        // inverterad fas
  soundSampleFromSramBuffer = bufInverted;

  // Mappa potentiometer till feedback-skalning 0..240 (heltal)
  int fbMin = 0;
  int fbMax = 240; // prova 240..250 vid behov
  int fb = map((int)pot, 0, 255, fbMin, fbMax); // 0..240

  // Multiplicera och skala (heltal)
  long scaled = ((long)bufInverted * (long)fb) / 255L; // -127..127 ungefär

  // Ta bort DC-offset från inkommande sample
  soundSampleFromADC = (int)adc;
  int inCentered = soundSampleFromADC - 127; // -127 .. +128

  // Summera inkommande och skalad buffert
  long combined = (long)inCentered + scaled;

  // Hård limitering -127..127
  if (combined > 127L) combined = 127L;
  if (combined < -127L) combined = -127L;

  // Lägg tillbaka DC-offset och spara i buffer
  int outSample = (int)combined + 127;
  if (outSample < 0) outSample = 0;
  if (outSample > 255) outSample = 255;

  sramBuffer[bufferIndex] = (uint8_t)outSample; // feedback i buffern

  // Skicka till PWM
  sramBufferSampleValue = (uint8_t)outSample;
  OCR2A = sramBufferSampleValue;

  // Öka index med modulo (%)
  bufferIndex = (bufferIndex + 1) % WAVETABLE_SIZE;
}

// Timer2 overflow ISR -> trigger ADC-sampling
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
