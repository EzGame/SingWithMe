
#ifndef ShazamTest_FFTHelper_h
#define ShazamTest_FFTHelper_h




#import <Accelerate/Accelerate.h>
#include <MacTypes.h>


typedef struct FFTHelperRef {
    FFTSetup fftSetup;
    COMPLEX_SPLIT complexA;
    float *outFFTData;
    float *invertedCheckData;
} FFTHelperRef;


FFTHelperRef*   FFTHelperCreate(int numberOfSamples);
void            FFTHelperRelease(FFTHelperRef *fftHelper);

float*          computeFFT(FFTHelperRef *fftHelperRef,
                           float *timeDomainData,
                           int numSamples);

float           findFrequency(float *buffer,
                              int bufferSize,
                              int sampleRate);
#endif
