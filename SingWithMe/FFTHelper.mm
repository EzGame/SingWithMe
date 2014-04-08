

#include <stdio.h>


#import "FFTHelper.h"
FFTHelperRef * FFTHelperCreate(long numberOfSamples)
{
    FFTHelperRef *helperRef = (FFTHelperRef*) malloc(sizeof(FFTHelperRef));
    vDSP_Length log2n = log2f(numberOfSamples);    
    helperRef->fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    int nOver2 = numberOfSamples/2;
    helperRef->complexA.realp = (Float32*) malloc(nOver2*sizeof(Float32) );
    helperRef->complexA.imagp = (Float32*) malloc(nOver2*sizeof(Float32) );
    
    helperRef->outFFTData = (Float32 *) malloc(nOver2*sizeof(Float32) );
    memset(helperRef->outFFTData, 0, nOver2*sizeof(Float32) );

    helperRef->invertedCheckData = (Float32*) malloc(numberOfSamples*sizeof(Float32) );
    
    return  helperRef;
}


Float32 * computeFFT(FFTHelperRef *fftHelperRef, Float32 *timeDomainData, long numSamples)
{
	vDSP_Length log2n = log2f(numSamples);
    Float32 mFFTNormFactor = 1.0/(2*numSamples);
    
    //Convert float array of reals samples to COMPLEX_SPLIT array A
	vDSP_ctoz((COMPLEX*)timeDomainData, 2, &(fftHelperRef->complexA), 1, numSamples/2);
    
    //Perform FFT using fftSetup and A
    //Results are returned in A
	vDSP_fft_zrip(fftHelperRef->fftSetup, &(fftHelperRef->complexA), 1, log2n, FFT_FORWARD);
    
    //scale fft 
    vDSP_vsmul(fftHelperRef->complexA.realp, 1, &mFFTNormFactor, fftHelperRef->complexA.realp, 1, numSamples/2);
    vDSP_vsmul(fftHelperRef->complexA.imagp, 1, &mFFTNormFactor, fftHelperRef->complexA.imagp, 1, numSamples/2);
    
    vDSP_zvmags(&(fftHelperRef->complexA), 1, fftHelperRef->outFFTData, 1, numSamples/2);
    
    //to check everything (checking by reversing to time-domain data) =============================
    vDSP_fft_zrip(fftHelperRef->fftSetup, &(fftHelperRef->complexA), 1, log2n, FFT_INVERSE);
    vDSP_ztoc( &(fftHelperRef->complexA), 1, (COMPLEX *) fftHelperRef->invertedCheckData , 2, numSamples/2);
    //=============================================================================================

    return fftHelperRef->outFFTData;
}

float findFrequency(SInt16 *timeDomainData, long numSamples)
{
    FFTHelperRef *helper = FFTHelperCreate(numSamples);
    
    // Turn the SInt16 array to Float32
    Float32 *floatValues = (Float32 *)malloc(numSamples * sizeof(Float32));
    for (int i = 0; i < numSamples; i ++) {
        floatValues[i] = (Float32)timeDomainData[i];
    }
    
    Float32 *fftArray = computeFFT(helper, floatValues, numSamples);
    int peakIndex = 0;
    int rollingMax = 0;
    for (int i = 1; i < numSamples/2 - 1; i++) {
        if ((fftArray[i] > fftArray[i-1]) && (fftArray[i] > fftArray[i+1]) && rollingMax < fftArray[i]) {
            rollingMax = fftArray[i];
            peakIndex = i;
        }
    }
    
    // Get frequency
    float frequency = (float)(peakIndex * 44100) / numSamples;
    
    FFTHelperRelease(helper);
    return frequency;
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

