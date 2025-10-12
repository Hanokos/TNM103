#include <Arduino.h>
#include <math.h>

#define WAVETABLE_SIZE 512
#define SAMPLE_RATE 8000

byte sramBuffer[WAVETABLE_SIZE];
volatile uint16_t bufferIndex = 0;
volatile uint8_t stepValue = 1;

// Fyll bufferten med en sågtandsvåg
void fillSramBufferWithSawtooth() {
  float soundValue = 0.0;
  float step = 255.0 / WAVETABLE_SIZE;  // 255/512

  for (int i = 0; i < WAVETABLE_SIZE; i++) {
    soundValue = step * i;    //soundValue = 255 - step * i;  // fallande från 255 till 0
    sramBuffer[i] = (byte)round(soundValue);  // avrunda till byte
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

  // Timer1: CTC
  TCCR1A = 0;
  TCCR1B = _BV(WGM12) | _BV(CS11);
  OCR1A = (uint16_t)((F_CPU / (8UL * SAMPLE_RATE)) - 1);
  TIMSK1 = _BV(OCIE1A);
}

void setup() {
  Serial.begin(115200);
  fillSramBufferWithSawtooth();
  pinMode(11, OUTPUT);
  setupTimers();
}

void loop() {
  uint16_t pot = analogRead(A1);
  stepValue = pot >> 5;

  // Skicka värdet till Serial Plotter
  Serial.println(OCR2A);
}
