/*
g++ -O3 -c opl.cpp;g++ -O3 -c gus.cpp;g++ -O0 pc.cpp opl.o gus.o -lwiringPi -lm -lpthread -o pc
g++ -O2 -c opl.cpp;g++ -O2 -c gus.cpp;g++ -O0 pc.cpp opl.o gus.o -lwiringPi -lm -lpthread -o pc
g++ -O0 -c opl.cpp;g++ -O0 -c gus.cpp;g++ -O0 pc.cpp opl.o gus.o -lwiringPi -lm -lpthread -o pc

run as root and do the following before running:
echo -1 > /proc/sys/kernel/sched_rt_runtime_us
add to /boot/cmdline.txt isolcpus=1,2,3
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
void adlib_init(uint32_t samplerate);
void adlib_write(uint16_t idx, uint8_t val);
void adlib_getsample(short* sndptr, short numsamples);

static uint8_t audio_busy = 0;
static uint8_t adlib_req = 0;
static uint8_t gus_req = 0;
int16_t buf16[128];
int16_t buf[128];

#define DI0           0
#define DI1           1
#define DI2           2
#define DI3           3
#define DI4           4
#define DI5           5
#define DI6           6
#define DI7           7

#define DO0           8
#define DO1           9
#define DO2          10
#define DO3          11
#define DO4          12
#define DO5          13
#define DO6          14
#define DO7          15

#define CLOCK        16
#define FPGA_TX_REQ  17
#define FPGA_AU_REQ  18
#define STATE0       19
#define STATE1       20
#define STATE2       21

#define STATE_SY      0
#define STATE_TX      1
#define STATE_HD      2
#define STATE_AU      3
#define STATE_RX      4

unsigned short ind() {
  unsigned short data;
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
  digitalWrite(CLOCK, 0);
  digitalWrite(CLOCK, 0);
}

void* adlib_worker(void*) {
  cpu_set_t cpuset;
  pthread_t thread;
  thread = pthread_self();
  CPU_ZERO(&cpuset);
  CPU_SET(2, &cpuset);
  pthread_setaffinity_np(thread, sizeof(cpuset), &cpuset);

  adlib_init(44100);
  for(;;)
    if(adlib_req==1) {
      adlib_getsample(buf, 64);
      adlib_req = 2;
    }
  return NULL;
}

void* gus_worker(void*) {
  cpu_set_t cpuset;
  pthread_t thread;
  thread = pthread_self();
  CPU_ZERO(&cpuset);
  CPU_SET(3, &cpuset);
  pthread_setaffinity_np(thread, sizeof(cpuset), &cpuset);

  init_gus();
  for(;;) {
    if(gus_req==1) {
      GUS_CallBack(64);
      gus_req = 2;
    }
  }
  return NULL;
}

int main(void) {
  volatile int rd = 0, wr = 0, lba = 0, chs = 0, c = 0, h = 0, s = 0, i = 0, j;
  volatile unsigned char addr, data, areg, ad = 0;
  unsigned char *hdd;
  pthread_t tha, thg;
  FILE *hdd_file;

  cpu_set_t cpuset;
  pthread_t thread;
  thread = pthread_self();
  CPU_ZERO(&cpuset);
  CPU_SET(1, &cpuset);
  pthread_setaffinity_np(thread, sizeof(cpuset), &cpuset);

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

  pinMode(CLOCK, OUTPUT);
  pinMode(FPGA_TX_REQ, INPUT);
  pinMode(FPGA_AU_REQ, INPUT);
  pinMode(STATE0, OUTPUT);
  pinMode(STATE1, OUTPUT);
  pinMode(STATE2, OUTPUT);

  pthread_create(&tha, NULL, adlib_worker, NULL);
  pthread_create(&thg, NULL, gus_worker, NULL);

  for(;;) {
    set_state(STATE_SY);
    CLK();

    if(digitalRead(FPGA_TX_REQ)) {
      set_state(STATE_TX);
      CLK();
      CLK();
      CLK();
      data = ind();
      ad = ~ad;
      if(ad) addr = data;
      else {
	if(addr>0x40 && addr<0x49) write_gus(0x300|addr, data);
        if(addr==0x70) {
          if(data==0) { rd = 0; wr = 512; chs=0; }
          if(data==1) { rd = 512; wr = 0; }
        }
        if(addr==0x71) {
          if(chs==0) { c = data; chs++; }
          else if(chs==1) { h = data; chs++; }
          else if(chs==2) { s = data; chs++; lba = 512*(63*(16*c+h)+s-1); }
          else if(wr) { hdd[lba++] = data; }
        }
        if(addr==0x88) areg = data;
        if(addr==0x89) adlib_write(areg, data);
      }
    }

    if(audio_busy) {
      set_state(STATE_AU);
      outd((buf[(64-audio_busy)<<1]>>8)+(buf16[(64-audio_busy)<<1]>>8));
      CLK();
      outd((buf[(64-audio_busy)<<1]&255)+(buf16[(64-audio_busy)<<1]&255));
      CLK();
      outd((buf[((64-audio_busy)<<1)+1]>>8)+(buf16[((64-audio_busy)<<1)+1]>>8));
      CLK();
      outd((buf[((64-audio_busy)<<1)+1]&255)+(buf16[((64-audio_busy)<<1)+1]&255));
      CLK();
      CLK();
      CLK();
      audio_busy--;
    } else {
      if(digitalRead(FPGA_AU_REQ) && adlib_req==0 && gus_req==0) {
        adlib_req = 1;
        gus_req = 1;
      }
      if(rd) {
        set_state(STATE_HD);
        outd(hdd[lba++]);
        CLK();
        rd--;
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
