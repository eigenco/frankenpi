#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>

/*
extern "C" void init_gus(void);
extern "C" void GUS_CallBack(uint16_t len);
extern "C" void write_gus(uint16_t port, uint8_t val);
extern "C" int16_t buf16[128];
*/

//void init_gus(void);
//void GUS_CallBack(uint16_t len);
//void write_gus(uint16_t port, uint8_t val);
extern int16_t buf16[128];

#define WAVE_BITS 2
#define WAVE_FRACT (9+WAVE_BITS)
#define WAVE_FRACT_MASK ((1 << WAVE_FRACT)-1)
#define WAVE_MSWMASK ((1 << (16+WAVE_BITS))-1)
#define WAVE_LSWMASK (0xffffffff ^ WAVE_MSWMASK)
#define RAMP_FRACT (10)
#define RAMP_FRACT_MASK ((1 << RAMP_FRACT)-1)
#define GUS_RATE 44100

int8_t MixTemp[16000];
uint8_t GUSRam[1024*1024];
int32_t AutoAmp;
uint16_t vol16bit[4096];
uint32_t pantable[16];

struct GFGus {
	uint8_t gRegSelect;
	uint16_t gRegData;
	uint32_t gDramAddr;
	uint16_t gCurChannel;
	uint8_t SampControl;
	uint8_t mixControl;
	uint8_t ActiveChannels;
	uint32_t basefreq;
	uint32_t rate;
	uint16_t portbase;
	uint32_t ActiveMask;
} myGUS;

// Returns a single 16-bit sample from the Gravis's RAM
int32_t GetSample(uint32_t Delta, uint32_t CurAddr, char eightbit) {
	uint32_t useAddr;
	uint32_t holdAddr;
	useAddr = CurAddr >> WAVE_FRACT;
	if (eightbit) {
		if (Delta >= (1 << WAVE_FRACT)) {
			int32_t tmpsmall = (int8_t)GUSRam[useAddr];
			return tmpsmall << 8;
		} else {
			// Interpolate
			int32_t w1 = ((int8_t)GUSRam[useAddr+0]) << 8;
			int32_t w2 = ((int8_t)GUSRam[useAddr+1]) << 8;
			int32_t diff = w2 - w1;
			return (w1+((diff*(int32_t)(CurAddr&WAVE_FRACT_MASK ))>>WAVE_FRACT));
		}
	} else {
		// Formula used to convert addresses for use with 16-bit samples
		holdAddr = useAddr & 0xc0000L;
		useAddr = useAddr & 0x1ffffL;
		useAddr = useAddr << 1;
		useAddr = (holdAddr | useAddr);

		if(Delta >= (1 << WAVE_FRACT)) {
			return (GUSRam[useAddr+0] | (((int8_t)GUSRam[useAddr+1]) << 8));
		} else {
			// Interpolate
			int32_t w1 = (GUSRam[useAddr+0] | (((int8_t)GUSRam[useAddr+1]) << 8));
			int32_t w2 = (GUSRam[useAddr+2] | (((int8_t)GUSRam[useAddr+3]) << 8));
			int32_t diff = w2 - w1;
			return (w1+((diff*(int32_t)(CurAddr&WAVE_FRACT_MASK ))>>WAVE_FRACT));
		}
	}
}

class GUSChannels {
public:
	uint32_t WaveStart;
	uint32_t WaveEnd;
	uint32_t WaveAddr;
	uint32_t WaveAdd;
	uint8_t  WaveCtrl;
	uint16_t WaveFreq;

	uint32_t RampStart;
	uint32_t RampEnd;
	uint32_t RampVol;
	uint32_t RampAdd;
	uint32_t RampAddReal;

	uint8_t RampRate;
	uint8_t RampCtrl;

	uint8_t PanPot;
	uint8_t channum;
	uint32_t PanLeft;
	uint32_t PanRight;
	int32_t VolLeft;
	int32_t VolRight;

	GUSChannels(uint8_t num) {
		channum = num;
		WaveStart = 0;
		WaveEnd = 0;
		WaveAddr = 0;
		WaveAdd = 0;
		WaveFreq = 0;
		WaveCtrl = 3;
		RampRate = 0;
		RampStart = 0;
		RampEnd = 0;
		RampCtrl = 3;
		RampAdd = 0;
		RampVol = 0;
		VolLeft = 0;
		VolRight = 0;
		PanLeft = 0;
		PanRight = 0;
		PanPot = 0x7;
	};
	void WriteWaveFreq(uint16_t val) {
		WaveFreq = val;
		double frameadd = double(val >> 1)/512.0; // Samples / original gus frame
		double realadd = (frameadd*(double)myGUS.basefreq/(double)GUS_RATE) * (double)(1 << WAVE_FRACT);
		WaveAdd = (uint32_t)realadd;
	}
	void WriteWaveCtrl(uint8_t val) {
		WaveCtrl = val & 0x7f;
	}
	uint8_t ReadWaveCtrl(void) {
		uint8_t ret=WaveCtrl;
		return ret;
	}
	void UpdateWaveRamp(void) {
		WriteWaveFreq(WaveFreq);
		WriteRampRate(RampRate);
	}
	void WritePanPot(uint8_t val) {
		PanPot = val;
		PanLeft = pantable[0x0f-(val & 0xf)];
		PanRight = pantable[(val & 0xf)];
		UpdateVolumes();
	}
	uint8_t ReadPanPot(void) {
		return PanPot;
	}
	void WriteRampCtrl(uint8_t val) {
		RampCtrl = val & 0x7f;
	}
	uint8_t ReadRampCtrl(void) {
		uint8_t ret=RampCtrl;
		return ret;
	}
	void WriteRampRate(uint8_t val) {
		RampRate = val;
		double frameadd = (double)(RampRate & 63)/(double)(1 << (3*(val >> 6)));
		double realadd = (frameadd*(double)myGUS.basefreq/(double)GUS_RATE) * (double)(1 << RAMP_FRACT);
		RampAdd = (uint32_t)realadd;
	}
	void WaveUpdate(void) {
		if (WaveCtrl & 0x3) return;
		int32_t WaveLeft;
		if (WaveCtrl & 0x40) {
			WaveAddr-=WaveAdd;
			WaveLeft=WaveStart-WaveAddr;
		} else {
			WaveAddr+=WaveAdd;
			WaveLeft=WaveAddr-WaveEnd;
		}
		if (WaveLeft<0) return;
		/* Check for not being in PCM operation */
		if (RampCtrl & 0x04) return;
		/* Check for looping */
		if (WaveCtrl & 0x08) {
			/* Bi-directional looping */
			if (WaveCtrl & 0x10) WaveCtrl^=0x40;
			WaveAddr = (WaveCtrl & 0x40) ? (WaveEnd-WaveLeft) : (WaveStart+WaveLeft);
		} else {
			WaveCtrl|=1;	//Stop the channel
			WaveAddr = (WaveCtrl & 0x40) ? WaveStart : WaveEnd;
		}
	}
	void UpdateVolumes(void) {
		int32_t templeft=RampVol - PanLeft;
		templeft&=~(templeft >> 31);
		int32_t tempright=RampVol - PanRight;
		tempright&=~(tempright >> 31);
		VolLeft=vol16bit[templeft >> RAMP_FRACT];
		VolRight=vol16bit[tempright >> RAMP_FRACT];
	}
	void RampUpdate(void) {
		/* Check if ramping enabled */
		if (RampCtrl & 0x3) return;
		int32_t RampLeft;
		if (RampCtrl & 0x40) {
			RampVol-=RampAdd;
			RampLeft=RampStart-RampVol;
		} else {
			RampVol+=RampAdd;
			RampLeft=RampVol-RampEnd;
		}
		if (RampLeft<0) {
			UpdateVolumes();
			return;
		}
		/* Check for looping */
		if (RampCtrl & 0x08) {
			/* Bi-directional looping */
			if (RampCtrl & 0x10) RampCtrl^=0x40;
			RampVol = (RampCtrl & 0x40) ? (RampEnd-RampLeft) : (RampStart+RampLeft);
		} else {
			RampCtrl|=1; // Stop the channel
			RampVol = (RampCtrl & 0x40) ? RampStart : RampEnd;
		}
		UpdateVolumes();
	}
	void generateSamples(int32_t * stream,uint32_t len) {
		int i;
		int32_t tmpsamp;
		char eightbit;
		if (RampCtrl & WaveCtrl & 3) return;
		eightbit = ((WaveCtrl & 0x4) == 0);

		for(i=0;i<(int)len;i++) {
			tmpsamp = GetSample(WaveAdd, WaveAddr, eightbit);
			stream[i<<1]+= tmpsamp * VolLeft;
			stream[(i<<1)+1]+= tmpsamp * VolRight;
			WaveUpdate();
			RampUpdate();
		}
	}
};

static GUSChannels *guschan[32];
static GUSChannels *curchan;

void GUSReset(void) {
	if((myGUS.gRegData & 0x1) == 0x1) {
		myGUS.mixControl = 0x0b;	// latches enabled by default LINEs disabled
		// Stop all channels
		int i;
		for(i=0;i<32;i++) {
			guschan[i]->RampVol=0;
			guschan[i]->WriteWaveCtrl(0x1);
			guschan[i]->WriteRampCtrl(0x1);
			guschan[i]->WritePanPot(0x7);
		}
	}
}

void ExecuteGlobRegister(void) {
	int i;
	switch(myGUS.gRegSelect) {
	case 0x0:  // Channel voice control register
		if(curchan) curchan->WriteWaveCtrl((uint16_t)myGUS.gRegData>>8);
		break;
	case 0x1:  // Channel frequency control register
		if(curchan) curchan->WriteWaveFreq(myGUS.gRegData);
		break;
	case 0x2:  // Channel MSW start address register
		if (curchan) {
			uint32_t tmpaddr = (uint32_t)(myGUS.gRegData & 0x1fff) << (16+WAVE_BITS);
			curchan->WaveStart = (curchan->WaveStart & WAVE_MSWMASK) | tmpaddr;
		}
		break;
	case 0x3:  // Channel LSW start address register
		if(curchan != NULL) {
			uint32_t tmpaddr = (uint32_t)(myGUS.gRegData) << WAVE_BITS;
			curchan->WaveStart = (curchan->WaveStart & WAVE_LSWMASK) | tmpaddr;
		}
		break;
	case 0x4:  // Channel MSW end address register
		if(curchan != NULL) {
			uint32_t tmpaddr = (uint32_t)(myGUS.gRegData & 0x1fff) << (16+WAVE_BITS);
			curchan->WaveEnd = (curchan->WaveEnd & WAVE_MSWMASK) | tmpaddr;
		}
		break;
	case 0x5:  // Channel MSW end address register
		if(curchan != NULL) {
			uint32_t tmpaddr = (uint32_t)(myGUS.gRegData) << WAVE_BITS;
			curchan->WaveEnd = (curchan->WaveEnd & WAVE_LSWMASK) | tmpaddr;
		}
		break;
	case 0x6:  // Channel volume ramp rate register
		if(curchan != NULL) {
			uint8_t tmpdata = (uint16_t)myGUS.gRegData>>8;
			curchan->WriteRampRate(tmpdata);
		}
		break;
	case 0x7:  // Channel volume ramp start register  EEEEMMMM
		if(curchan != NULL) {
			uint8_t tmpdata = (uint16_t)myGUS.gRegData >> 8;
			curchan->RampStart = tmpdata << (4+RAMP_FRACT);
		}
		break;
	case 0x8:  // Channel volume ramp end register  EEEEMMMM
		if(curchan != NULL) {
			uint8_t tmpdata = (uint16_t)myGUS.gRegData >> 8;
			curchan->RampEnd = tmpdata << (4+RAMP_FRACT);
		}
		break;
	case 0x9:  // Channel current volume register
		if(curchan != NULL) {
			uint16_t tmpdata = (uint16_t)myGUS.gRegData >> 4;
			curchan->RampVol = tmpdata << RAMP_FRACT;
			curchan->UpdateVolumes();
		}
		break;
	case 0xA:  // Channel MSW current address register
		if(curchan != NULL) {
			uint32_t tmpaddr = (uint32_t)(myGUS.gRegData & 0x1fff) << (16+WAVE_BITS);
			curchan->WaveAddr = (curchan->WaveAddr & WAVE_MSWMASK) | tmpaddr;
		}
		break;
	case 0xB:  // Channel LSW current address register
		if(curchan != NULL) {
			uint32_t tmpaddr = (uint32_t)(myGUS.gRegData) << (WAVE_BITS);
			curchan->WaveAddr = (curchan->WaveAddr & WAVE_LSWMASK) | tmpaddr;
		}
		break;
	case 0xC:  // Channel pan pot register
		if(curchan) curchan->WritePanPot((uint16_t)myGUS.gRegData>>8);
		break;
	case 0xD:  // Channel volume control register
		if(curchan) curchan->WriteRampCtrl((uint16_t)myGUS.gRegData>>8);
		break;
	case 0xE:  // Set active channel register
		myGUS.gRegSelect = myGUS.gRegData>>8; // JAZZ Jackrabbit seems to assume this?
		myGUS.ActiveChannels = 1+((myGUS.gRegData>>8) & 63);
		if(myGUS.ActiveChannels < 14) myGUS.ActiveChannels = 14;
		if(myGUS.ActiveChannels > 32) myGUS.ActiveChannels = 32;
		myGUS.ActiveMask=0xffffffffU >> (32-myGUS.ActiveChannels);
		myGUS.basefreq = (uint32_t)((double)1000000/(1.619695497*(double)(myGUS.ActiveChannels)));
		for(i=0;i<myGUS.ActiveChannels;i++) guschan[i]->UpdateWaveRamp();
		break;
	case 0x43:  // MSB Peek/poke DRAM position
		myGUS.gDramAddr = (0xff0000 & myGUS.gDramAddr) | ((uint32_t)myGUS.gRegData);
		break;
	case 0x44:  // LSW Peek/poke DRAM position
		myGUS.gDramAddr = (0xffff & myGUS.gDramAddr) | ((uint32_t)myGUS.gRegData>>8) << 16;
		break;
	case 0x4c:  // GUS reset register
		GUSReset();
		break;
	}
	return;
}

uint8_t read_gus(uint16_t port, uint16_t iolen) {
	switch(port) {
	case 0x343:
		return myGUS.gRegSelect;
	case 0x347:
		if(myGUS.gDramAddr < sizeof(GUSRam)) {
			return GUSRam[myGUS.gDramAddr];
		} else {
			return 0;
		}
	}

	return 0xff;
}

void write_gus(uint16_t port,uint8_t val) {
	switch(port) {
	case 0x342:
		myGUS.gCurChannel = val & 31 ;
		curchan = guschan[myGUS.gCurChannel];
		break;
	case 0x343:
		myGUS.gRegSelect = (uint8_t)val;
		myGUS.gRegData = 0;
		break;
	case 0x344:
		myGUS.gRegData = (uint8_t)val;
		break;
	case 0x345:
		myGUS.gRegData = (uint16_t)((0x00ff & myGUS.gRegData) | val << 8);
		ExecuteGlobRegister();
		break;
	case 0x347:
		if(myGUS.gDramAddr < sizeof(GUSRam)) GUSRam[myGUS.gDramAddr] = (uint8_t)val;
		break;
	}
}

void GUS_CallBack(uint16_t len) {
	memset(&MixTemp,0,len*8);
	uint16_t i;
	//buf16 = (int16_t *)MixTemp;
	int32_t * buf32 = (int32_t *)MixTemp;
	for(i=0;i<myGUS.ActiveChannels;i++)
		guschan[i]->generateSamples(buf32,len);
	for(i=0;i<len*2;i++) {
		int32_t sample=((buf32[i] >> 13)*AutoAmp)>>9;
		if (sample>32767) {
			sample=32767;
			AutoAmp--;
		} else if (sample<-32768) {
			sample=-32768;
			AutoAmp--;
		}
		buf16[i] = (int16_t)(sample);
	}
}

// Generate logarithmic to linear volume conversion tables
void MakeTables(void) {
	int i;
	double out = (double)(1 << 13);
	for (i=4095;i>=0;i--) {
		vol16bit[i]=(int16_t)out;
		out/=1.002709201;		/* 0.0235 dB Steps */
	}
	pantable[0]=0;
	for (i=1;i<16;i++) {
		pantable[i]=(uint32_t)(-128.0*(log((double)i/15.0)/log(2.0))*(double)(1 << RAMP_FRACT));
	}
}

void init_gus(void) {
	AutoAmp = 128; // using original value of 512 causes clipping, not sure why it works a bit differently from the way it does in dosbox so might want to look into this later
        memset(&myGUS,0,sizeof(myGUS));
        memset(GUSRam,0,1024*1024);
        MakeTables();
        for(uint8_t chan_ct=0; chan_ct<32; chan_ct++)
		guschan[chan_ct] = new GUSChannels(chan_ct);
        myGUS.gRegData=0x1;
        GUSReset();
        myGUS.gRegData=0x0;
}
