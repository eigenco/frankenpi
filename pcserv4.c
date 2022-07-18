/*
sudo modprobe snd-pcm-oss
apt-get install libasound2-dev
g++ -O3 -c opl.cpp
gcc -O0 pcserv4.c opl.o -o pcserv4 -lwiringPi -lpthread -lasound -lm
*/

#define _GNU_SOURCE

#include <sched.h>
#include <linux/soundcard.h>
#include <termios.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <wiringPi.h>
#include <alsa/asoundlib.h>

void adlib_init(uint32_t samplerate);
void adlib_write(uintptr_t idx, uint8_t val);
void adlib_getsample(int16_t* sndptr, intptr_t numsamples);

void adlib(void) {
  short buf[2*256];
  int a;

  int fd = open("/dev/dsp", O_WRONLY);
  a = 16; ioctl(fd, SOUND_PCM_WRITE_BITS, &a);
  a = 2; ioctl(fd, SOUND_PCM_WRITE_CHANNELS, &a);
  a = 44100; ioctl(fd, SOUND_PCM_WRITE_RATE, &a);
  a = (4 << 16) | 8; ioctl(fd, SNDCTL_DSP_SETFRAGMENT, &a);
  for(;;) {
    adlib_getsample(buf, 256);
    write(fd, buf, sizeof(buf));
  }
}

#define D0    0
#define D1    1
#define D2    2
#define D3    3
#define D4    4
#define D5    5
#define D6    6
#define D7    7

#define REQ0  8
#define REQ1  9
#define ACK   10

#define DI0   19
#define DI1   20
#define DI2   21
#define DI3   22
#define ICL   24

unsigned char ind() {
  unsigned char data;
  data  = digitalRead(D7); data <<= 1;
  data |= digitalRead(D6); data <<= 1;
  data |= digitalRead(D5); data <<= 1;
  data |= digitalRead(D4); data <<= 1;
  data |= digitalRead(D3); data <<= 1;
  data |= digitalRead(D2); data <<= 1;
  data |= digitalRead(D1); data <<= 1;
  data |= digitalRead(D0);
  return data;
}

void outd(unsigned char data) {
  digitalWrite(DI0, data & 1); data >>= 1;
  digitalWrite(DI1, data & 1); data >>= 1;
  digitalWrite(DI2, data & 1); data >>= 1;
  digitalWrite(DI3, data & 1);
}

void ICLCLK() {
  digitalWrite(ICL, 1);
  digitalWrite(ICL, 1);
  digitalWrite(ICL, 1);
  digitalWrite(ICL, 1);
  digitalWrite(ICL, 0);
  digitalWrite(ICL, 0);
  digitalWrite(ICL, 0);
  digitalWrite(ICL, 0);
}

void ACKCLK() {
  digitalWrite(ACK, 1);
  digitalWrite(ACK, 1);
  digitalWrite(ACK, 1);
  digitalWrite(ACK, 1);
  digitalWrite(ACK, 0);
  digitalWrite(ACK, 0);
  digitalWrite(ACK, 0);
  digitalWrite(ACK, 0);
}

int main(void) {
  int adlib_register, adlib_data, linear_address, c, h, s, rdd=0;
  unsigned char addr, data, ad, chs_state, rd=0;
  unsigned char *hdd;
  pthread_t thread;
  FILE *hdd_file;

  hdd = (unsigned char*)malloc(132120576);
  printf("Reading...\n");
  hdd_file = fopen("compact.img", "rb");
  c = fread(hdd, 1, 132120576, hdd_file);
  //hdd_file = fopen("disk.bin", "rb");
  //c = fread(hdd, 1, 512, hdd_file);
  fclose(hdd_file);
  printf("Read %d bytes\n\n", c);

  adlib_init(44100);
  pthread_create(&thread, NULL, (void*)adlib, NULL);

  wiringPiSetupGpio();
  pinMode(D0, INPUT);
  pinMode(D1, INPUT);
  pinMode(D2, INPUT);
  pinMode(D3, INPUT);
  pinMode(D4, INPUT);
  pinMode(D5, INPUT);
  pinMode(D6, INPUT);
  pinMode(D7, INPUT);
  pinMode(REQ0, INPUT);
  pinMode(REQ1, INPUT);
  pinMode(ACK, OUTPUT);
  pinMode(DI0, OUTPUT);
  pinMode(DI1, OUTPUT);
  pinMode(DI2, OUTPUT);
  pinMode(DI3, OUTPUT);
  pinMode(ICL, OUTPUT);

  for(;;) {
    if(digitalRead(REQ0)==1) {
      ad = digitalRead(REQ1);
      if(ad) {
        data = ind();
        if(addr==0x70) {
          if(data==0) {
            rd = 0;
            rdd = 0;
            chs_state = 0;
            linear_address = 0;
          }
          if(data==1) { rd = 1; rdd = 0; }
        }
        if(addr==0x71) {
          if(chs_state==0) c = data;
          if(chs_state==1) h = data;
          if(chs_state==2) {
            s = data;
            linear_address = 512*((c*16+h)*63+s-1);
            //printf("Block: %d\n", linear_address/512);
          }
          if(chs_state==3) {
            //printf("Write: %d\n", linear_address & 511);
            hdd[linear_address++] = data;
          }
          if(chs_state<3) chs_state = chs_state + 1;
        }
        if(addr==0x38) adlib_register = data;
        if(addr==0x39) adlib_write(adlib_register, data);
      }
      else addr = ind();
      ACKCLK();
    }
    if(rd) {
      //printf("%.2X", hdd[linear_address]);
      outd(hdd[linear_address] & 15); ICLCLK();
      outd(hdd[linear_address++] >> 4); ICLCLK();
      if(++rdd==512) { rd = 0; rdd = 0; } //printf("\n\n");}
    }
  }
  return 0;
}
