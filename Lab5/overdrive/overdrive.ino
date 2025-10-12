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

#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))

//  Globala variabler för sampling 
volatile boolean div32;
volatile boolean div16;
volatile boolean sampleFlag; 
volatile byte badc0; // ljudsample ADC kanal 0
volatile byte badc1; // potentiometer ADC kanal 1
volatile byte ibb;

//  Variabler för overdrive
int soundSampleFromADC = 127;     
byte sramBufferSampleValue = 127; 

void setup()
{
  Serial.begin(57600);

  //  ADC-inställning 
  cbi(ADCSRA, ADPS2);
  sbi(ADCSRA, ADPS1);
  sbi(ADCSRA, ADPS0);

  sbi(ADMUX, ADLAR);  
  sbi(ADMUX, REFS0);  
  cbi(ADMUX, REFS1);
  cbi(ADMUX, MUX0);   
  cbi(ADMUX, MUX1);
  cbi(ADMUX, MUX2);
  cbi(ADMUX, MUX3);

  //  TIMER2 för PWM-utgång 
  cbi(TCCR2A, COM2A0);
  sbi(TCCR2A, COM2A1);
  sbi(TCCR2A, WGM20);
  sbi(TCCR2A, WGM21);
  cbi(TCCR2B, WGM22);

  sbi(TCCR2B, CS20);  
  cbi(TCCR2B, CS21);
  cbi(TCCR2B, CS22);

  sbi(DDRB, 3); // pin 11 som PWM

  cbi(TIMSK0, TOIE0);
  sbi(TIMSK2, TOIE2);

  sbi(ADCSRA, ADSC);
  soundSampleFromADC = badc0;
  sramBufferSampleValue = 127;
}

void loop()
{
  // Vänta tills ett nytt sample finns
  while (!sampleFlag) {}
  sampleFlag = false;

  uint8_t adc = badc0;   // ljudsample
  uint8_t pot = badc1;   // potentiometer (styr gain)
  soundSampleFromADC = adc;

  //  Ta bort DC-offset 
  int centered = (int)soundSampleFromADC - 127;

  //  Mappa potentiometer till gain (1.0 – 4.0)
  float potf = (float)pot / 255.0f;
  float gain = 1.0f + potf * 3.0f;

  //  Multiplicera med gain 
  float processed = (float)centered * gain;

  //  Hård limitering
  if (processed > 127.0f) processed = 127.0f;
  if (processed < -127.0f) processed = -127.0f;

  //  Lägg tillbaka DC-offset och begränsa
  int outSample = (int)round(processed) + 127;
  if (outSample < 0) outSample = 0;
  if (outSample > 255) outSample = 255;
  sramBufferSampleValue = (byte)outSample;

  //  Skicka till PWM-utgång 
  OCR2A = sramBufferSampleValue;
}

// Timer2 overflow ISR -> trigger ADC-sampling
ISR(TIMER2_OVF_vect)
{
  div32 = !div32;
  if (div32) {
    div16 = !div16;
    if (div16) {
      badc0 = ADCH;           // sampla kanal 0
      sbi(ADMUX, MUX0);       // växla till kanal 1
      sampleFlag = true;
    } else {
      badc1 = ADCH;           // sampla kanal 1
      cbi(ADMUX, MUX0);       // växla tillbaka till kanal 0
    }
    ibb++; ibb--; ibb++; ibb--;
    sbi(ADCSRA, ADSC);        // starta nästa ADC-konversion
  }
}
