#include <Arduino.h>
#include <math.h>

#define WAVETABLE_SIZE 512
#define SAMPLE_RATE 8000

byte sramBuffer[WAVETABLE_SIZE];
volatile uint16_t bufferIndex = 0;
volatile uint8_t stepValue = 1;

// Skapa mix av sågtand och sinus 
void fillSramBufferWithSawAndSine() {
  float soundValue = 0.0;
  float delta = (2.0 * M_PI) / WAVETABLE_SIZE;   // stegstorlek för sinus
  float stepSaw = 255.0 / WAVETABLE_SIZE;        // stegstorlek för sågtand

  for (int i = 0; i < WAVETABLE_SIZE; i++) {
    // Sågtandsvåg: 0-255 skala om till -127-127
    float sawSample = (stepSaw * i) - 127.0;

    // Sinusvåg: -1 - 1 -> skala till -127-127
    float sinSample = 127.0 * sin(soundValue);
    soundValue += delta;

    // Dela med 2
    float mixed = (sawSample + sinSample) / 2.0;

    // Lägg till DC-offset +127 för att få 0-255
    sramBuffer[i] = (byte)round(mixed + 127.0);
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
  fillSramBufferWithSawAndSine();   // fyll mixad våg
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
