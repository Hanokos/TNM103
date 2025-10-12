#include <Arduino.h>
#include <math.h>

#define WAVETABLE_SIZE 512
#define SAMPLE_RATE 8000   // Hz, samplingsfrekvens

byte sramBuffer[WAVETABLE_SIZE];
volatile uint16_t bufferIndex = 0;
volatile uint8_t stepValue = 1;   // uppdateras i loop

// Fyll bufferten med fyrkantsvåg (192 ↔ 64 runt 128)
void fillSramBufferWithWaveTable() {
  float soundValue = 0.0;
  for (int i = 0; i < WAVETABLE_SIZE; i++) {
    if (i < WAVETABLE_SIZE / 2) {
      soundValue = 192.0;
    } else {
      soundValue = 64.0;
    }
    sramBuffer[i] = (byte)round(soundValue);
  }
}

// Timer1 interrupt: spelar upp wavetable i SAMPLE_RATE Hz
ISR(TIMER1_COMPA_vect) {
  uint8_t inc = (stepValue == 0) ? 1 : stepValue;
  bufferIndex = (bufferIndex + inc) & (WAVETABLE_SIZE - 1);
  OCR2A = sramBuffer[bufferIndex];   // PWM-utgång (pin 11)
}

void setupTimers() {
  // Timer2: PWM på OC2A (pin 11)
  TCCR2A = _BV(COM2A1) | _BV(WGM21) | _BV(WGM20);
  TCCR2B = _BV(CS20); // prescaler = 1, ~62.5 kHz PWM-carrier

  // Timer1: CTC mode för samplings-interrupt
  TCCR1A = 0;
  TCCR1B = _BV(WGM12) | _BV(CS11);   // CTC, prescaler 8
  OCR1A = (uint16_t)((F_CPU / (8UL * SAMPLE_RATE)) - 1);
  TIMSK1 = _BV(OCIE1A);
}

void setup() {
  Serial.begin(115200);
  fillSramBufferWithWaveTable();
  pinMode(11, OUTPUT);
  setupTimers();
}

void loop() {
  // Läs potentiometer A1 (0..1023), mappa till 0..31
  uint16_t pot = analogRead(A1);
  stepValue = pot >> 5;  // 0..31, där 0 hanteras som 1 i ISR

  // Skicka PWM-värdet till Serial Plotter (för att se vågformen)
  Serial.println(OCR2A);
}
