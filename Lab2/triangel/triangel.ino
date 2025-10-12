#include <Arduino.h>
#include <math.h>

#define WAVETABLE_SIZE 512
#define SAMPLE_RATE 8000

byte sramBuffer[WAVETABLE_SIZE];      // wavetable
volatile uint16_t bufferIndex = 0;    
volatile uint8_t stepValue = 1;

// Fyll bufferten med triangelvåg
void fillSramBufferWithTriangle() {
  float soundValue = 0.0;
  int halfSize = WAVETABLE_SIZE / 2;
  float step = 255.0 / halfSize;

  // stigande del
  for (int i = 0; i < halfSize; i++) {
    soundValue = step * i;
    sramBuffer[i] = (byte)round(soundValue);
  }
  // fallande del
  for (int i = 0; i < halfSize; i++) {
    soundValue = 255.0 - step * i;
    sramBuffer[i + halfSize] = (byte)round(soundValue);
  }
}

// Timer1 interrupt: spelar upp wavetable via PWM på pin 11
ISR(TIMER1_COMPA_vect) {
  uint8_t inc = (stepValue == 0) ? 1 : stepValue;
  bufferIndex = (bufferIndex + inc) & (WAVETABLE_SIZE - 1);
  OCR2A = sramBuffer[bufferIndex];
}

void setupTimers() {
  // Timer2: PWM på pin 11
  TCCR2A = _BV(COM2A1) | _BV(WGM21) | _BV(WGM20);
  TCCR2B = _BV(CS20);

  // Timer1: CTC mode för sample-interrupt
  TCCR1A = 0;
  TCCR1B = _BV(WGM12) | _BV(CS11);
  OCR1A = (uint16_t)((F_CPU / (8UL * SAMPLE_RATE)) - 1);
  TIMSK1 = _BV(OCIE1A);
}

void setup() {
  Serial.begin(115200);
  fillSramBufferWithTriangle();   // fyll triangelvåg
  pinMode(11, OUTPUT);
  setupTimers();
}

void loop() {
  // Läs potentiometer A1 (0..1023) och mappa till 0..31
  uint16_t pot = analogRead(A1);
  stepValue = pot >> 5;

  // Skicka värdet till Serial Plotter
  Serial.println(OCR2A);
}
