/*
g++ -O0 -c opl.cpp;g++ -O0 -c gus.cpp ; g++ -O0 pc.cpp opl.o gus.o -lwiringPi -lm -lpthread -o pc
*/

#include <unistd.h>
#include <fcntl.h>
#include <sched.h>
#include <termios.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <wiringPi.h>

void init_gus(void);
void write_gus(uint16_t addr, uint8_t data);
void GUS_CallBack(uint16_t len);
uint32_t rx_read = 0;
uint32_t rx_write = 0;
uint8_t audio_busy = 0;
uint8_t adlib_req = 0;
uint8_t gus_req = 0;
uint8_t rx_buf[256];
int16_t buf16[128];
int16_t buf[128];
void adlib_init(uint32_t samplerate);
void adlib_write(uint16_t idx, uint8_t val);
void adlib_getsample(short* sndptr, short numsamples);
uint8_t wg_addr[65536];
uint8_t wg_data[65536];
uint16_t wg_rx;
uint16_t wg_tx;
uint8_t hdd_flush = 0;

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

void* adlib_worker(void*) {
  for(;;)
    if(adlib_req==1) {
      adlib_getsample(buf, 64);
      adlib_req = 2;
    }
  return NULL;
}

void* gus_worker(void*) {
  for(;;) {
    if(gus_req==1) {
      GUS_CallBack(64);
      gus_req = 2;
    }
  }
  return NULL;
}

void *mouse_worker(void *) {
  int mfile;
  char data[3];
  const char *mdev = "/dev/input/mouse0";

  mfile = open(mdev, O_RDONLY);
  for(;;)
    if(!audio_busy)
      if(read(mfile, data, 3)==3) {
        rx_buf[((rx_write<<2)  )&255] = 0x33;
        rx_buf[((rx_write<<2)|1)&255] = data[0];
        rx_buf[((rx_write<<2)|2)&255] = data[1];
        rx_buf[((rx_write<<2)|3)&255] = data[2];
        rx_write++;
      }
}

int main(void) {
  int rd = 0, wr = 0, lba = 0, chs = 0, c = 0, h = 0, s = 0, i = 0, j;
  unsigned char addr, data, *hdd, areg;
  unsigned char blocks[256*16*63]; // keeps track of written blocks
  FILE *hdd_file;
  pthread_t tha, thg, thm;

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

  init_gus();
  adlib_init(44100);
  pthread_create(&thg, NULL, gus_worker, NULL);
  pthread_create(&tha, NULL, adlib_worker, NULL);
  pthread_create(&thm, NULL, mouse_worker, NULL);

  for(;;) {
    set_state(FPGA_SYNC);
    CLK();

    if(digitalRead(FPGA_TX_REQ)) {
      set_state(FPGA_TX_FIFO);                  // read from FPGA_TX_FIFO
      CLK(); CLK(); CLK();
      data = ind();
      if(digitalRead(DI8)) addr = data;
      else {
	if(addr>0x40 && addr<0x49) {            // gravis ultrasound
          write_gus(0x300|addr, data);
        }
        if(addr==0x70) {                        // HDD control/status port
          if(data==0) { rd = 0; wr = 512; chs=0; }
          if(data==1) { rd = 512; wr = 0; }
          if(data==2) {
            printf("Writing...\n");
            hdd_file = fopen("compact.img", "wb");
            i = fwrite(hdd, 1, 512*256*16*63, hdd_file);
            fclose(hdd_file);
            printf("...wrote %d bytes\n", i);
          }
        }
        if(addr==0x71) {                        // HDD read/write port
          if(chs==0) { c = data; chs++; }
          else if(chs==1) { h = data; chs++; }
          else if(chs==2) { s = data; chs++; lba = 512*(63*(16*c+h)+s-1); }
          else if(wr) { blocks[lba>>9] = 1; hdd[lba++] = data; }
        }
        if(addr==0x88) areg = data;             // ADLIB register port
        if(addr==0x89) adlib_write(areg, data); // ADLIB data port
      }
    }

    if(audio_busy) {
      set_state(FPGA_AU_FIFO);
      outd((buf[(64-audio_busy)<<1]>>8)|(buf16[(64-audio_busy)<<1]>>8));
      digitalWrite(CLOCK, 1);
      digitalWrite(CLOCK, 1);
      digitalWrite(CLOCK, 1);
      outd((buf[(64-audio_busy)<<1]&255)|(buf16[(64-audio_busy)<<1]&255));
      digitalWrite(CLOCK, 0);
      digitalWrite(CLOCK, 0);
      digitalWrite(CLOCK, 0);
      outd((buf[((64-audio_busy)<<1)+1]>>8)|(buf16[((64-audio_busy)<<1)+1]>>8));
      digitalWrite(CLOCK, 1);
      digitalWrite(CLOCK, 1);
      digitalWrite(CLOCK, 1);
      outd((buf[((64-audio_busy)<<1)+1]&255)|(buf16[((64-audio_busy)<<1)+1]&255));
      digitalWrite(CLOCK, 0);
      digitalWrite(CLOCK, 0);
      digitalWrite(CLOCK, 0);
      CLK();
      audio_busy--;
    } else {
      if(rx_read!=rx_write) {
        set_state(FPGA_RX_FIFO);
        outd(rx_buf[((rx_read<<2)  )&255]);
        digitalWrite(CLOCK, 1);
        digitalWrite(CLOCK, 1);
        digitalWrite(CLOCK, 1);
        outd(rx_buf[((rx_read<<2)|1)&255]);
        digitalWrite(CLOCK, 0);
        digitalWrite(CLOCK, 0);
        digitalWrite(CLOCK, 0);
        outd(rx_buf[((rx_read<<2)|2)&255]);
        digitalWrite(CLOCK, 1);
        digitalWrite(CLOCK, 1);
        digitalWrite(CLOCK, 1);
        outd(rx_buf[((rx_read<<2)|3)&255]);
        digitalWrite(CLOCK, 0);
        digitalWrite(CLOCK, 0);
        digitalWrite(CLOCK, 0);
        rx_read++;
      }
      if(rd) {
        set_state(FPGA_HD_FIFO);
        outd(hdd[lba++]);
        CLK();
        rd--;
      }
      if(digitalRead(FPGA_RX_REQ) && adlib_req==0 && gus_req==0) {
        adlib_req = 1;
        gus_req = 1;
      }
    }
    if(adlib_req == 2 && gus_req == 2) {
      audio_busy = 64;
      adlib_req = 0;
      gus_req = 0;
    }
  }
  return 0;
}
