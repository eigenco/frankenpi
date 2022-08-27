/*
g++ -c opl.cpp; g++ -c gus.cpp; gcc pc.c opl.o gus.o -lwiringPi -lm -lpthread -lstdc++
g++ -O0 -c gus.cpp; gcc -O0 pc.c opl.o gus.o -lwiringPi -lm -lpthread -lstdc++
*/

#include <sched.h>
#include <termios.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <wiringPi.h>

typedef uintptr_t          Bitu;
typedef intptr_t           Bits;
typedef uint32_t           Bit32u;
typedef int32_t            Bit32s;
typedef uint16_t           Bit16u;
typedef int16_t            Bit16s;
typedef uint8_t            Bit8u;
typedef int8_t             Bit8s;

void init_gus(void);
void write_gus(int addr, int data, int ibit);
void get_samples(short *buf);

#define DI0           0
#define DI1           1
#define DI2           2
#define DI3           3
#define DI4           4
#define DI5           5
#define DI6           6
#define DI7           7
#define DI8           8

#define DO0           9
#define DO1          10
#define DO2          11
#define DO3          12
#define DO4          13
#define DO5          14
#define DO6          15
#define DO7          16

#define CLOCK        17
#define FPGA_TX_REQ  18
#define FPGA_RX_REQ  19

#define STATE0       20
#define STATE1       21
#define STATE2       22

#define FPGA_SYNC     0
#define FPGA_TX_FIFO  1
#define FPGA_RX_FIFO  2
#define FPGA_AU_FIFO  3
#define FPGA_HD_FIFO  4

void adlib_init(uint32_t samplerate);
void adlib_write(uintptr_t idx, uint8_t val);
void adlib_getsample(int16_t* sndptr, intptr_t numsamples);

int audio_busy = 0;
short buf[128];

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

void set_state(unsigned char state) {
  digitalWrite(STATE0, state & 1); state >>= 1;
  digitalWrite(STATE1, state & 1); state >>= 1;
  digitalWrite(STATE2, state & 1);
}

void CLK() {
  digitalWrite(CLOCK, 1);
  digitalWrite(CLOCK, 1);
  digitalWrite(CLOCK, 1);
  digitalWrite(CLOCK, 0);
  digitalWrite(CLOCK, 0);
  digitalWrite(CLOCK, 0);
}

void adlib_worker(void) {
  for(;;)
    if(digitalRead(FPGA_RX_REQ) && audio_busy==0) {
      adlib_getsample(buf, 64);
      audio_busy = 64;
    }
}

void gus_worker(void) {
  unsigned int i = 0, j = 0, k = 0;
  for(;;) {
    if(digitalRead(FPGA_RX_REQ) && audio_busy==0) {
      get_samples(buf);
      audio_busy = 64;
    }
  }
}

unsigned char reverse[256];

int main(void) {
  int rd = 0, wr = 0, lba = 0, chs = 0, c = 0, h = 0, s = 0, i = 0, j, autoamp = 512;
  char mouse_buttons, mouse_dx, mouse_dy;
  unsigned char addr, data, *hdd, areg;
  FILE *hdd_file;
  pthread_t th;

  for(i=0; i<256; i++)
    reverse[i] = ((i&0x80)>>7)|((i&0x40)>>5)|((i&0x20)>>3)|((i&0x10)>>1)|((i&8)<<1)|((i&4)<<3)|((i&2)<<5)|((i&1)<<7);

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
  pinMode(DI8, INPUT);

  pinMode(DO0, OUTPUT);
  pinMode(DO1, OUTPUT);
  pinMode(DO2, OUTPUT);
  pinMode(DO3, OUTPUT);
  pinMode(DO4, OUTPUT);
  pinMode(DO5, OUTPUT);
  pinMode(DO6, OUTPUT);
  pinMode(DO7, OUTPUT);

  pinMode(CLOCK, OUTPUT);
  pinMode(FPGA_TX_REQ, INPUT);
  pinMode(FPGA_RX_REQ, INPUT);
  pinMode(STATE0, OUTPUT);
  pinMode(STATE1, OUTPUT);
  pinMode(STATE2, OUTPUT);

  //adlib_init(44100);
  //pthread_create(&th, NULL, (void*)adlib_worker, NULL);

  init_gus();
  pthread_create(&th, NULL, (void*)gus_worker, NULL);

  for(;;) {
    set_state(FPGA_SYNC);
    CLK();

    if(digitalRead(FPGA_TX_REQ)) {
      set_state(FPGA_TX_FIFO);                  // read from FPGA_TX_FIFO
      CLK(); CLK(); CLK();
      data = ind();
      if(digitalRead(DI8)) addr = data;
      else {
	if(addr>0x3F && addr<0x50) {            // gravis ultrasound
          write_gus(0x300|addr, data, 1);
        }
        if(addr==0x70) {                        // HDD control/status port
          if(data==0) { rd = 0; wr = 512; chs=0; }
          if(data==1) { rd = 512; wr = 0; }
        }
        if(addr==0x71) {                        // HDD read/write port
          if(chs==0) { c = data; chs++; }
          else if(chs==1) { h = data; chs++; }
          else if(chs==2) { s = data; chs++; lba = 512*(63*(16*c+h)+s-1); }
          else if(wr) hdd[lba++] = data;
        }
/*
        if(addr==0x72) {                        // respond with mouse state
          set_state(4);
          outd(mouse_buttons); CLK();
          outd(mouse_dx); CLK();
          outd(mouse_dy); CLK();
        }
*/
        if(addr==0x88) areg = data;             // ADLIB register port
        if(addr==0x89) adlib_write(areg, data); // ADLIB data port
      }
    }

    if(audio_busy) {
      set_state(FPGA_AU_FIFO);
      outd(buf[2*(64-audio_busy)]>>8);
      digitalWrite(CLOCK, 1);
      digitalWrite(CLOCK, 1);
      digitalWrite(CLOCK, 1);
      outd(buf[2*(64-audio_busy)]&255);
      digitalWrite(CLOCK, 0);
      digitalWrite(CLOCK, 0);
      digitalWrite(CLOCK, 0);
      outd(buf[2*(64-audio_busy)+1]>>8);
      digitalWrite(CLOCK, 1);
      digitalWrite(CLOCK, 1);
      digitalWrite(CLOCK, 1);
      outd(buf[2*(64-audio_busy)+1]&255);
      digitalWrite(CLOCK, 0);
      digitalWrite(CLOCK, 0);
      digitalWrite(CLOCK, 0);
      CLK();
      audio_busy--;
    }

    if(rd) {
      set_state(FPGA_HD_FIFO);
      outd(hdd[lba++]);
      CLK();
      rd--;
    }
/*
    if(digitalRead(FPGA_RX_REQ)) i++;
    if(j++==1000000) {
      printf("busy %f\n", 100.0*i/j);
      i = 0;
      j = 0;
    }
*/
  }
  return 0;
}
