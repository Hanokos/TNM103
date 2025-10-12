/* Arduino Realtime Audio Processing
   2 ADC 8-Bit Mode
   analog input 0 is used to sample the audio signal
   analog input 1 is used to control an audio effect
   PWM DAC with Timer2 as analog output
   
   Original idea:
   KHM 2008 / Lab3/  Martin Nawrath nawrath@khm.de
   Kunsthochschule fuer Medien Koeln
   Academy of Media Arts Cologne
    
   Redeveloped by Niklas Rönnberg
   Linköping university
   For the course Ljudteknik 1
*/

#include <Arduino.h>
#include <math.h>

//  cbi = Clear Bit, sbi = Set Bit i I/O-register
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))

//  Globala variabler för sampling 
volatile boolean div32;
volatile boolean div16;
volatile boolean sampleFlag; 
volatile byte badc0; // ljudsample (ADC kanal 0)
volatile byte badc1; // potentiometer (ADC kanal 1)
volatile byte ibb;

//  Globala variabler för reverb 
#define WAVETABLE_SIZE 512
byte sramBuffer[WAVETABLE_SIZE];
volatile uint16_t bufferIndex;

int soundSampleFromADC;           // senaste ljudsample
byte sramBufferSampleValue;       // ut-sample (0..255)

//  Tom funktion för kompatibilitet
void fillSramBufferWithWaveTable() { }

void setup()
{
  Serial.begin(57600);

  // --- ADC-inställningar ---
  cbi(ADCSRA, ADPS2);
  sbi(ADCSRA, ADPS1);
  sbi(ADCSRA, ADPS0);

  sbi(ADMUX, ADLAR);   // 8-bit ADC i ADCH
  sbi(ADMUX, REFS0);   // VCC som referens
  cbi(ADMUX, REFS1);
  cbi(ADMUX, MUX0);    // starta på kanal 0
  cbi(ADMUX, MUX1);
  cbi(ADMUX, MUX2);
  cbi(ADMUX, MUX3);

  // --- TIMER2 för PWM-utgång ---
  cbi(TCCR2A, COM2A0);
  sbi(TCCR2A, COM2A1);
  sbi(TCCR2A, WGM20);
  sbi(TCCR2A, WGM21);
  cbi(TCCR2B, WGM22);

  sbi(TCCR2B, CS20);   // prescaler = 1
  cbi(TCCR2B, CS21);
  cbi(TCCR2B, CS22);

  sbi(DDRB, 3);        // pin 11 som PWM-utgång (OCR2A)

  cbi(TIMSK0, TOIE0);
  sbi(TIMSK2, TOIE2);

  // --- Initiera buffert till mittvärde ---
  for (int i = 0; i < WAVETABLE_SIZE; ++i) sramBuffer[i] = 127;
  bufferIndex = 0;
  sramBufferSampleValue = 127;
  soundSampleFromADC = 127;

  // Starta första ADC-konverteringen
  sbi(ADCSRA, ADSC);
}

void loop()
{
  // --- Vänta tills nytt sample finns ---
  while (!sampleFlag) {}
  sampleFlag = false;

  uint8_t adc = badc0;   // inkommande ljud 0..255
  uint8_t pot = badc1;   // potentiometer 0..255

  // --- Läs från buffer, ta bort DC-offset och vänd fas ---
  uint8_t bufRaw = sramBuffer[bufferIndex];
  int bufCentered = (int)bufRaw - 127;   // centrera
  int bufInverted = -bufCentered;        // invertera fas

  // --- Mappa potentiometern till feedback-styrka (0..240) ---
  int fb = map((int)pot, 0, 255, 0, 240);

  // --- Skala feedback enligt potentiometern (heltal) ---
  long scaled = ((long)bufInverted * (long)fb) / 255L; // -127..+127 ungefär

  // --- Ta bort DC-offset från inkommande ljud ---
  soundSampleFromADC = (int)adc - 127;   // -127..+128

  // --- Summera inkommande ljud + dämpad feedback ---
  long combined = (long)soundSampleFromADC + scaled;

  // --- Hård limitering för att undvika överstyrning ---
  if (combined > 127L) combined = 127L;
  if (combined < -127L) combined = -127L;

  // --- Lägg tillbaka DC-offset och skriv till buffert ---
  int outSample = (int)combined + 127;
  if (outSample < 0) outSample = 0;
  if (outSample > 255) outSample = 255;

  sramBuffer[bufferIndex] = (uint8_t)outSample;  // feedback i buffer

  // --- Skicka till PWM-utgång ---
  sramBufferSampleValue = (uint8_t)outSample;
  OCR2A = sramBufferSampleValue;

  // --- Öka index och håll inom buffert ---
  bufferIndex = (bufferIndex + 1) % WAVETABLE_SIZE;
}

// --- Timer2 overflow ISR -> triggar ADC-sampling ---
ISR(TIMER2_OVF_vect)
{
  div32 = !div32;
  if (div32) {
    div16 = !div16;
    if (div16) {
      badc0 = ADCH;          // sampla kanal 0
      sbi(ADMUX, MUX0);      // växla till kanal 1
      sampleFlag = true;
    } else {
      badc1 = ADCH;          // sampla kanal 1
      cbi(ADMUX, MUX0);      // växla tillbaka till kanal 0
    }
    ibb++; ibb--; ibb++; ibb--;
    sbi(ADCSRA, ADSC);       // starta nästa ADC-konvertering
  }
}
