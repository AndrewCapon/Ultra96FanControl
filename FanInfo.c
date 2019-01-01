/*
 * Copyright (c) 2012 Xilinx, Inc.  All rights reserved.
 *
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>

#define Q 8

typedef u_int32_t fixed;

fixed fixed_mul_16(fixed x, fixed y)
{
  return ((u_int32_t)x * (u_int32_t)y) / (1 << Q);
}

fixed fixed_div_16(fixed x, fixed y)
{
  return ((u_int32_t)x * (1 << Q)) / y;
}

fixed to_fixed(u_int32_t x)
{
	return x << Q;
}

u_int32_t from_fixed(fixed x)
{
	return x >> Q;
}

fixed transition(fixed fLast, fixed fNew, fixed fRatio)
{
	fixed fDiff;
	fixed fDiffSmoothed;
	fixed fResult;

	if(fLast > fNew)
	{
		fDiff = fLast - fNew;
		fDiffSmoothed = fixed_div_16((fDiff), fRatio);
		fResult = fLast - fDiffSmoothed;
	}
	else
	{
		fDiff = fNew - fLast;
		fDiffSmoothed = fixed_div_16((fDiff), fRatio);
		fResult = fLast + fDiffSmoothed;
	}

	return fResult;
}

float toFloat(fixed f)
{
	return ((float)f / (float)(1 << Q));
}

#define gotoxy(x,y) printf("\033[%d;%dH", (x), (y))
#define clear() printf("\033[H\033[J")

int main()
{
    unsigned uPageSize = sysconf(_SC_PAGESIZE);
    unsigned uPageAddress = 0x80001000;


    int fd = open ("/dev/mem", O_RDWR);
    unsigned page_addr = (uPageAddress & (~(uPageSize-1)));
    unsigned page_offset = uPageAddress - page_addr;

    void *pMem = mmap(NULL, uPageSize, PROT_READ|PROT_WRITE, MAP_SHARED, fd, uPageAddress); //memory map

    unsigned *pPWMReg = (pMem+page_offset);

    volatile unsigned *pTempLowReg 		= pPWMReg;
    volatile unsigned *pTempHighReg 	= pPWMReg+1;
    volatile unsigned *pTempSmoothReg 	= pPWMReg+2;
    volatile unsigned *pTempOverrideReg = pPWMReg+3;

    volatile unsigned *pTempReg 		= pPWMReg+4;
    volatile unsigned *pTempAlarmReg    = pPWMReg+5;

    volatile unsigned *pDbg0Reg 		= pPWMReg+6;
    volatile unsigned *pDbg1Reg 		= pPWMReg+7;
    volatile unsigned *pDbg2Reg 		= pPWMReg+8;
    volatile unsigned *pDbg3Reg 		= pPWMReg+9;
    volatile unsigned *pDbg4Reg 		= pPWMReg+10;
    volatile unsigned *pDbg5Reg 		= pPWMReg+11;
    volatile unsigned *pDbg6Reg 		= pPWMReg+12;
    volatile unsigned *pDbg7Reg 		= pPWMReg+13;
    volatile unsigned *pDbg8Reg 		= pPWMReg+14;
    volatile unsigned *pDbg9Reg 		= pPWMReg+15;

    char *states[] = {"FAN_OFF", "FAN_PROCESS", "FAN_ON", "FAN_FORCED"};
    clear();
    while(1)
    {
		//clear();
		gotoxy(0,0);

		printf("Fan Control Registers\n");


		int bIsTempOverride = (*pTempOverrideReg) &  (1<<13);

		printf("Temp Low        = %d                  \n", *pTempLowReg);
		printf("Temp High       = %d                  \n", *pTempHighReg);
		printf("Smooth Divisor  = %d                  \n", *pTempSmoothReg);
		printf("PWM Override    = %d - %d             \n\n", 0!=bIsTempOverride, (*pTempOverrideReg) & 0xfff);

		printf("Temp            = %d                  \n", *pTempReg);
		printf("Alarm           = %d                  \n\n", *pTempAlarmReg);

		u_int32_t 	uState 		= *pDbg0Reg;

		u_int32_t   uPWM 		= *pDbg1Reg;
		float 		fPWM 		= toFloat(uPWM);

		u_int32_t	uUsePWM 	= *pDbg2Reg;
		float 		fUsePWM 	= toFloat(uUsePWM);


		u_int32_t	uLastPWM	= *pDbg3Reg;
		float 		fLastPWM	= toFloat(uLastPWM);

		float 		fRealTemp	= toFloat(*pDbg4Reg);
		float 		fUseTemp 	= toFloat(*pDbg5Reg);
		float 		fLastTemp	= toFloat(*pDbg6Reg);


		float 		fTempError	= toFloat(*pDbg7Reg);
		float 		fLinear		= toFloat(*pDbg8Reg);

		float 		fMaxPWM		= toFloat(*pDbg9Reg);

		printf("Dbg0 (state)     = %s                   \n", states[uState]);
		printf("Dbg1 (PWM)       = %f                   \n", fPWM);
		printf("Dbg2 (usePWM)    = %f                   \n", fUsePWM);
		printf("Dbg3 (lastPWM)   = %f                   \n\n", fLastPWM);

		printf("Dbg4 (Real Temp) = %f                   \n", fRealTemp);
		printf("Dbg5 (Use Temp)  = %f                   \n", fUseTemp);
		printf("Dbg6 (last Temp) = %f                   \n\n", fLastTemp);

		printf("Dbg7 (Error)     = %f                   \n", fTempError);
		printf("Dbg8 (Linear)    = %f                   \n", fLinear);

		printf("Dbg9 (Max PWM)   = %f                   \n", fMaxPWM);
		usleep(1000);
    }

    close(fd);
}
