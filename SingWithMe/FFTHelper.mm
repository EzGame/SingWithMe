

#include <stdio.h>


#import "FFTHelper.h"
FFTHelperRef * FFTHelperCreate(int numberOfSamples)
{
    FFTHelperRef *helperRef = (FFTHelperRef*) malloc(sizeof(FFTHelperRef));
    vDSP_Length log2n = log2f(numberOfSamples);    
    helperRef->fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    int nOver2 = numberOfSamples/2;
    helperRef->complexA.realp = (float*) malloc(nOver2*sizeof(float) );
    helperRef->complexA.imagp = (float*) malloc(nOver2*sizeof(float) );
    
    helperRef->outFFTData = (float *) malloc(nOver2*sizeof(float) );
    memset(helperRef->outFFTData, 0, nOver2*sizeof(float) );

    helperRef->invertedCheckData = (float*) malloc(numberOfSamples*sizeof(float) );
    
    return  helperRef;
}


float * computeFFT(FFTHelperRef *fftHelperRef, float *timeDomainData, int numSamples)
{
	vDSP_Length log2n = log2f(numSamples);
    float mFFTNormFactor = 1.0/(2*numSamples);
    
    //Convert float array of reals samples to COMPLEX_SPLIT array A
	vDSP_ctoz((COMPLEX*)timeDomainData, 2, &(fftHelperRef->complexA), 1, numSamples/2);
    
    //Perform FFT using fftSetup and A
	vDSP_fft_zrip(fftHelperRef->fftSetup, &(fftHelperRef->complexA), 1, log2n, FFT_FORWARD);
    
    //scale fft 
    vDSP_vsmul(fftHelperRef->complexA.realp, 1, &mFFTNormFactor, fftHelperRef->complexA.realp, 1, numSamples/2);
    vDSP_vsmul(fftHelperRef->complexA.imagp, 1, &mFFTNormFactor, fftHelperRef->complexA.imagp, 1, numSamples/2);
    
    vDSP_zvmags(&(fftHelperRef->complexA), 1, fftHelperRef->outFFTData, 1, numSamples/2);
    
    // to check everything (checking by reversing to time-domain data)
    vDSP_fft_zrip(fftHelperRef->fftSetup, &(fftHelperRef->complexA), 1, log2n, FFT_INVERSE);
    vDSP_ztoc( &(fftHelperRef->complexA), 1, (COMPLEX *) fftHelperRef->invertedCheckData , 2, numSamples/2);
    
    return fftHelperRef->outFFTData;
}

void FFTHelperRelease(FFTHelperRef *fftHelper) {
    vDSP_destroy_fftsetup(fftHelper->fftSetup);
    free(fftHelper->complexA.realp);
    free(fftHelper->complexA.imagp);
    free(fftHelper->outFFTData);
    free(fftHelper->invertedCheckData);
    free(fftHelper);
    fftHelper = NULL;
}

float findFrequency(float *samples, int numSamples, int sampleRate)
{
    FFTHelperRef *helper = FFTHelperCreate(numSamples);
    
    float *fftArray = computeFFT(helper, samples, numSamples);
    int peakIndex = 0;
    int rollingMax = 0;
    for (int i = 1; i < numSamples/2 - 1; i++) {
        if ((fftArray[i] > fftArray[i-1]) && (fftArray[i] > fftArray[i+1]) && rollingMax < fftArray[i]) {
            peakIndex = i;
            rollingMax = fftArray[i];
            break;
        }
    }
    
    // Get frequency
    float frequency = (float)(peakIndex * sampleRate) / (numSamples * 2);
    
    FFTHelperRelease(helper);
    return frequency;
}