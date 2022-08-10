/*
gcc pcserv7.c opl.o -lwiringPi -lpthread -lm
*/

#include <sched.h>
#include <termios.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <wiringPi.h>

#define DI0        0
#define DI1        1
#define DI2        2
#define DI3        3
#define DI4        4
#define DI5        5
#define DI6        6
#define DI7        7

#define DO0        8
#define DO1        9
#define DO2       10
#define DO3       11
#define DO4       12
#define DO5       13
#define DO6       14
#define DO7       15

#define AD        16

#define FIFO1_DAT 17
#define FIFO1_CLK 18
#define FIFO1_ADR 19

#define FIFO2_CLK 20

#define ACLK      22
#define AREQ      23
#define AACK      24

unsigned char ind() {
  unsigned char data;
  data  = digitalRead(DI7); data <<= 1;
  data |= digitalRead(DI6); data <<= 1;
  data |= digitalRead(DI5); data <<= 1;
  data |= digitalRead(DI4); data <<= 1;
  data |= digitalRead(DI3); data <<= 1;
  data |= digitalRead(DI2); data <<= 1;
  data |= digitalRead(DI1); data <<= 1;
  data |= digitalRead(DI0);
  return data;
}

void outd(unsigned char data) {
  digitalWrite(DO0, data & 1); data >>= 1;
  digitalWrite(DO1, data & 1); data >>= 1;
  digitalWrite(DO2, data & 1); data >>= 1;
  digitalWrite(DO3, data & 1); data >>= 1;
  digitalWrite(DO4, data & 1); data >>= 1;
  digitalWrite(DO5, data & 1); data >>= 1;
  digitalWrite(DO6, data & 1); data >>= 1;
  digitalWrite(DO7, data & 1);
}

void FIFO1CLK() {
  digitalWrite(FIFO1_CLK, 1);
  digitalWrite(FIFO1_CLK, 1);
  digitalWrite(FIFO1_CLK, 1);
  digitalWrite(FIFO1_CLK, 0);
  digitalWrite(FIFO1_CLK, 0);
  digitalWrite(FIFO1_CLK, 0);
}

void FIFO1ADR() {
  digitalWrite(FIFO1_ADR, 1);
  digitalWrite(FIFO1_ADR, 1);
  digitalWrite(FIFO1_ADR, 1);
  digitalWrite(FIFO1_ADR, 0);
  digitalWrite(FIFO1_ADR, 0);
  digitalWrite(FIFO1_ADR, 0);
}

void FIFO2CLK() {
  digitalWrite(FIFO2_CLK, 1);
  digitalWrite(FIFO2_CLK, 1);
  digitalWrite(FIFO2_CLK, 1);
  digitalWrite(FIFO2_CLK, 0);
  digitalWrite(FIFO2_CLK, 0);
  digitalWrite(FIFO2_CLK, 0);
}

/*
void adlib_init(uint32_t samplerate);
void adlib_write(uintptr_t idx, uint8_t val);
void adlib_getsample(int16_t* sndptr, intptr_t numsamples);

int adlib_busy, adlib_sample;
short buf[128];

void adlib(void) {
  char j, k;
  for(;;) {
    j = digitalRead(AREQ);
    if(j==1 && k==0) {
      adlib_getsample(buf, 64);
      adlib_busy = 64;
    }
    k = j;
  }
}
*/

int main(void) {
  int rd = 0, wr = 0, sn = 0, lba = 0, chs = 0, c = 0, h = 0, s = 0, i;
  unsigned char addr, data, *hdd, areg;
  FILE *hdd_file;
  pthread_t th;

  s = 512*256*16*63;
  hdd = (unsigned char*)malloc(s);
  printf("Reading...\n");
  hdd_file = fopen("compact.img", "rb");
  c = fread(hdd, 1, s, hdd_file);
  printf("...got %d bytes\n", c);
  fclose(hdd_file);

  wiringPiSetupGpio();

  pinMode(DI0, INPUT);
  pinMode(DI1, INPUT);
  pinMode(DI2, INPUT);
  pinMode(DI3, INPUT);
  pinMode(DI4, INPUT);
  pinMode(DI5, INPUT);
  pinMode(DI6, INPUT);
  pinMode(DI7, INPUT);

  pinMode(DO0, OUTPUT);
  pinMode(DO1, OUTPUT);
  pinMode(DO2, OUTPUT);
  pinMode(DO3, OUTPUT);
  pinMode(DO4, OUTPUT);
  pinMode(DO5, OUTPUT);
  pinMode(DO6, OUTPUT);
  pinMode(DO7, OUTPUT);

  pinMode(AD, INPUT);
  pinMode(FIFO1_DAT, INPUT);
  pinMode(FIFO1_CLK, OUTPUT);
  pinMode(FIFO1_ADR, OUTPUT);
  pinMode(FIFO2_CLK, OUTPUT);

//  pinMode(AREQ, INPUT);
//  pinMode(ACLK, OUTPUT);
//  pinMode(AACK, OUTPUT);

//  adlib_init(48000);
//  pthread_create(&th, NULL, (void*)adlib, NULL);

  for(;;) {
    FIFO1CLK();
    if(digitalRead(FIFO1_DAT)) {
      FIFO1ADR();
      FIFO1CLK();
      FIFO1CLK();
      data = ind();
      if(digitalRead(AD)) addr = data;
      else {
        if(addr==0x70) {
          if(data==0) { rd = 0; wr = 512; chs=0; }
          if(data==1) { rd = 512; wr = 0; }
        }
        if(addr==0x71) {
               if(chs==0) { c = data; chs++; }
          else if(chs==1) { h = data; chs++; }
          else if(chs==2) { s = data; chs++;
            lba = 512*(63*(16*c+h)+s-1); }
          else if(wr) hdd[lba++] = data;
        }
//        if(addr==0x88) areg = data;
//        if(addr==0x89) adlib_write(areg, data);
      }
    }
    if(rd) {
      outd(hdd[lba++]);
      FIFO2CLK();
      rd = rd - 1;
    }
/*
    if(adlib_busy) {
      outd(buf[2*(64-adlib_busy)]>>8);
      digitalWrite(ACLK, 1);
      digitalWrite(ACLK, 1);
      digitalWrite(ACLK, 1);
      digitalWrite(ACLK, 0);
      digitalWrite(ACLK, 0);
      digitalWrite(ACLK, 0);
      adlib_busy--;
    }
*/
  }
  return 0;
}
