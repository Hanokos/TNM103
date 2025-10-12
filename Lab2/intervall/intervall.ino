#include <Arduino.h>
#include <math.h>

#define WAVETABLE_SIZE 512
#define SAMPLE_RATE 8000

byte sramBuffer[WAVETABLE_SIZE];
volatile uint16_t bufferIndex1 = 0;
volatile uint16_t bufferIndex2 = 0;
volatile uint8_t stepValue1 = 1;  // grundton
volatile uint8_t stepValue2 = 2;  // andra tonen 

// sinusvåg 
void fillSramBufferWithSine() {
  float soundValue = 0.0;
  float delta = (2.0 * M_PI) / WAVETABLE_SIZE;

  for (int i = 0; i < WAVETABLE_SIZE; i++) {
    float sinSample = 127.0 * sin(soundValue); // -127-127
    sramBuffer[i] = (byte)round(sinSample + 127.0); //  0-255
    soundValue += delta;
  }
}

// Timer1 interrupt: två toner 
ISR(TIMER1_COMPA_vect) {
  uint8_t inc1 = (stepValue1 == 0) ? 1 : stepValue1;
  uint8_t inc2 = (stepValue2 == 0) ? 1 : stepValue2;

  bufferIndex1 = (bufferIndex1 + inc1) & (WAVETABLE_SIZE - 1);
  bufferIndex2 = (bufferIndex2 + inc2) & (WAVETABLE_SIZE - 1);

  // Hämta båda samplen
  int16_t sample1 = (int16_t)sramBuffer[bufferIndex1] - 127; 
  int16_t sample2 = (int16_t)sramBuffer[bufferIndex2] - 127; 

  // Summera,  /2 och  offset
  int16_t mixed = (sample1 + sample2) / 2;
  OCR2A = (byte)(mixed + 127);
}

void setupTimers() {
  // Timer2
  TCCR2A = _BV(COM2A1) | _BV(WGM21) | _BV(WGM20);
  TCCR2B = _BV(CS20);

  // Timer1 CTC
  TCCR1A = 0;
  TCCR1B = _BV(WGM12) | _BV(CS11);
  OCR1A = (uint16_t)((F_CPU / (8UL * SAMPLE_RATE)) - 1);
  TIMSK1 = _BV(OCIE1A);
}

void setup() {
  Serial.begin(115200);
  fillSramBufferWithSine();   // fyll wavetable med sinus
  pinMode(11, OUTPUT);
  setupTimers();
}

void loop() {
  // Läs potentiometer A1 
  uint16_t pot = analogRead(A1);
  stepValue1 = pot >> 5;  // FÖrsta  tonen

 
  // oktav ned =halva steget
  stepValue2 = stepValue1 / 2; // andra tonen

  // Skicka till Serial Plotter för debug
  Serial.println(OCR2A);
}
