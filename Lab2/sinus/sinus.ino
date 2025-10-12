#include <Arduino.h>
#include <math.h>

#define WAVETABLE_SIZE 512
#define SAMPLE_RATE 8000

byte sramBuffer[WAVETABLE_SIZE];    
volatile uint16_t bufferIndex = 0;    
volatile uint8_t stepValue = 1;

// Fyll bufferten med en sinusvåg 
void fillSramBufferWithSine() {
  float soundValue = 0.0;
  float delta = (2.0 * M_PI) / WAVETABLE_SIZE;  // ökning per steg i radianer

  for (int i = 0; i < WAVETABLE_SIZE; i++) {
    float sinusSample = 127.0 * sin(soundValue) + 127.0;  // -1 - 1 till 0 - 255
    sramBuffer[i] = (byte)round(sinusSample);
    soundValue += delta;
  }
}

// Timer1 interrupt
ISR(TIMER1_COMPA_vect) {
  uint8_t inc = (stepValue == 0) ? 1 : stepValue;
  bufferIndex = (bufferIndex + inc) & (WAVETABLE_SIZE - 1);
  OCR2A = sramBuffer[bufferIndex];
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
  fillSramBufferWithSine();   // fyll sinusvåg
  pinMode(11, OUTPUT);
  setupTimers();
}

void loop() {
  // Läs potentiometer A1 
  uint16_t pot = analogRead(A1);
  stepValue = pot >> 5;

  // Skicka värdet till Serial Plotter
  Serial.println(OCR2A);
}
