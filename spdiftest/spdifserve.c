// g++ -O3 -c opl.cpp
// gcc spdifserve.c opl.o -o spdifserve -lpthread -lm -lwiringPi
// GPIO0    D24 (L19)		D0
// GPIO1    D25 (K17)		D1
// GPIO2    D2  (M16)		D2
// GPIO3    D4  (D17)		D3
// GPIO4    D6  (K21)		D4
// GPIO5    NC  (conflicting)
// GPIO6    D26 (K19)		D6
// GPIO7    D23 (L17)		D7
// GPIO8    D21 (M18)
// GPIO9    D18 (L22)
// GPIO10   D16 (M22)
// GPIO11   D20 (P16)
// GPIO12   D27 (P18)
// GPIO13   D28 (R15)
// GPIO14   D7  (K22)
// GPIO15   D9  (M21)
// GPIO16   D31 (T20)		D5
// GPIO17   NC  (conflicting)
// GPIO18   NC  (conflicting)
// GPIO19   D30 (R16)		WRCLK (OUTPUT: FPGA audio FIFO write clock)
// GPIO20   D33 (T18)		WRREQ (OUTPUT: FPGA audio FIFO write request)
// GPIO21   D35 (T15)		AREQ  (INPUT: FPGA audio FIFO request)
// GPIO22   D12 (R21)
// GPIO23   D13 (T22)
// GPIO24   D15 (N19)
// GPIO25   D19 (P17)
// GPIO26   D32 (T19)
// GPIO27   D10 (N21)

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <pthread.h>
#include <wiringPi.h>

#define D0 0
#define D1 1
#define D2 2
#define D3 3
#define D4 4
#define D5 16
#define D6 6
#define D7 7
#define WRCLK 19
#define WRREQ 20
#define AREQ 21

void setdata(unsigned char data) {
  digitalWrite(D0, data & 1); data >>= 1;
  digitalWrite(D1, data & 1); data >>= 1;
  digitalWrite(D2, data & 1); data >>= 1;
  digitalWrite(D3, data & 1); data >>= 1;
  digitalWrite(D4, data & 1); data >>= 1;
  digitalWrite(D5, data & 1); data >>= 1;
  digitalWrite(D6, data & 1); data >>= 1;
  digitalWrite(D7, data & 1);
}

void adlib_init(uint32_t samplerate);
void adlib_write(uintptr_t idx, uint8_t val);
void adlib_getsample(int16_t* sndptr, intptr_t numsamples);

void adlib(void) {
  short buf[128];
  int i;
  for(;;) {
    while(digitalRead(AREQ)==0);
    digitalWrite(WRREQ, 1);
    digitalWrite(WRREQ, 1);
    digitalWrite(WRREQ, 1);
    digitalWrite(WRREQ, 1);
    for(i=0; i<64; i++) {
      setdata(buf[2*i]>>8);
      digitalWrite(WRCLK, 1);
      digitalWrite(WRCLK, 1);
      digitalWrite(WRCLK, 1);
      digitalWrite(WRCLK, 1);
      digitalWrite(WRCLK, 0);
      digitalWrite(WRCLK, 0);
      digitalWrite(WRCLK, 0);
      digitalWrite(WRCLK, 0);
      setdata(buf[2*i]&255);
      digitalWrite(WRCLK, 1);
      digitalWrite(WRCLK, 1);
      digitalWrite(WRCLK, 1);
      digitalWrite(WRCLK, 1);
      digitalWrite(WRCLK, 0);
      digitalWrite(WRCLK, 0);
      digitalWrite(WRCLK, 0);
      digitalWrite(WRCLK, 0);
    }
    digitalWrite(WRREQ, 0);
    digitalWrite(WRREQ, 0);
    digitalWrite(WRREQ, 0);
    digitalWrite(WRREQ, 0);
    adlib_getsample(buf, 64);
  }
}

int main() {
  pthread_t th;
  unsigned char buffer[57306];
  int song_register, song_data, song_offset = 0, song_wait;
  FILE *f;
  int i, j, k;

  wiringPiSetupGpio();
  for(i=0; i<28; i++)
    pinMode(i, OUTPUT);
  pinMode(AREQ, INPUT);

  adlib_init(48000);
  pthread_create(&th, NULL, (void*)adlib, NULL);

  f = fopen("lemmings.raw", "rb");
  fread(buffer, 1, 57306, f);
  fclose(f);

  for(;;) {
    song_register = buffer[song_offset];
    song_offset++;
    if(song_register==0) {
      song_wait  = (buffer[song_offset+1] << 8) | buffer[song_offset+0];
      song_offset += 2;
      usleep(1786*song_wait);
    } else {
      song_data = buffer[song_offset]; song_offset++;
      song_wait = buffer[song_offset]; song_offset++;
      adlib_write(song_register, song_data);
      usleep(1786*song_wait);
    }
    if(song_offset>57300) {
      for(i=0; i<256; i++)
        adlib_write(i, 0);
      exit(0);
    }
  }

  return 0;
}
