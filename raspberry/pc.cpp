/*
g++ -O2 -c opl.cpp;g++ -O2 -c gus.cpp
g++ -fsigned-char -O0 pc.cpp opl.o gus.o -lwiringPi -lm -lpthread -lmt32emu -o pc

run with run.sh as root and add to /boot/cmdline.txt isolcpus=1,2,3 before running
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
#define MT32EMU_API_TYPE 3
#include <mt32emu/mt32emu.h>

void init_gus(void);
void write_gus(uint16_t addr, uint8_t data);
void GUS_CallBack(int16_t* buf, uint16_t len);
void adlib_init(uint32_t samplerate);
void adlib_write(uint16_t idx, uint8_t val);
void adlib_getsample(short* sndptr, short numsamples);

typedef uint8_t Bit8u;
typedef int16_t Bit16s;
typedef uint32_t Bit32u;

static uint8_t audio_busy = 0;
static uint8_t adlib_req = 0;
static uint8_t gus_req = 0;
//int16_t buf16[128];
static int16_t buf[128];
static int16_t buf2[128];
static uint8_t rx_buf[256];
static volatile uint8_t rx_read = 0;
static volatile uint8_t rx_write = 0;
uint8_t *hdd;
uint8_t dirty[256*16*63];
uint8_t dirt = 0;
FILE *hdd_file;
volatile int wr = 0;
static uint8_t mt32_buf[256];
static uint8_t mt32_rd = 0;
static uint8_t mt32_wr = 0;
static uint8_t adlib = 1;
static uint8_t mt32 = 0;
static uint8_t gus = 0;

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
#define STATE_MOUSE   4

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
  while(adlib)
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
  CPU_SET(2, &cpuset);
  pthread_setaffinity_np(thread, sizeof(cpuset), &cpuset);

  init_gus();
  while(gus)
    if(adlib_req==1) {
      GUS_CallBack(buf, 64);
      adlib_req = 2;
    }
  return NULL;
}

MT32Emu::Service *service;
void *mt32_worker(void*) {
  cpu_set_t cpuset;
  pthread_t thread;
  thread = pthread_self();
  CPU_ZERO(&cpuset);
  CPU_SET(2, &cpuset);
  pthread_setaffinity_np(thread, sizeof(cpuset), &cpuset);

  static mt32emu_report_handler_i mt32_rhi;
  service = new MT32Emu::Service();
  service->createContext(mt32_rhi, NULL);
  service->addROMFile("CM32L_CONTROL.ROM");
  service->addROMFile("CM32L_PCM.ROM");
  service->setStereoOutputSampleRate(44100);
  service->openSynth();

  while(mt32) {
    if(adlib_req==1) {
      for(int i=0; i<128; i++) buf[i] = buf2[i];
      adlib_req = 2;
      service->renderBit16s(buf2, 64);
    } /*else if(mt32_rd!=mt32_wr)
      service->parseStream((uint8_t*)&mt32_buf[mt32_rd++], 1);*/
  }
  return NULL;
}

void *mouse_worker(void *) {
  cpu_set_t cpuset;
  pthread_t thread;
  thread = pthread_self();
  CPU_ZERO(&cpuset);
  CPU_SET(0, &cpuset);
  pthread_setaffinity_np(thread, sizeof(cpuset), &cpuset);

  int mfile;
  char data[3];
  const char *mdev = "/dev/input/mouse0";
  mfile = open(mdev, O_RDONLY);
  for(;;) {
    if(!audio_busy)
      if(read(mfile, data, 3)==3) {
	data[1] = data[1]*0.5;
	data[2] = -data[2]*0.5;
        rx_buf[rx_write++] = 0x40|((data[0]&1)<<5)|((data[0]&2)<<3)|((data[2]&0xC0)>>4)|((data[1]&0xC0)>>6);
        rx_buf[rx_write++] = data[1]&63;
        rx_buf[rx_write++] = data[2]&63;
      } else usleep(10);
  }

  return NULL;
}

void *hdflush_worker(void *) {
  cpu_set_t cpuset;
  pthread_t thread;
  thread = pthread_self();
  CPU_ZERO(&cpuset);
  CPU_SET(0, &cpuset);
  pthread_setaffinity_np(thread, sizeof(cpuset), &cpuset);
  uint32_t i, j, k;

  hdd_file = fopen("compact.img", "rb+");
  for(;;) {
    usleep(2000000);
    if(dirt && !wr) {
      printf("<");
      fflush(stdout);
      for(i=0; i<256*16*63; i++)
        if(dirty[i]) {
          fseek(hdd_file, 512*i, SEEK_SET);
          fwrite(hdd+512*i, 512, 1, hdd_file);
          dirty[i] = 0;
          printf(".");
        }
      dirt = 0;
      fflush(hdd_file);
      printf(">\n");
      fflush(stdout);
    }
  }
  fclose(hdd_file);

  return NULL;
}

int main(void) {
  volatile int rd = 0, lba = 0, chs = 0, c = 0, h = 0, s = 0, i = 0, j;
  volatile unsigned char addr, data, areg, ad = 0;
  pthread_t thread_adlib, thread_gus, thread_mouse, thread_hdd, thread_mt32;

  s = 512*256*16*63;
  hdd = (uint8_t*)malloc(s);
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

  // audio generating thread runs on isolated core 2
  pthread_create(&thread_adlib, NULL, adlib_worker, NULL);

  // gpio controlling thread runs on isolated core 1
  cpu_set_t cpuset;
  pthread_t thread;
  thread = pthread_self();
  CPU_ZERO(&cpuset);
  CPU_SET(1, &cpuset);
  pthread_setaffinity_np(thread, sizeof(cpuset), &cpuset);

  // miscellaneous threads run on core 0
  pthread_create(&thread_mouse, NULL, mouse_worker, NULL);
  pthread_create(&thread_hdd, NULL, hdflush_worker, NULL);

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
        if(addr==0x32) {
          if(data==0) { adlib = 0; mt32 = 0; gus = 0; }
          if(data==1) { adlib = 1; mt32 = 0; gus = 0; pthread_create(&thread_adlib, NULL, adlib_worker, NULL); }
          if(data==2) { adlib = 0; mt32 = 1; gus = 0; pthread_create(&thread_mt32, NULL, mt32_worker, NULL); }
          if(data==3) { adlib = 0; mt32 = 0; gus = 1; pthread_create(&thread_gus, NULL, gus_worker, NULL); }
        }
        if(addr==0x30) service->parseStream((uint8_t*)&data, 1);
        //if(addr==0x30) mt32_buf[mt32_wr++] = data;
	if(addr>0x40 && addr<0x49) write_gus(0x300|addr, data);
        if(addr==0x70) {
          if(data==0) { rd = 0; wr = 512; chs=0; }
          if(data==1) { rd = 512; wr = 0; }
        }
        if(addr==0x71) {
          if(chs==0) { c = data; chs++; }
          else if(chs==1) { h = data; chs++; }
          else if(chs==2) { s = data; chs++; lba = 512*(63*(16*c+h)+s-1); }
          else if(wr) { if(lba&511==511) dirty[lba>>9] = 1; hdd[lba++] = data; dirt = 1; }
        }
        if(addr==0x88) areg = data;
        if(addr==0x89) adlib_write(areg, data);
      }
    }

    if(audio_busy) {
      set_state(STATE_AU);
      outd((buf[(64-audio_busy)<<1]>>8));
      CLK();
      outd((buf[(64-audio_busy)<<1]&255));
      CLK();
      outd((buf[((64-audio_busy)<<1)+1]>>8));
      CLK();
      outd((buf[((64-audio_busy)<<1)+1]&255));
      CLK();
      CLK();
      CLK();
      audio_busy--;
    } else {
      if(digitalRead(FPGA_AU_REQ) && adlib_req==0)
        adlib_req = 1;
      if(rd) {
        set_state(STATE_HD);
        outd(hdd[lba++]);
        CLK();
        rd--;
      }
      if(rx_read!=rx_write) {
        set_state(STATE_MOUSE);
        outd(rx_buf[rx_read++]);
        CLK();
      }
    }
    if(adlib_req == 2) {
      audio_busy = 64;
      adlib_req = 0;
    }
  }
  return 0;
}
